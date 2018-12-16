#!/usr/bin/env bash

# Usage:
#   ./get-language-hashes.sh [<tessdataRev>]
#
# Output:
#   eng = "05gvs5kmlmp9ncb3c044vfndl24p5f99k8yfy50aabwksl3575q7";
#   fra = "0606cailv7ap80b9ix72h56lq2ipgk5fsf0f7m3yjcxl0hr5pinb";
#   ...

set -e

tessdataRev=${1:-3cf1e2df1fe1d1da29295c9ef0983796c7958b7d}

nixSrc=$(sed "s/TESSDATA_REV/$tessdataRev/" <<'EOF'
  with (import ../../../.. { config = {}; overlays = []; });
  let
    tessdataRev = "TESSDATA_REV";
    languageCodes = builtins.attrNames
                      (builtins.removeAttrs tesseractLanguages [ "recurseForDerivations" "all" ]);
    url = lang: "https://github.com/tesseract-ocr/tessdata/raw/${tessdataRev}/${lang}.traineddata";
    commands = map (lang: ''
      echo "${lang} = \"$(nix-prefetch-url ${url lang} 2>/dev/null)\";"
    '') languageCodes;
  in
    builtins.concatStringsSep "\n" commands
EOF
)
cmds=$(nix eval --raw "($nixSrc)")

eval "$cmds"
