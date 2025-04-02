{
  description = "Flake exposing services and applications specific to DESY";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.simplon-stub.url = "github:pmiddend/simplon-stub";

  outputs = { self, nixpkgs, simplon-stub }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      src = pkgs.fetchurl {
        url = "https://gitlab.desy.de/philipp.middendorf/asapo/-/archive/fd5125b8c11217be214f2ea19c49a87bf02cee1e/asapo-fd5125b8c11217be214f2ea19c49a87bf02cee1e.tar.gz";
        sha256 = "sha256-EnAbpNaQorfjcFYTnD2U1oI/CTlgSLHejCvO2mHHuVg=";
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
    {
      overlays.default = final: prev: rec {

        asapo-broker = pkgs.buildGoModule {
          pname = "asapo-broker";
          inherit src;
          version = asapoVersion;
          modRoot = "broker/src/asapo_broker";

          vendorHash = "sha256-M0Pyp8v80FKAtk2qZJHbN6/0TTjAxK/5DG6cOgnMY/g=";

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

          vendorHash = "sha256-HNdHPAH2t7NNgtgkGiYwo6D5IZT81mY6kD7uopt1Hf0=";

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

          vendorHash = "sha256-ZSqUBlEd6Nbj1YDZyFVLnC0yDRtALdKrwyALbA4HK3I=";

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

          vendorHash = "sha256-O8aqGxYUFNEfZcOSX17PVm3WLQm+eAjxDC/Z6DAe9io=";

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

          vendorHash = "sha256-+OTYzacbFwKA9ciPq55QsVscSwc9FyY/nXJg1eIruP0=";

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

        asapo-examples = pkgs.stdenv.mkDerivation {
          name = "asapo-examples";
          src = /home/pmidden/code/fs-sc/asapo/docs/site/examples/cpp/.;

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
      };
      packages.${system} =
        let
          local-pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        with local-pkgs; {
          inherit crystfel crystfel-headless crystfel-devel crystfel-devel-headless seedee asapo_eiger_connector asapo-libs asapo-broker;
        };

      nixosModules.asapo = { pkgs, config, lib, ... }: import ./asapo-nixos-module.nix {
        inherit pkgs config lib;
        default-overlay = self.overlays.default;
      };

      checks.${system}.asapoVmTest = pkgs.callPackage ./asapo-nixos-test.nix {
        inherit simplon-stub;
        asapo-module = self.nixosModules.asapo;
      };
    };

}
