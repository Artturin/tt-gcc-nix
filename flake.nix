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

  outputs =
    inputs:

    let
      inherit (inputs.nixpkgs) lib;
      inherit (inputs) self;
      tt-gccLambda = pkgs: pkgs.callPackage ./tt-gcc.nix { };
    in
    inputs.utils.lib.eachDefaultSystem (
      system:
      let
        #pkgs = inputs.nixpkgs.legacyPackages.${system};
        pkgs =
          (import inputs.nixpkgs {
            localSystem = system;
            crossSystem = {
              config = "riscv32-none-elf";
              libc = "newlib";
              gcc = {
                abi = "ilp32";
                arch = "rv32i";
              };
            };

            #config.replaceCrossStdenv =
            #  { buildPackages, baseStdenv }:
            #  if baseStdenv.targetPlatform.config == "riscv32-none-elf" then
            #    (buildPackages.stdenvAdapters.overrideCC baseStdenv buildPackages.wrapped-gcc-fork)
            #  else
            #    baseStdenv;

            overlays = [
              (final: prev: {
                #newlib = prev.newlib.overrideAttrs {
                #  version = "4.1.0";
                #  configureFlags = [
                #    "--with-newlib"
                #    "--disable-shared"
                #    "--disable-threads"
                #    "--disable-multilib"
                #  ];
                #  src = (
                #    pkgs.fetchurl {
                #      url = "https://sourceware.org/pub/newlib/newlib-4.1.0.tar.gz";
                #      sha256 = "sha256-8pbjcvUTJCJNOHzBFtw3pr05cZh1Z0b5OisC6aXUAVQ=";
                #    }
                #  );

                #};
                gcc-fork = prev.callPackage ./pkgs/gcc.nix { };
                binutils-fork-unwrapped = prev.callPackage ./pkgs/binutils.nix { };
                bintools-wrapped = prev.wrapBintoolsWith {
                  bintools = final.binutils-fork-unwrapped;
                };
                wrapped-gcc-fork = prev.wrapCCWith {
                  cc = final.gcc-fork;
                  bintools = prev.wrapBintoolsWith {
                    bintools = final.binutils-fork-unwrapped;
                  };
                };
              })

            ];

            crossOverlays = [
              (final: prev: {
                #gcc-fork = prev.callPackage ./pkgs/gcc.nix { };
                #binutils-fork-unwrapped = prev.callPackage ./pkgs/binutils.nix { };
                #wrapped-gcc-fork = prev.wrapCCWith {
                #  cc = prev.gcc-fork;
                #  bintools = prev.wrapBintoolsWith {
                #    bintools = prev.binutils-fork-unwrapped;
                #  };
                #};
                # TODO: just do `stdenv =`
                # There's a stubborn issue with `infinite recursion encountered`
                stdenv-fork = prev.buildPackages.stdenvAdapters.overrideCC prev.stdenv prev.buildPackages.wrapped-gcc-fork;
              })
            ];

          }).__splicedPackages;
      in
      {
        packages = {
          default = self.packages."${system}".tt-gcc;
          #tt-gcc = (tt-gccLambda pkgs).wrapped-cc;
          inherit pkgs;
        };

        checks =
          let
            runCommand =
              name: env:
              pkgs.runCommandWith {
                inherit name;
                derivationArgs = env;
                stdenv = self.packages.${system}.pkgs.stdenv-fork;
              };
          in
          {
            simple =
              runCommand "test"
                {
                  NIX_DEBUG = 3;
                }
                ''
                  mkdir -p $out
                  $CC ${./test.c} -o $out/test
                  $CC -mblackhole ${./test.c} -o $out/test-wormhole
                '';
            #cc-wrapper = pkgs.tests.cc-wrapper.default.override (
            #  let
            #    stdenv = pkgs.stdenv.override {
            #      cc = self.packages.${system}.tt-gcc;
            #    };
            #  in
            #  {
            #    inherit stdenv;
            #  }
            #);
          };

        #apps.default = utils.lib.mkApp {
        #  drv = self.packages."${system}".default;
        #};

        devShells.default =
          with pkgs;
          mkShell {
            #nativeBuildInputs = [ self.packages.${system}.tt-gcc ];
          };

        formatter = pkgs.pkgsBuildBuild.nixfmt-rfc-style;
      }
    )
    // {
      inherit lib;
      overlays.default = (
        final: prev: {
          tt-gcc = tt-gccLambda prev;
        }
      );
    };
}
