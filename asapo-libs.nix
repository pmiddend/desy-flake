{ static ? false, stdenv, fetchurl, cmake, rdkafka, curl, mongoc, cyrus_sasl, python3 }: stdenv.mkDerivation {
  name = "asapo-libs";

  CI_COMMIT_REF_NAME = "81fd8376233ee73ad6a2f02d42be49096ee340e7";
  CI_COMMIT_TAG = "81fd8376233ee73ad6a2f02d42be49096ee340e7";

  src = fetchurl {
    url = "https://gitlab.desy.de/asapo/asapo/-/archive/81fd8376233ee73ad6a2f02d42be49096ee340e7/asapo-81fd8376233ee73ad6a2f02d42be49096ee340e7.tar.gz";
    hash = "sha256-ABaQuKNVW7Fjcq5ubJniUgeQ+67dEN3/Wg8Ir8QVHWg=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    curl
    rdkafka
    mongoc
    cyrus_sasl
    python3
  ];

  cmakeFlags = [
    # Python fails because the dependencies regarding setuptools changed and 3.12 doesn't work
    # Specifically, it says that setuptools isn't found
    "-DBUILD_PYTHON=OFF"
  ] ++ (if stdenv.hostPlatform.isStatic || static then [ "-DBUILD_SHARED_CLIENT_LIBS=OFF" "-DBUILD_STATIC_CLIENT_LIBS=ON" ] else [ ]);

  # This is to get rid of a "git" dependency for the version number
  # preConfigure = ''
  #   export CI_COMMIT_REF_NAME=${srcCommit}
  #   export CI_COMMIT_TAG=${srcCommit}
  # '';

  patches = [ ./fix-asapo-for-gcc-15.patch ];

  # The following units are built separately
  postPatch = ''
    sed -ie 's/add_subdirectory(broker)//' CMakeLists.txt
    sed -ie 's/add_subdirectory(discovery)//' CMakeLists.txt
    sed -ie 's/add_subdirectory(authorizer)//' CMakeLists.txt
    sed -ie 's/add_subdirectory(asapo_tools)//' CMakeLists.txt
    sed -ie 's/add_subdirectory(file_transfer)//' CMakeLists.txt
    sed -ie 's/add_subdirectory(monitoring)//' CMakeLists.txt
  '';
}
