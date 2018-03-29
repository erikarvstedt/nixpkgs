{ stdenv, lib, jre, fetchurl, makeWrapper }:

stdenv.mkDerivation rec {
  name = "ripme-${version}";
  version = "1.7.28";

  src = fetchurl {
    url = "https://github.com/RipMeApp/ripme/releases/download/${version}/ripme.jar";
    sha256 = "03ca9h4pc0lk7rcq2pb92qf8gn85b6lkm4pc78i7m194x6ljpnlk";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildCommand = ''
    makeWrapper ${jre}/bin/java $out/bin/ripme --add-flags "-jar $src"
  '';

  meta = with lib; {
    description = "Content downloader for various websites";
    homepage = https://github.com/RipMeApp/ripme;
    license = licenses.mit;
    maintainers = [ maintainers.earvstedt ];
  };
}
