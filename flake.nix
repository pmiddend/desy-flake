{
  description = "Flake exposing services and applications specific to DESY";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      overlays.default = final: prev: rec {
        # Taken from
        # https://discourse.nixos.org/t/how-to-create-an-overlay-for-a-python-package-in-a-flake/46247
        # pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
        #   (python-final: python-prev: {
        #     fabio = pkgs.python3Packages.callPackage ./fabio.nix { };
        #   })
        # ];

        # python3 =
        #   let
        #     self = prev.python3.override {
        #       inherit self;
        #       packageOverrides = prev.lib.composeManyExtensions final.pythonPackagesOverlays;
        #     };
        #   in
        #   self;

        # python3Packages = final.python3.pkgs;

        asapo-for-crystfel = asapo24;
        crystfel-headless = final.callPackage ./crystfel.nix { withGui = false; asapo = asapo-for-crystfel; };
        crystfel = final.callPackage ./crystfel.nix { asapo = asapo-for-crystfel; };
        crystfel-devel = final.callPackage ./crystfel-devel.nix { asapo = asapo-for-crystfel; };
        crystfel-devel-headless = final.callPackage ./crystfel-devel.nix { withGui = false; asapo = asapo-for-crystfel; };
        asapo23 = final.callPackage ./asapo23.nix { };
        asapo24 = final.callPackage ./asapo24.nix { };
        seedee = final.callPackage ./seedee.nix { };
        silx = final.callPackage ./silx.nix { };
        lavue = final.callPackage ./lavue.nix { };
      };
      packages.${system} =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        with pkgs; {
          inherit crystfel crystfel-headless crystfel-devel crystfel-devel-headless seedee asapo23 asapo24;
        };
    };
}
