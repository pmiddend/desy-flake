{ buildPythonApplication, setuptools, pyyaml, pyzmq, numpy, seedee, h5py, asapo-producer, lz4, hdf5plugin, bitshuffle }:

buildPythonApplication {
  pname = "asapo_eiger_connector";
  version = "v0.1.3";

  # Doesn't work because it's not public
  # src = fetchurl {
  #   url = "https://gitlab.desy.de/fs-sc/asapo_eiger_connector/-/archive/${version}/asapo_eiger_connector-${version}.tar.gz";
  #   hash = "sha256-NH55OCvRJ3Zi4ZncfxaGoytFD7JrMRmS47QecQhImSU=";
  # };
  src = fetchGit {
    url = "git@gitlab.desy.de:fs-sc/asapo_eiger_connector.git";
    # rev for v0.1.3 because specifying this directly doesn't work
    rev = "52638f99d10d0d959adf3773a0fb2aa603f4212b";
  };

  build-system = [ setuptools ];

  dependencies = [ pyzmq numpy pyyaml seedee asapo-producer bitshuffle lz4 h5py hdf5plugin ];
}
