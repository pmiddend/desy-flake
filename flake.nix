{
  description = "Flake exposing services and applications specific to DESY";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      overlays.default = final: prev: {
        # Taken from
        # https://discourse.nixos.org/t/how-to-create-an-overlay-for-a-python-package-in-a-flake/46247
        pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
          (python-final: python-prev: {
            fabio = pkgs.python3Packages.callPackage ./fabio.nix { };
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

        crystfel-headless = final.callPackage ./crystfel.nix { withGui = false; };
        crystfel = final.callPackage ./crystfel.nix { };
        asapo = final.callPackage ./asapo.nix { };
        seedee = final.callPackage ./seedee.nix { };
        silx = final.callPackage ./silx.nix { };
      };
      packages.${system} =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        with pkgs; {
          inherit crystfel crystfel-headless seedee silx;
        };
    };
}
