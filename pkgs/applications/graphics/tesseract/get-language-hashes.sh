#!/usr/bin/env bash

# Usage:
#   ./get-language-hashes.sh [--local-langs] [<tessdataRev>]
#
#   --local-langs
#        Only use languages already defined in ./languages.nix instead of
#        fetching all available languages from the tessdata repo
#
# Output:
#   eng = "05gv...";
#   fra = "0c60...";
#   ...

set -e

tessdataRev=3cf1e2df1fe1d1da29295c9ef0983796c7958b7d

for arg in "$@"; do
    if [[ $arg == --local-langs ]]; then
        localLangs=1
    else
        tessdataRev=$arg
    fi
done

if [[ $localLangs ]]; then
  langCodes=$(nix eval --raw '(
    with (import ../../../.. { config = {}; overlays = []; });
    let
      languages = (pkgs.callPackage ./languages.nix {}).v3;
    in
      builtins.concatStringsSep " " (lib.remove "all" (builtins.attrNames languages))
  )')
else
  langCodes=$(echo $(curl -s https://github.com/tesseract-ocr/tessdata/tree/$tessdataRev \
              | grep -ohP "(?<=/)[^/]+?(?=\.traineddata)" | sort))
fi

for lang in $langCodes; do
    url=https://github.com/tesseract-ocr/tessdata/raw/$tessdataRev/$lang.traineddata
    hash=$(nix-prefetch-url $url 2>/dev/null)
    echo "$lang = \"$hash\";"
done
