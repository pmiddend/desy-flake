{ stdenv, cmake, fetchurl, zlib, nlohmann_json, lib }:
stdenv.mkDerivation rec {
  pname = "seedee";
  version = "v0.3.0";

  src = fetchurl {
    url = "https://gitlab.desy.de/fs-sc/seedee/-/archive/${version}/seedee-${version}.tar.gz";
    sha256 = "sha256-wZcFKhFh8AkEVkElkEFNytYBHubBxWLhhIgfH7yMtso=";
  };

  doCheck = true;

  cmakeFlags = [
    "-DSEEDEE_USE_EXTERNAL_ZLIB=ON"
    "-DSEEDEE_USE_EXTERNAL_JSON=ON"
    "-DBUILD_TESTS=ON"
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ zlib nlohmann_json ];

  meta = with lib; {
    description = "Serialization format for multi-dimensional arrays based on HDF5 chunks";
    homepage = "https://gitlab.desy.de/fs-sc/seedee";
    maintainers = with maintainers; [ pmiddend ];
    license = with licenses; [ mit ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
