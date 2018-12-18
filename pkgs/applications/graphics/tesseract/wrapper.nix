{ stdenv, tesseractBase, languages

# A list of languages like [ "eng" "spa" … ] or `null` for all available languages
, enableLanguages ? null

# A list of files or a directory containing files
, tessdata ? (if enableLanguages == null then languages.all
              else map (lang: languages.${lang}) enableLanguages)

# This argument is obsolete
, enableLanguagesHash ? null
}:

let
  passthru = { inherit tesseractBase languages tessdata; };

  tesseractWithData = tesseractBase.overrideAttrs (_: {
    inherit tesseractBase tessdata;

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

  tesseract = (if enableLanguages == [] then tesseractBase else tesseractWithData) // passthru;
in
  if enableLanguagesHash == null then
    tesseract
  else
    stdenv.lib.warn "Argument `enableLanguagesHash` is obsolete and can be removed."
    tesseract
