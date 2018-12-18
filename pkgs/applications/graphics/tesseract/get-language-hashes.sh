#!/usr/bin/env bash

# Usage:
#   ./get-language-hashes.sh <tessdataRev> [<language code>…]
#
# Example:
#   ./get-language-hashes.sh 4.0.0 eng spa
#
#   Output:
#     eng = "05gv...";
#     spa = "0c60...";
#    ...

set -e

(( $# >= 1 )) || exit 1
tessdataRev=$1
shift

if (( $# > 0 )); then
    langCodes="$@"
else
    repoPage=$(curl -fs https://github.com/tesseract-ocr/tessdata/tree/$tessdataRev || {
                   >&2 echo "Invalid tessdataRev: $tessdataRev"
                   exit 1
               })
    langCodes=$(echo $(echo "$repoPage" | grep -ohP "(?<=/)[^/]+?(?=\.traineddata)" | sort))
fi

for lang in $langCodes; do
    url=https://github.com/tesseract-ocr/tessdata/raw/$tessdataRev/$lang.traineddata
    hash=$(nix-prefetch-url $url 2>/dev/null)
    echo "$lang = \"$hash\";"
done
