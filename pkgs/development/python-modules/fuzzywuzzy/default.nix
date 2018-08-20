{ lib, buildPythonPackage, fetchPypi, python-Levenshtein
, pytest, hypothesis, enum34, pycodestyle }:

buildPythonPackage rec {
  pname = "fuzzywuzzy";
  version = "0.16.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0kldif0d393p2wrp80q73mj5z1xpz83zrfrhbf489zsdfk92436l";
  };

  propagatedBuildInputs = [ python-Levenshtein ];

  checkInputs = [ pytest hypothesis enum34 pycodestyle ];

  meta = with lib; {
    description = "Fuzzy string matching in python";
    homepage = https://github.com/seatgeek/fuzzywuzzy;
    license = licenses.gpl2;
  };
}
