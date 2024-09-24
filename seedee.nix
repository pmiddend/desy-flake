{ stdenv, cmake }:
stdenv.mkDerivation {
  pname = "seedee";
  version = "0.2.4";
  src = /home/pmidden/code/fs-sc/seedee;
  # src = fetchurl {
  #   url = /home/pmidden/code/fs-sc/seedee;
  #   hash = "";
  # };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ ];
}
