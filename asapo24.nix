{ stdenv
, fetchurl
, cmake
, curl
, rdkafka
, mongoc
, cyrus_sasl
, python3
, python3Packages
, buildGoModule
}:
let
  version = "24.11.1";
  src = fetchurl {
    url = "https://gitlab.desy.de/asapo/asapo/-/archive/${version}/asapo-${version}.tar.gz";
    hash = "sha256-8T1KgbxdyVDoo8c8RQMIczHDDAN/uhU6IUEJgPZYGCM=";
  };
  asapo-common = buildGoModule rec {
    pname = "asapo_common";
    inherit src version;
    sourceRoot = "asapo-${version}/common/go/src/asapo_common";

    vendorHash = "";
  };
  broker = buildGoModule rec {
    pname = "asapo-broker";
    inherit src version;
    sourceRoot = "asapo-${version}/broker/src/asapo_broker";

    vendorHash = "sha256-fxaI0ugKf7lCczoh3S7qLsoN/h6mC2d82xvpK4ereB0=";

    buildInputs = [ asapo-common ];
  };
  asapo-clients = stdenv.mkDerivation {
    pname = "asapo-clients";

    inherit src version;

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
      # Python fails because the dependencies regarding setuptools changed and 3.12 doesn't work
      # Specifically, it says that setuptools isn't found
      "-DBUILD_PYTHON=OFF"
      # This is actually just to let cmake not build the clients. We
      # build them ourselves, with Nix methods.
      "-DBUILD_CLIENTS_ONLY=ON"
    ];

    patches = [ ./remove-asapo-git-refs-24.patch ];
  };
in
asapo-clients

