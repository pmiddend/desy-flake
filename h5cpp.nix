{ fetchFromGitHub, stdenv, cmake, hdf5 }:
stdenv.mkDerivation rec {
  pname = "h5cpp";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "ess-dmsc";
    repo = "h5cpp";
    rev = "v${version}";
    hash = "sha256-VuOV7UXixk6ChtfDz0FqOclwkZCtoYcq7P2iZ3WlM20=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ hdf5 ];

  cmakeFlags = [ "-DH5CPP_CONAN=DISABLE" "-DH5CPP_DISABLE_TESTS=ON" ];
}
