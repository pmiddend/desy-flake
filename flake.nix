{
  description = "Flake exposing services and applications specific to DESY";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.simplon-stub.url = "github:pmiddend/simplon-stub";

  outputs = { self, nixpkgs, simplon-stub }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      overlays.default = final: prev: import ./packages.nix {
        inherit final prev pkgs;
      };

      packages.${system} =
        let
          local-pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        with local-pkgs; {
          inherit
            crystfel
            crystfel-devel
            crystfel-headless
            crystfel-devel-headless
            seedee
            asapo_eiger_connector
            asapo-libs
            asapo-libs-devel
            asapo-broker
            asapo-authorizer
            h5cpp;
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
