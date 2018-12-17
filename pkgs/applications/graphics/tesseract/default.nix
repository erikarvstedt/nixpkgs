{ stdenv, fetchurl, fetchFromGitHub, autoreconfHook, pkgconfig
, leptonica, libpng, libtiff, icu, pango, opencl-headers
# List of languages like [ "eng" "spa" ... ] or `null` for all available languages
, enableLanguages ? null

, tesseractBase ? stdenv.mkDerivation rec {
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

    meta = {
      description = "OCR engine";
      homepage = https://github.com/tesseract-ocr/tesseract;
      license = stdenv.lib.licenses.asl20;
      maintainers = with stdenv.lib.maintainers; [ viric earvstedt ];
      platforms = with stdenv.lib.platforms; linux ++ darwin;
    };
  }

# This argument is obsolete
, enableLanguagesHash ? null
}:

let
  languages = (import ./languages.nix { inherit stdenv fetchurl fetchFromGitHub; }).v3;

  tessdata = if enableLanguages == null then
      languages.all
    else
      map (lang: languages.${lang}) enableLanguages;

  tesseractWithData = tesseractBase.overrideAttrs (_: {
    inherit tesseractBase;

    # tessdata can be a list of files or a directory containing files
    inherit tessdata;

    buildCommand = ''
      mkdir $out
      cp -r $tesseractBase/{bin,lib} $out
      chmod -R +w $out
      cp -rs --no-preserve=mode $tesseractBase/{include,share} $out

      # The store paths in bin and lib still point to `tesseractBase`.
      # Switch them to this derivation so that the correct tessdata is used.
      if (( ''${#tesseractBase} != ''${#out} )); then
        echo "Can't replace store paths due to differing lengths"
        exit 1
      fi
      find $out/{bin,lib} -type f -exec sed -i "s|$tesseractBase|$out|g" {} \;

      if [[ -d "$tessdata" ]]; then
        ln -s $tessdata/* $out/share/tessdata
      else
        for lang in $tessdata; do
          ln -s $lang $out/share/tessdata/''${lang#/nix/store*-}
        done
      fi
    '';
  });

  tesseract = (if enableLanguages == [] then tesseractBase else tesseractWithData) // {
    inherit languages tesseractBase;
  };
in
  if enableLanguagesHash == null then
    tesseract
  else
    stdenv.lib.warn "Argument `enableLanguagesHash` is obsolete and can be removed."
    tesseract
