{ lib, buildDotnetModule, fetchFromGitHub, dotnetCorePackages
, altcoinSupport ? false }:

buildDotnetModule rec {
  pname = "btcpayserver";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-beNgAg+jtS23LiyeqHyjcyLO1q4qjhQLP1P/N1P9tzc=";
  };

  projectFile = "BTCPayServer/BTCPayServer.csproj";
  nugetDeps = ./deps.nix;

  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;

  dotnetFlags = lib.optionals altcoinSupport [ "/p:Configuration=Altcoins-Release" ];

  postFixup = ''
    mv $out/bin/{BTCPayServer,btcpayserver}
  '';

  meta = with lib; {
    description = "Self-hosted, open-source cryptocurrency payment processor";
    homepage = "https://btcpayserver.org";
    maintainers = with maintainers; [ kcalvinalvin earvstedt ];
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
