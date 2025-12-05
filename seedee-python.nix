{ buildPythonPackage, fetchurl, setuptools, seedee-lib, numpy, cython }:
buildPythonPackage rec {
  pname = "seedee";
  version = "v0.3.1";

  src = fetchurl {
    url = "https://gitlab.desy.de/fs-sc/seedee/-/archive/${version}/seedee-${version}.tar.gz";
    hash = "sha256-T5kmsUZ7EDE9d6J9Wel0lWNyNZTANi7Q3LxKrlaAcmY=";
  };

  postPatch = ''
    sed -e 's#@SEEDEE_VERSION@#${version}#' setup.py.in > setup.py
    rm setup.py.in
  '';

  sourceRoot = "seedee-${version}/python";

  build-system = [ setuptools ];

  pyproject = true;

  dependencies = [ numpy cython ];

  buildInputs = [ seedee-lib ];
}
