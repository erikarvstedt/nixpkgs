#!/usr/bin/env bash

# Output:
#   eng = "05gvs5kmlmp9ncb3c044vfndl24p5f99k8yfy50aabwksl3575q7";
#   fra = "0606cailv7ap80b9ix72h56lq2ipgk5fsf0f7m3yjcxl0hr5pinb";
#   ...
# for all languages where the actual sha256 doesn't match the expected hash

read -d '' perlSrc <<'EOF'
  print "$1 = \\"$2\\";\\n" if m|-(\\S*?)\\.traineddata' with sha256 hash '(.*?)'|
EOF

(nix-build --no-out-link --keep-going -E '
with (import ../../../.. { config = {}; overlays = []; });
let
  fetchurlHashFail = { ... }@args:
    fetchurl (args // { sha256 = "0000000000000000000000000000000000000000000000000000"; });
  languages = callPackage ./languages.nix { fetchurl = fetchurlHashFail; };
in
  languages.v3
' 2>&1) | perl -ne "$perlSrc"
