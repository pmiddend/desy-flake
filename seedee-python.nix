{ buildPythonPackage, fetchurl, setuptools, seedee-lib, numpy, cython }:
buildPythonPackage rec {
  pname = "seedee";
  version = "v0.3.0";

  src = fetchurl {
    url = "https://gitlab.desy.de/fs-sc/seedee/-/archive/${version}/seedee-${version}.tar.gz";
    sha256 = "sha256-wZcFKhFh8AkEVkElkEFNytYBHubBxWLhhIgfH7yMtso=";
  };

  postPatch = ''
    sed -e 's#@SEEDEE_VERSION@#${version}#' setup.py.in > setup.py
    rm setup.py.in
  '';

  sourceRoot = "seedee-${version}/python";

  build-system = [ setuptools ];

  dependencies = [ numpy cython ];

  buildInputs = [ seedee-lib ];
}
