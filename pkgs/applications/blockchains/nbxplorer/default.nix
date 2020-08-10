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
  name = "NBXplorer";
  version = "2.1.42";

  src = fetchFromGitHub {
    owner = "dgarage";
    repo = "NBXplorer";
    rev = "v${version}";
    sha256 = "01q6n7095rrha00xs3l7igzfb9rd743z8crxa2dcz4q5srapfzpi";
  };

  nativeBuildInputs = [ dotnetSdk dotnetPackages.Nuget makeWrapper ];

  buildPhase = ''
    mkdir home
    export HOME=$PWD/home
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

    nuget sources Add -Name nixos -Source nixos
    nuget init ${linkFarmFromDrvs "deps" deps} nixos

    dotnet restore --source nixos NBXplorer/NBXplorer.csproj
    dotnet publish --no-restore --output $out/lib -c Release NBXplorer/NBXplorer.csproj
  '';

  installPhase = ''
    makeWrapper $out/lib/NBXplorer $out/bin/nbxplorer \
      --set DOTNET_ROOT "${dotnetSdk}"
  '';

  dontStrip = true;

  meta = with lib; {
    description = "Minimalist UTXO tracker for HD Cryptocurrency Wallets";
    maintainers = with maintainers; [ kcalvinalvin earvstedt ];
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
