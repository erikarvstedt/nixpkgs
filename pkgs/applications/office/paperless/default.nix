{ stdenv
, lib
, writeScript
, fetchFromGitHub

, python3
, tesseract
, file
, poppler
, imagemagickBig # includes ghostscript
, unpaper

, enableTests ? true
}:

## Usage
#
# ${pkgs.paperless}/bin/paperless wraps manage.py
#
# ${pkgs.paperless}/share/paperless/setup-env.sh can be sourced from a
#   shell script to setup a Paperless environment
#
# paperless.withConfig is a convenience function to setup a
# configured Paperless instance. Example:
#
# nix-build --out-link ./paperless -E '
# (import <nixpkgs> {}).paperless.withConfig {
#   dataDir = /tmp/paperless-data;
#   config = {
#     PAPERLESS_DISABLE_LOGIN = "true";
#   };
# }'
#
## Setup DB
# ./paperless migrate
#
## Consume documents in dataDir/consume
# ./paperless document_consumer --oneshot
#
## Start web interface
# ./paperless runserver --noreload localhost:8000


## WSGI with gunicorn
# Use a shell script like this:
# source ${paperless}/share/paperless/setup-env.sh
# PYTHONPATH=$paperlessSrc gunicorn paperless.wsgi

with lib;
let
  paperless = stdenv.mkDerivation rec {
    name = "paperless-${version}";
    version = "2.3.0";

    src = fetchFromGitHub {
      owner = "danielquinn";
      repo = "paperless";
      rev = version;
      sha256 = "0vjh4ricvrnq1cg9fciwvrd7mbkal4cddi6w2d17h7vsvdi5iymv";
    };

    inherit python;

    pythonEnv = python.withPackages (ps: with ps; [
      coveralls
      dateparser
      dateutil
      django
      django-crispy-forms
      django-cors-headers
      django-filter
      django-flat-responsive
      django_extensions
      djangorestframework
      factory_boy
      filemagic
      flake8
      fuzzywuzzy
      gunicorn
      langdetect
      pdftotext
      pillow
      pycodestyle
      pyocrWithUserTesseract
      pytest
      pytest-django
      pytest-env
      # pytest_xdist # Disabled, broken in nixpkgs
      pytestcov
      python-dotenv
      python-gnupg
      pytz
      termcolor
    ] ++ (optional stdenv.isLinux inotify_simple));

    buildCommand = let
      # Paperless has explicit runtime checks that expect these binaries to be in PATH
      extraBin = makeBinPath [ tesseract imagemagickBig unpaper ];
    in ''
      srcDir=$out/share/paperless
      mkdir -p $out/bin $out/share
      cp -r $src/src $srcDir
      chmod -R +w $srcDir
      cp $src/LICENSE $srcDir

      ### Patches

      # Remove command arguments for pytest_xdist, which is broken in nixpkgs
      chmod +w $srcDir/setup.cfg
      sed -i 's/ -n auto//' $srcDir/setup.cfg

      ### Compile

      ${python}/bin/python -m compileall $srcDir

      ### Scripts

      cat > $out/bin/paperless <<EOF
      export PATH=${extraBin}
      exec ${pythonEnv}/bin/python $out/share/paperless/manage.py "\$@"
      EOF
      chmod +x $out/bin/paperless

      # A shell snippet that can be sourced to setup a paperless env
      cat > $out/share/paperless/setup-env.sh <<EOF
      export PATH=${pythonEnv}/bin:${extraBin}''${PATH:+:}$PATH
      export paperlessSrc=$out/share/paperless
      EOF

      ${optionalString enableTests ''
        echo "Running tests. This might take a while..."
        (source $out/share/paperless/setup-env.sh
         export HOME=$(pwd)
         cd $paperlessSrc
         # Prevent pytest from creating unneeded cache files in $paperlessSrc
         pytest -p no:cacheprovider)
      ''}
    '';

    passthru = {
      inherit withConfig;
    };

    meta = with lib; {
      description = "Scan, index, and archive all of your paper documents";
      homepage = https://github.com/danielquinn/paperless;
      license = licenses.gpl3;
      maintainers = [ maintainers.earvstedt ];
    };
  };

  python = python3;

  pyocrWithUserTesseract =
    let
      pyocr = python.pkgs.pyocr.override { inherit tesseract; };
    in
      if pyocr.outPath == python.pkgs.pyocr.outPath then
        pyocr
      else
        # The user has provided a custom tesseract derivation that might be
        # missing some languages that are required for PyOCR's tests. Disable them to
        # avoid build errors.
        pyocr.overrideAttrs (attrs: {
          doInstallCheck = false;
        });

  withConfig = { config ? {}, dataDir ? null, paperlessDrv ? paperless, extraCmds ? "" }:
    let
      dir = toString dataDir;

      envVars = (optionalAttrs (dataDir != null) {
        PAPERLESS_CONSUMPTION_DIR = "${dir}/consume";
        PAPERLESS_MEDIADIR = "${dir}/media";
        PAPERLESS_STATICDIR = "${dir}/static";
        PAPERLESS_DBDIR = "${dir}";
      }) // config;

      envVarDefs = mapAttrsToList (n: v: ''export ${n}="${toString v}"'') envVars;
      setupEnvVars = builtins.concatStringsSep "\n" envVarDefs;

      setupEnv = ''
        source ${paperlessDrv}/share/paperless/setup-env.sh
        ${setupEnvVars}
        ${optionalString (dataDir != null) ''
          mkdir -p "$PAPERLESS_CONSUMPTION_DIR" \
                   "$PAPERLESS_MEDIADIR" \
                   "$PAPERLESS_STATICDIR" \
                   "$PAPERLESS_DBDIR"
        ''}
      '';

      runPaperless = writeScript "paperless" ''
        #!${stdenv.shell} -e
        ${setupEnv}
        ${extraCmds}
        exec python $paperlessSrc/manage.py "$@"
      '';
   in
     runPaperless // {
       paperless = paperlessDrv;
       inherit setupEnv;
     };
in
  paperless
