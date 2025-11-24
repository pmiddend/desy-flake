{ final, prev, pkgs }:
let
  srcCommit = "b33295494a96a726665d03fe52ea359d204d9589";
  src = pkgs.fetchurl {
    url = "https://gitlab.desy.de/philipp.middendorf/asapo/-/archive/${srcCommit}/asapo-${srcCommit}.tar.gz";
    hash = "sha256-R/H5SxiSyb0zx1vQK9PPA0n548b/yXhSSgNdBV97q0M=";
  };
  asapoVersion = "24.11.1";
  # Here we duplicate whatever CMake does (which is shitty of us, we know)
  postPatch = ''
    sed -e 's/@ASAPO_CONSUMER_PROTOCOL@/v0.7/' \
        -e 's/@ASAPO_PRODUCER_PROTOCOL@/v0.7/' \
        -e 's/@ASAPO_ASAPOVERSION@/${asapoVersion}/' \
        -e 's/@ASAPO_ASAPOVERSION_COMMIT@/deadbeef/' \
        -e 's/@ASAPO_DISCOVERY_API_VER@/v0.1/' \
        -e 's/@ASAPO_AUTHORIZER_API_VER@/v0.2/' \
        -e 's/@ASAPO_BROKER_API_VER@/v0.7/' \
        -e 's/@ASAPO_FILE_TRANSFER_SERVICE_API_VER@/v0.2/' \
        -e 's/@ASAPO_RECEIVER_API_VER@/v0.7/' \
        -e 's/@ASAPO_RDS_API_VER@/v0.1/' common/go/src/asapo_common/version/version_lib.go.in > common/go/src/asapo_common/version/version_lib.go
  '';
