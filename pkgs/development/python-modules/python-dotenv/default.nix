{ lib, buildPythonPackage, fetchPypi, click, ipython }:

buildPythonPackage rec {
  pname = "python-dotenv";
  version = "0.8.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1mc901wfxd0sxw0baqcb08dh66waarkfcx4r009ic4apa8c3d5sh";
  };

  checkInputs = [ click ipython ];

  meta = with lib; {
    description = "Add .env support to your django/flask apps in development and deployments";
    homepage = http://github.com/theskumar/python-dotenv;
    license = licenses.bsdOriginal;
  };
}
