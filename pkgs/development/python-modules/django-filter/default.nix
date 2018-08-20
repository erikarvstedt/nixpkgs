{ lib, buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "django-filter";
  version = "1.1.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0slpfqfhnjrzlrb6vmswyhrzn01p84s16j2x1xib35gg4fxg23pc";
  };

  doCheck = false;

  meta = with lib; {
    description = "Django-filter is a reusable Django application for allowing users to filter querysets dynamically.";
    homepage = https://github.com/carltongibson/django-filter;
    license = licenses.bsdOriginal;
  };
}
