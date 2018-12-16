{ stdenv, fetchurl, fetchFromGitHub, autoreconfHook, pkgconfig
, leptonica, libpng, libtiff, icu, pango, opencl-headers
# Supported list of languages or `null' for all available languages
, enableLanguages ? null
# if you want just a specific list of languages, optionally specify a hash
# to make tessdata a fixed output derivation.
, enableLanguagesHash ? (if enableLanguages == null # all languages
                         then "11bi1hj2ihqrgvi9cam8mi70p4spm3syljkpnbglf4s8jkpfn15a"
                         else null)
}:

let
  languages = (import ./languages.nix { inherit stdenv fetchurl fetchFromGitHub; }).v3;

  tessdata = if enableLanguages == null then
      languages.all
    else
      if builtins.all (lang: builtins.hasAttr lang languages) enableLanguages then
        map (lang: languages.${lang}) enableLanguages
      else
        # Copy the selected languages from languages.all
        stdenv.mkDerivation ({
          name = "tessdata";
          buildCommand = ''
            mkdir $out
            cd ${languages.all}
            cp ${stdenv.lib.concatMapStringsSep " " (x: x + ".traineddata") enableLanguages} $out
          '';
          preferLocalBuild = true;
        } // (stdenv.lib.optionalAttrs (enableLanguagesHash != null) {
          # when a hash is given, we make this a fixed output derivation.
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = enableLanguagesHash;
        }));

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
      maintainers = with stdenv.lib.maintainers; [viric];
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

      [[ -d "$tessdata" ]] && tessdata=$tessdata/*
      ln -s $tessdata $out/share/tessdata
    '';
  });
in
  if enableLanguages == false then
    tesseractWithoutData
  else
    tesseractWithData
