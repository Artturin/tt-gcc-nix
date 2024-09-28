{
  lib,
  buildPackages,
  fetchpatch,
  stdenv,
  fetchurl,
  pkgs, # remove
  callPackage,
# don't add `pkgs`, it is not spliced, instead add the attrs separately.
}:

let
  newlibRev = "4.1.0"; # Adjust the version if needed

  gcc-fork-unwrapped = buildPackages.callPackage (
    { flex }:
    buildPackages.gcc10.cc.overrideAttrs (previousAttrs: {
      version = "10.2.0";
      src = (
        pkgs.fetchurl {
          url = "https://github.com/tenstorrent/sfpi-gcc/archive/9b05394f53925372db0330098916a94fde47bda5.tar.gz";
          sha256 = "sha256-YOaybTRADLI+gfCMs61gEJKNDCkfpUTL8N+qq0z14SY=";
        }
      );

      nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
        # fix `cc1plus: fatal error: gengtype-lex.c: No such file or directory`
        # Found in https://gibsonic.org/tools/2019/08/08/gcc_building.html
        flex
      ];

      # TODO: why not automatically patched in https://github.com/NixOS/nixpkgs/blob/49be301a59b894ffe96a964a525cfa6bcdab5cf6/pkgs/stdenv/generic/setup.sh#L1400
      postPatch = ''
        substituteInPlace libcc1/configure \
          --replace-fail "/usr/bin/file" "file"
      '';

    })
  ) { };

  # NOTE: use the correct `callPackage` for everything so the dependency offsets will be correct.
  # If simply getting `gmp` from the arguments at the top
  # `error: GMP is missing or unusable`
  binutils-unwrapped = buildPackages.callPackage (
    {
      texinfo,
      flex,
      gmp,
      isl,
      mpfr,
      libmpc,
      libopcodes,
      libbfd,
    }:
    (buildPackages.binutils-unwrapped.override { enableShared = false; }).overrideAttrs
      (previousAttrs: {
        # 2.38 is the closest ver in nixpkgs.
        version = "2.39";
        src = (
          pkgs.fetchurl {
            url = "https://github.com/ThePerfectComputer/sfpi-binutils/archive/ef96897f5209541d2c6b3464e40430d5cb02b1f6.tar.gz";
            sha256 = "sha256-NlHelM9+QpMhPbYBQLUqjclqHEVW/go2RBfC8Zvlw3c=";
          }
        );

        nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
          texinfo
          flex
        ];

        buildInputs = previousAttrs.buildInputs ++ [
          gmp
          isl
          # configure:6290: checking for isl 0.15 or later
          # configure:6303: gcc -o conftest -g -O2      -lisl -lmpc -lmpfr -lgmp conftest.c  -lisl -lgmp >&5
          # /nix/store/81xsp348yfgmaan9r5055mcdjfw7a8wc-binutils-2.42/bin/ld: cannot find -lmpc: No such file or directory
          # /nix/store/81xsp348yfgmaan9r5055mcdjfw7a8wc-binutils-2.42/bin/ld: cannot find -lmpfr: No such file or directory
          # collect2: error: ld returned 1 exit status
          mpfr
          libmpc
        ];

        #NIX_DEBUG = 7;

        preConfigure = ''
          CONFIGURE_MTIME_REFERENCE=$(mktemp configure.mtime.reference.XXXXXX)
          find . \
            -executable \
            -type f \
            -exec touch -r {} "$CONFIGURE_MTIME_REFERENCE" \; \
            -exec sed -i s_/usr/bin/file_file_g {} \;    \
            -exec touch -r "$CONFIGURE_MTIME_REFERENCE" {} \;
          rm -f "$CONFIGURE_MTIME_REFERENCE"
        '';
        #configureFlags = previousAtts.configureFlags ++ [
        #  "--with-abi=ilp32"
        #  "--with-arch=rv32i"
        #];

      })
  ) { };

  newlib = buildPackages.gcc10.libc.overrideAttrs (previousAttrs: {
    version = newlibRev;
    src = (
      pkgs.fetchurl {
        url = "https://sourceware.org/pub/newlib/newlib-${newlibRev}.tar.gz";
        sha256 = "sha256-8pbjcvUTJCJNOHzBFtw3pr05cZh1Z0b5OisC6aXUAVQ=";
      }
    );

  });
in
{
  wrapped-cc = buildPackages.wrapCCWith {
    cc = gcc-fork-unwrapped;
    bintools = buildPackages.wrapBintoolsWith {
      bintools = binutils-unwrapped;
    };
  };
}
