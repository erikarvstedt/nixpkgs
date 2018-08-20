{ lib, buildPythonPackage, fetchurl, six }:

buildPythonPackage rec {
  pname = "langdetect";
  version = "1.0.7";

  # Although langdetect is hosted on PyPI, none of the canonical PyPI mirror URLs
  # (like https://pypi.io/packages/source/l/langdetect/langdetect-1.0.7.tar.gz) are working
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/59/59/4bc44158a767a6d66de18c4136c8aa90491d56cc951c10b74dd1e13213c9/langdetect-1.0.7.zip";
    sha256 = "0c5zm6c7xzsigbb9c7v4r33fcpz911zscfwvh3dq1qxdy3ap18ci";
  };

  propagatedBuildInputs = [ six ];

  meta = with lib; {
    description = "Python port of Google's language-detection library";
    homepage = https://github.com/Mimino666/langdetect;
    license = licenses.asl20;
  };
}
