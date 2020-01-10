{ lib, buildGoModule, fetchFromGitHub, pkg-config, vips, gobject-introspection }:

buildGoModule rec {
  version = "2.8.1";
  pname = "imgproxy";

  src = fetchFromGitHub {
    owner ="imgproxy";
    repo = "imgproxy";
    sha256 = "00hhgh6nrzg2blc6yl8rph5h5w7swlkbh0zgsj7xr0lkm10879pc";
    rev = "v${version}";
  };

  buildInputs = [
    gobject-introspection
    pkg-config
    vips
  ];

  preBuild = ''
    export CGO_LDFLAGS_ALLOW='-(s|w)'
  '';

  goPackagePath = "github.com/imgproxy/imgproxy";

  modSha256 = "0kgd8lwcdns3skvd4bj4z85mq6hkk79mb0zzwky0wqxni8f73s6w";

  meta = with lib; {
    description = "Fast and secure on-the-fly image processing server written in Go";
    homepage = https://imgproxy.net;
    license = licenses.mit;
    maintainers = with maintainers; [ paluh ];
  };
}
