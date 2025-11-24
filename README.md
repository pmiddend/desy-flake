# Nix Flake for DESY-related projects

This flake exports an overlay and some packages directly which are used at [DESY](https://www.desy.de).

**Note**: For tango packages, check out [tango-flake](https://gitlab.desy.de/cfel-sc-public/tango-flake)

## Packages inside

- lavue (without pytango though)
- crystfel
- asapo
- seedee
- silx
- h5cpp

## Usage

Either run software directly from the flake:

```
nix run 'git+https://gitlab.desy.de/philipp.middendorf/desy-flake'#crystfel
```

...or use the overlay to include the software directly in your own flake:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.desy-flake.url = "git+https://gitlab.desy.de/philipp.middendorf/desy-flake";

  outputs = { self, nixpkgs, desy-flake }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
	    overlays = [ desy-flake.overlays.default ];
      };
    in
	  packages.${system} = {
	    my-package = {};
	  };
}
```

## asapo

The asapo C libraries come in two versions (both as normal packages you can put into your `buildInputs`): `asapo-libs` and `asapo-libs-devel`. The latter will use a very recent `develop` commit and possibly some patches. The former is just the latest stable version of asapo.
