{ lib, stdenv, fetchFromGitHub, fetchurl, linkFarmFromDrvs, makeWrapper,
  dotnetPackages, dotnetCorePackages
}:

let
  deps = import ./deps.nix {
    fetchNuGet = { name, version, sha256 }: fetchurl {
      name = "nuget-${name}-${version}.nupkg";
      url = "https://www.nuget.org/api/v2/package/${name}/${version}";
      inherit sha256;
    };
  };
  dotnetSdk = dotnetCorePackages.sdk_3_1;
in

stdenv.mkDerivation rec {
  name = "btcpayserver";
  version = "1.0.5.5";

  src = fetchFromGitHub {
    owner = "btcpayserver";
    repo = "btcpayserver";
    rev = "v${version}";
    sha256 = "11h1nrmb7f44msbhhiz9ddqh5ss2kz6d8ysnvd070x3xj5krgnxz";
  };

  nativeBuildInputs = [ dotnetSdk dotnetPackages.Nuget makeWrapper ];

  buildPhase = ''
    mkdir home
    export HOME=$PWD/home
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

    nuget sources Add -Name nixos -Source nixos
    nuget init ${linkFarmFromDrvs "deps" deps} nixos

    dotnet restore --source nixos BTCPayServer/BTCPayServer.csproj
    dotnet publish --no-restore --output $out/lib -c Release BTCPayServer/BTCPayServer.csproj
  '';

  installPhase = ''
    makeWrapper $out/lib/BTCPayServer $out/bin/btcpayserver --set DOTNET_ROOT "${dotnetSdk}"
  '';

  dontStrip = true;

  meta = with lib; {
    description = "Self-hosted, open-source cryptocurrency payment processor";
    homepage = "https://btcpayserver.org";
    maintainers = with maintainers; [ kcalvinalvin earvstedt ];
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
