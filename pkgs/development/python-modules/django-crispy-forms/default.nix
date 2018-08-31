{ lib, buildPythonPackage, fetchPypi
, pytest, pytest-django, django }:

buildPythonPackage rec {
  pname = "django-crispy-forms";
  version = "1.7.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0pv7y648i8iz7mf64gkjizpbx5d01ap2s4vqqa30n38if6wvlljr";
  };

  checkInputs = [pytest pytest-django django ];

  checkPhase = ''
    PYTHONPATH="$(pwd):$PYTHONPATH" \
    DJANGO_SETTINGS_MODULE=crispy_forms.tests.test_settings \
      pytest crispy_forms/tests
  '';

  meta = with lib; {
    description = "The best way to have DRY Django forms";
    homepage = http://github.com/maraujop/django-crispy-forms;
    license = licenses.mit;
  };
}
