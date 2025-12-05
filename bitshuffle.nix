{ buildPythonPackage, fetchurl, setuptools, fetchPypi, numpy, cython, h5py }:
buildPythonPackage rec {
  pname = "bitshuffle";
  version = "0.5.2";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-3A4/t72/Qr4QCcwwKHRBgGANYlp1sxgzokqjKur4PY0=";
  };

  build-system = [ setuptools ];

  pyproject = true;

  dependencies = [ numpy cython h5py ];
}
