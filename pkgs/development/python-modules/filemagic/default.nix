{ stdenv, lib, buildPythonPackage, fetchPypi, file }:

buildPythonPackage rec {
  pname = "filemagic";
  version = "1.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1wyvss8xk0l0ys56ivbzvdxp32cglzw5pg0fdx0gw808yjg3b176";
  };

  postPatch = ''
    substituteInPlace magic/api.py --replace "ctypes.util.find_library('magic')" \
      "'${file}/lib/libmagic${stdenv.hostPlatform.extensions.sharedLibrary}'"
  '';

  doCheck = false;

  meta = with lib; {
    description = "File type identification using libmagic";
    homepage = https://github.com/aliles/filemagic;
    license = licenses.asl20;
  };
}
