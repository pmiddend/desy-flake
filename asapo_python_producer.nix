{ buildPythonPackage, asapoVersion, src, setuptools, cython, numpy, asapo-libs, curl }:
buildPythonPackage {
  pname = "asapo_producer";
  version = asapoVersion;

  inherit src;

  sourceRoot = "asapo-b33295494a96a726665d03fe52ea359d204d9589/producer/api/python";

  postPatch = ''
    sed -e 's#@EXTRA_LINK_ARGS@#[]#' -e 's#@EXTRA_COMPILE_ARGS@#[]#' setup.py.in > setup.py
    rm setup.py.in
    sed -e 's/@PYTHON_ASAPO_VERSION@/${asapoVersion}/' setup.cfg.in > setup.cfg
    rm setup.cfg.in
    sed -e 's/@PYTHON_ASAPO_VERSION@/${asapoVersion}/' -e 's/@ASAPO_VERSION_COMMIT@//' asapo_producer.pyx.in > asapo_producer.pyx
    rm asapo_producer.pyx.in
  '';

  build-system = [ setuptools ];

  pyproject = true;

  dependencies = [ cython numpy ];

  buildInputs = [ curl asapo-libs ];
}
