{ buildPythonPackage, asapoVersion, src, setuptools, cython, numpy, asapo-libs, curl }:
buildPythonPackage {
  pname = "asapo_consumer";
  version = asapoVersion;

  inherit src;

  sourceRoot = "asapo-7da189747d5fa86e87e1431db7a70cb457c88c3b/producer/api/python/consumer/api/python";

  postPatch = ''
    sed -e 's#@EXTRA_LINK_ARGS@#[]#' -e 's#@EXTRA_COMPILE_ARGS@#[]#' setup.py.in > setup.py
    rm setup.py.in
    sed -e 's/@PYTHON_ASAPO_VERSION@/${asapoVersion}/' setup.cfg.in > setup.cfg
    rm setup.cfg.in
    sed -e 's/@PYTHON_ASAPO_VERSION@/${asapoVersion}/' -e 's/@ASAPO_VERSION_COMMIT@//' asapo_consumer.pyx.in > asapo_consumer.pyx
    rm asapo_consumer.pyx.in
  '';

  build-system = [ setuptools ];

  pyproject = true;

  dependencies = [ cython numpy ];

  buildInputs = [ curl asapo-libs ];
}
