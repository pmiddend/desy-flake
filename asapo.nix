{ stdenv, fetchurl, cmake, curl, rdkafka, mongoc, cyrus_sasl, python3, python3Packages }:
stdenv.mkDerivation rec {
  pname = "asapo";

  version = "23.11.1";

  src = fetchurl {
    url = "https://gitlab.desy.de/asapo/asapo/-/archive/${version}/asapo-${version}.tar.gz";
    hash = "sha256-eEKYEjGkUIIsOEjKDWg+4SnqtHTMSDak6lnyxnWI1FU=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    curl
    rdkafka
    mongoc
    cyrus_sasl
    python3
    python3Packages.cython
    python3Packages.numpy
  ];

  cmakeFlags = [
    "-DBUILD_PYTHON=OFF"
    # This is actually just to let cmake not build the clients. We
    # build them ourselves, with Nix methods.
    "-DBUILD_CLIENTS_ONLY=ON"
  ];

  patches = [ ./remove-asapo-git-refs.patch ];
}
