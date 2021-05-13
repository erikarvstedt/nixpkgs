{ lib
, buildPythonPackage
, fetchPypi
, portalocker
}:

buildPythonPackage rec {
  pname = "concurrent-log-handler";
  version = "0.9.19";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sS95q+0/lBIcJc6cJM21fYiSguxv9h9VNasgaNw31Ak=";
  };

  propagatedBuildInputs = [ portalocker ];

  # No tests included
  doCheck = false;
  pythonImportsCheck = [ "concurrent_log_handler" ];

  meta = with lib; {
    description = "An additional log handler for Python's standard logging package";
    homepage = "https://github.com/Preston-Landers/concurrent-log-handler";
    license = licenses.asl20;
    maintainers = with maintainers; [ Flakebi ];
  };
}
