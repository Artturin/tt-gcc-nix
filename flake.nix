{
  description = "runs programs without installing them";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, naersk, flake-compat }:
    let
      inherit (nixpkgs) lib;
      tt-gccLambda = pkgs:
        pkgs.callPackage ./tt-gcc.nix { };
    in
    utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages = {
            default = self.packages."${system}".tt-gcc;
            tt-gcc = tt-gccLambda pkgs;
          };

          apps.default = utils.lib.mkApp {
            drv = self.packages."${system}".default;
          };

          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [ cargo cargo-edit nix-index rustc rustfmt rustPackages.clippy fzy ];
            RUST_SRC_PATH = rustPlatform.rustLibSrc;
          };
        })
    // {
      overlays.default = (final: prev: {
        comma = tt-gccLambda prev;
      });
    };
}
