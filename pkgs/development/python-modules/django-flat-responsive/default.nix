{ lib, buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "django-flat-responsive";
  version = "2.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0x3439m2bim8r0xldx99ry0fksfyv39k8bffnwpvahf500ksl725";
  };

  doCheck = false;

  meta = with lib; {
    description = "An extension for Django admin that makes interface mobile friendly.";
    homepage = https://github.com/elky/django-flat-responsive;
    license = licenses.bsdOriginal;
  };
}
