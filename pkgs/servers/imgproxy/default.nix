{ lib, buildGoModule, fetchFromGitHub, pkg-config, vips, gobject-introspection }:

buildGoModule rec {
  version = "v2.8.1";
  name = "imgproxy-${version}";

  buildInputs = [
    gobject-introspection
    pkg-config
    vips
  ];

  src = fetchFromGitHub {
    owner ="imgproxy";
    repo = "imgproxy";
    sha256 = "00hhgh6nrzg2blc6yl8rph5h5w7swlkbh0zgsj7xr0lkm10879pc";
    rev = "${version}";
  };
  preBuild = ''
    export CGO_LDFLAGS_ALLOW='-(s|w)'
  '';

  goPackagePath = "github.com/imgproxy/imgproxy";

  modSha256 = "0w2k1v6zvk2kwh91idfisry3wly18ix8j13zjpl2q3hmv06mghpg";

  meta = with lib; {
    description = "Fast and secure on-the-fly image processing server written in Go";
    license = licenses.mit;
    maintainers = with maintainers; [ paluh ];
    homepage = https://imgproxy.net/;
  };
}