in
rec {

  asapo-broker = pkgs.buildGoModule {
    pname = "asapo-broker";
    inherit src;
    version = asapoVersion;
    modRoot = "broker/src/asapo_broker";

    vendorHash = "sha256-2dPwOEVN1XKawcPUUiNMK+ZK5fqmR4vbgt7h98Bn2CY=";

    # I think the tests actually run requests and stuff
    doCheck = false;

    postInstall = ''
      mv $out/bin/main $out/bin/broker
    '';

    inherit postPatch;
  };
  asapo-discovery = pkgs.buildGoModule {
    pname = "asapo-discovery";
    inherit src;
    version = asapoVersion;
    modRoot = "discovery/src/asapo_discovery";

    vendorHash = "sha256-x9vRQreDLPrjtpdTozH5ucp2N6GflPGyLTxWxlTWOao=";

    # I think the tests actually run requests and stuff
    doCheck = false;

    postInstall = ''
      mv $out/bin/main $out/bin/discovery
    '';

    inherit postPatch;
  };
  asapo-authorizer = pkgs.buildGoModule {
    pname = "asapo-authorizer";
    inherit src;
    version = asapoVersion;
    modRoot = "authorizer/src/asapo_authorizer";

    vendorHash = "sha256-lvnah1U5sTfB3dw+sYQu+Z6zVtqhHFuGk+7Mpc1tO5E=";

    # I think the tests actually run requests and stuff
    doCheck = false;

    postInstall = ''
      mv $out/bin/main $out/bin/authorizer
    '';

    inherit postPatch;
  };

  asapo-file-transfer = pkgs.buildGoModule {
    pname = "asapo-file-transfer";
    inherit src;
    version = asapoVersion;
    modRoot = "file_transfer/src/asapo_file_transfer";

    vendorHash = "sha256-CclNEY2mf44dfytY1eymJ9kKOdFYr8ekiIYcJKORFsE=";

    # I think the tests actually run requests and stuff
    doCheck = false;

    postInstall = ''
      mv $out/bin/main $out/bin/file-transfer
    '';

    inherit postPatch;
  };

  asapo-monitoring-server = pkgs.buildGoModule {
    pname = "asapo-monitoring-server";
    inherit src;
    version = asapoVersion;
    modRoot = "monitoring/monitoring_server/src/asapo_monitoring_server";

    vendorHash = "sha256-ly7od+tETxXITjisqa1Xv3XgZkYK0RYs9z8jFut/aic=";

    # I think the tests actually run requests and stuff
    doCheck = false;

    postInstall = ''
      mv $out/bin/main $out/bin/monitoring-server
    '';

    inherit postPatch;
  };

  # Taken from
  # https://discourse.nixos.org/t/how-to-create-an-overlay-for-a-python-package-in-a-flake/46247
  pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
    (python-final: python-prev: {
      asapo-consumer =
        pkgs.python3Packages.callPackage ./asapo_python_consumer.nix {
          inherit asapoVersion;
          inherit src;
          inherit asapo-libs;
        };
      asapo-producer =
        pkgs.python3Packages.callPackage ./asapo_python_producer.nix {
          inherit asapoVersion;
          inherit src;
          inherit asapo-libs;
        };
      seedee = pkgs.python3Packages.callPackage ./seedee-python.nix { seedee-lib = final.seedee; };

      bitshuffle = pkgs.python3Packages.callPackage ./bitshuffle.nix { };
    })
  ];

  python3 =
    let
      self = prev.python3.override {
        inherit self;
        packageOverrides = prev.lib.composeManyExtensions final.pythonPackagesOverlays;
      };
    in
    self;

  python3Packages = final.python3.pkgs;

  asapo-libs = pkgs.stdenv.mkDerivation {
    name = "asapo-libs";
    inherit src;

    nativeBuildInputs = [ pkgs.cmake ];

    buildInputs = with pkgs; [
      curl
      rdkafka
      mongoc
      cyrus_sasl
      python3
      # Needed to build Python bindings for consumer/producer
      # python3Packages.cython
      # python3Packages.numpy
      # python3Packages.setuptools
    ];

    cmakeFlags = [
      # Python fails because the dependencies regarding setuptools changed and 3.12 doesn't work
      # Specifically, it says that setuptools isn't found
      "-DBUILD_PYTHON=OFF"
    ];

    # The following units are built separately
    postPatch = ''
      sed -ie 's/add_subdirectory(broker)//' CMakeLists.txt
      sed -ie 's/add_subdirectory(discovery)//' CMakeLists.txt
      sed -ie 's/add_subdirectory(authorizer)//' CMakeLists.txt
      sed -ie 's/add_subdirectory(asapo_tools)//' CMakeLists.txt
      sed -ie 's/add_subdirectory(file_transfer)//' CMakeLists.txt
      sed -ie 's/add_subdirectory(monitoring)//' CMakeLists.txt
    '';
  };

  asapo-libs-devel = with pkgs; stdenv.mkDerivation rec {
    pname = "asapo-devel";

    # Version is "wrong", we're using a develop version
    version = "26.01.0";

    src = fetchurl {
      url = "https://gitlab.desy.de/asapo/asapo/-/archive/4ebf4f1eb32ad06b9ab11691da93a82b5f8c347d/asapo-4ebf4f1eb32ad06b9ab11691da93a82b5f8c347d.tar.gz";
      hash = "sha256-0VSDXAiZvzcA55WDe90kmkyco436IU+vYfsFDEdnvZ4=";
      # This is for the stable versions
      # url = "https://gitlab.desy.de/asapo/asapo/-/archive/${version}/asapo-${version}.tar.gz";
      # hash = "sha256-DzqjHU4iqunrPTNV22D7FHZTBNzTh1A75qxfc2/VHBE=";
    };

    nativeBuildInputs = [ cmake ];

    buildInputs = [
      curl
      rdkafka
      mongoc
      cyrus_sasl
      # Python is not strictly needed, but the build wants it present.
      python3
    ];

    cmakeFlags = [
      "-DBUILD_PYTHON=OFF"
      # This is actually just to let cmake not build the clients. We
      # build them ourselves, with Nix methods.
      "-DBUILD_CLIENTS_ONLY=ON"
    ];

    # This is to get rid of a "git" dependency for the version number
    preConfigure = ''
      export CI_COMMIT_REF_NAME=${version}
      export CI_COMMIT_TAG=${version}
    '';

    # Vendoring rapidjson for good measure.
    postPatch = ''
      rm -r 3d_party/rapidjson/include/rapidjson
      cp -R ${rapidjson}/include 3d_party/rapidjson
    '';

    patches = [
      # This is the user data ptr to producer callback
      (fetchpatch
        {
          url = "https://gitlab.desy.de/asapo/asapo/commit/1f714c27eb12b32a330d28f9f09022641084a638.diff";
          sha256 = "sha256-IP6e8YWkZ4Kc22xA2lrUvyX7F62A6MpGDxgagwy/hdc=";
        })
    ];
  };

  asapo-examples = pkgs.stdenv.mkDerivation {
    name = "asapo-examples";
    inherit src;
    # src = /home/pmidden/code/fs-sc/asapo/docs/site/examples/cpp/.;

    sourceRoot = "asapo-${srcCommit}/docs/site/examples/cpp";
    # sourceRoot = docs/site/examples/cpp/.;
    # postUnpack = "cd */docs/site/examples/cpp";
    # postUnpack = ''
    #   echo "========================="
    #   cd asapo-7da189747d5fa86e87e1431db7a70cb457c88c3b/docs/site/examples/cpp
    # '';

    nativeBuildInputs = [ pkgs.cmake ];

    buildInputs = [ final.asapo-libs pkgs.curl ];
  };


  asapo-for-crystfel = final.asapo-libs;
  crystfel-headless = final.callPackage ./crystfel.nix { withGui = false; asapo = asapo-for-crystfel; };
  crystfel = final.callPackage ./crystfel.nix { asapo = asapo-for-crystfel; };
  crystfel-devel = final.callPackage ./crystfel-devel.nix { asapo = asapo-for-crystfel; };
  crystfel-devel-headless = final.callPackage ./crystfel-devel.nix { withGui = false; asapo = asapo-for-crystfel; };
  seedee = final.callPackage ./seedee.nix { };
  asapo_eiger_connector = final.python3Packages.callPackage ./asapo_eiger_connector.nix { };
  silx = final.callPackage ./silx.nix { };
  lavue = final.callPackage ./lavue.nix { };
  h5cpp = final.callPackage ./h5cpp.nix { };
}
