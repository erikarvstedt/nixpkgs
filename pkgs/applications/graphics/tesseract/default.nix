{ stdenv, fetchurl, fetchFromGitHub, autoreconfHook, pkgconfig
, leptonica, libpng, libtiff, icu, pango, opencl-headers
# Supported list of languages or `null' for all available languages
, enableLanguages ? null
# This argument is obsolete
, enableLanguagesHash ? null
}:

let
  languages = (import ./languages.nix { inherit stdenv fetchurl fetchFromGitHub; }).v3;

  tessdata = if enableLanguages == null then
      languages.all
    else
      map (lang: languages.${lang}) enableLanguages;

  tesseractWithoutData = stdenv.mkDerivation rec {
    name = "tesseract-${version}";
    version = "3.05.00";

    src = fetchFromGitHub {
      owner = "tesseract-ocr";
      repo = "tesseract";
      rev = version;
      sha256 = "11wrpcfl118wxsv2c3w2scznwb48c4547qml42s2bpdz079g8y30";
    };

    enableParallelBuilding = true;

    nativeBuildInputs = [ pkgconfig autoreconfHook ];
    buildInputs = [ leptonica libpng libtiff icu pango opencl-headers ];

    LIBLEPT_HEADERSDIR = "${leptonica}/include";

    passthru = { inherit languages; };

    meta = {
      description = "OCR engine";
      homepage = https://github.com/tesseract-ocr/tesseract;
      license = stdenv.lib.licenses.asl20;
      maintainers = with stdenv.lib.maintainers; [ viric earvstedt ];
      platforms = with stdenv.lib.platforms; linux ++ darwin;
    };
  };

  tesseractWithData = tesseractWithoutData.overrideAttrs (_: {
    inherit tesseractWithoutData;

    # tessdata can be a list of files or a directory containing files
    inherit tessdata;

    buildCommand = ''
      cp -r $tesseractWithoutData $out
      chmod -R +w $out

      # Switch all store paths pointing to the original derivation to this derivation
      if (( ''${#tesseractWithoutData} != ''${#out} )); then
        echo "Can't replace store paths due to differing lengths"
        exit 1
      fi
      find $out -type f -exec sed -i "s|$tesseractWithoutData|$out|g" {} \;

      if [[ -d "$tessdata" ]]; then
        ln -s $tessdata/* $out/share/tessdata
      else
        for lang in $tessdata; do
          ln -s $lang $out/share/tessdata/''${lang#/nix/store*-}
        done
      fi
    '';
  });

  tesseract = if enableLanguages == false then
    tesseractWithoutData
  else
    tesseractWithData;
in
  if enableLanguagesHash == null then
    tesseract
  else
    builtins.trace "Argument `enableLanguagesHash` is obsolete and can be removed."
    tesseract
