{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "watchgod";
  version = "0.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "SBQNYrDr6d2c+DgTN/BjUeHy5wsiA/qcbv9OVyyoTyk=";
  };

  meta = with lib; {
    description = "Simple, modern file watching and code reload in python.";
    homepage = "https://github.com/samuelcolvin/watchgod";
    license = licenses.asl20;
    maintainers = with maintainers; [ Flakebi ];
  };
}
