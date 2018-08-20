{ lib, buildPythonPackage, fetchPypi, poppler }:

buildPythonPackage rec {
  pname = "pdftotext";
  version = "2.0.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1f3cbkkb9p0iqrhb06s43qz25i6kfhqrxkv1r3sjngss4pysk0hb";
  };

  buildInputs = [ poppler ];

  meta = with lib; {
    description = "Simple PDF text extraction";
    homepage = https://github.com/jalan/pdftotext;
    license = licenses.mit;
  };
}
