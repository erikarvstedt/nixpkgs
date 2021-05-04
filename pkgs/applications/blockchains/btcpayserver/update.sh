#!/usr/bin/env bash
set -euo pipefail

scriptDir=$(cd "${BASH_SOURCE[0]%/*}" && pwd)

echo "Updating nbxplorer"
"$scriptDir"/../nbxplorer/update.sh
echo "Updating btcpayserver"
"$scriptDir"/../nbxplorer/util/update-common.sh btcpayserver "$scriptDir"/deps.nix
