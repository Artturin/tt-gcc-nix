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

            crossOverlays = [
              (final: prev: {
                #stdenv = prev.stdenvAdapters.overrideCC prev.stdenv (
                #  prev.stdenv.cc.override {
                #    bintools = prev.stdenv.cc.bintools.override {
                #      bintools = prev.buildPackages.callPackage (
                #        {
                #          texinfo,
                #          flex,
                #          gmp,
                #          isl,
                #          mpfr,
                #          libmpc,
                #          gettext,
                #        }:
                #        (prev.stdenv.cc.bintools.bintools.override { enableShared = false; }).overrideAttrs
                #          (previousAttrs: {
                #            nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
                #              texinfo
                #              flex
                #              gettext # probably not necessary
                #            ];
                #            buildInputs = previousAttrs.buildInputs ++ [
                #              gmp
                #              isl
                #              # configure:6290: checking for isl 0.15 or later
                #              # configure:6303: gcc -o conftest -g -O2      -lisl -lmpc -lmpfr -lgmp conftest.c  -lisl -lgmp >&5
                #              # /nix/store/81xsp348yfgmaan9r5055mcdjfw7a8wc-binutils-2.42/bin/ld: cannot find -lmpc: No such file or directory
                #              # /nix/store/81xsp348yfgmaan9r5055mcdjfw7a8wc-binutils-2.42/bin/ld: cannot find -lmpfr: No such file or directory
                #              # collect2: error: ld returned 1 exit status
                #              mpfr
                #              libmpc
                #            ];
                #            version = "2.39";
                #            src = (
                #              pkgs.fetchurl {
                #                url = "https://github.com/ThePerfectComputer/sfpi-binutils/archive/ef96897f5209541d2c6b3464e40430d5cb02b1f6.tar.gz";
                #                sha256 = "sha256-NlHelM9+QpMhPbYBQLUqjclqHEVW/go2RBfC8Zvlw3c=";
                #              }
                #            );

                #            #enableParallelBuilding = false;

                #            #configureFlags = lib.remove "--enable-64-bit-bfd" previousAttrs.configureFlags;

                #            preConfigure = ''
                #              CONFIGURE_MTIME_REFERENCE=$(mktemp configure.mtime.reference.XXXXXX)
                #              find . \
                #                -executable \
                #                -type f \
                #                -exec touch -r {} "$CONFIGURE_MTIME_REFERENCE" \; \
                #                -exec sed -i s_/usr/bin/file_file_g {} \;    \
                #                -exec touch -r "$CONFIGURE_MTIME_REFERENCE" {} \;
                #              rm -f "$CONFIGURE_MTIME_REFERENCE"
                #            '';
                #          })
                #      ) { };
                #    };
                #  }
                #);
              })
            ];

          }).__splicedPackages;
      in
      {
        packages = {
          default = self.packages."${system}".tt-gcc;
          tt-gcc = tt-gccLambda pkgs;
          inherit pkgs;
        };

        checks = {
          simple = pkgs.runCommand "test" { nativeBuildInputs = [ self.packages.${system}.tt-gcc ]; } ''
            mkdir -p $out
            $CC -mwormhole ${./test.c} -o $out/test.c
            #$CC ${./test.c} -o $out/test.c
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
            nativeBuildInputs = [ self.packages.${system}.tt-gcc ];
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
