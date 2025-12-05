{ stdenv, cmake, fetchurl, zlib, nlohmann_json, lib }:
stdenv.mkDerivation rec {
  pname = "seedee";
  version = "v0.3.1";

  src = fetchurl {
    url = "https://gitlab.desy.de/fs-sc/seedee/-/archive/${version}/seedee-${version}.tar.gz";
    hash = "sha256-T5kmsUZ7EDE9d6J9Wel0lWNyNZTANi7Q3LxKrlaAcmY=";
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
