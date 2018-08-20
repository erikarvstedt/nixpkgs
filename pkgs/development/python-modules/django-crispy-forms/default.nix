{ lib, buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "django-crispy-forms";
  version = "1.7.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0pv7y648i8iz7mf64gkjizpbx5d01ap2s4vqqa30n38if6wvlljr";
  };

  doCheck = false;

  meta = with lib; {
    description = "Best way to have Django DRY forms";
    homepage = http://github.com/maraujop/django-crispy-forms;
    license = licenses.mit;
  };
}
