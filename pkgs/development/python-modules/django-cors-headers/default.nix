{ lib, buildPythonPackage, fetchFromGitHub
, pytest, pytest-django, pytestcov }:

buildPythonPackage rec {
  pname = "django-cors-headers";
  version = "2.4.0";

  # Don't use the PyPI source because it's missing test files
  src = fetchFromGitHub {
    owner = "ottoyiu";
    repo = "django-cors-headers";
    rev = version;
    sha256 = "1bj3fj4cknmf8qqnv91rig3gablnx6hx2rlvbnhcgwm97awdsmpf";
  };

  checkInputs = [ pytest pytest-django pytestcov ];

  checkPhase = ''
    PYTHONPATH="$(pwd):$PYTHONPATH" \
    DJANGO_SETTINGS_MODULE=tests.settings \
      pytest tests
  '';

  meta = with lib; {
    description = "Django app for handling the server headers required for CORS";
    homepage = https://github.com/ottoyiu/django-cors-headers;
    license = licenses.mit;
  };
}
