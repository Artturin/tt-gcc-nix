{
  buildPackages,
  fetchpatch,
  stdenv,
  fetchurl,
  pkgs, # remove
  callPackage,
# don't add `pkgs`, it is not spliced, instead add the attrs separately.
}:

let
  binutilsRev = "ef96897f5209541d2c6b3464e40430d5cb02b1f6";
  gccRev = "9b05394f53925372db0330098916a94fde47bda5";
  newlibRev = "4.1.0"; # Adjust the version if needed

  gcc-fork-unwrapped = buildPackages.callPackage (
    { flex }:
    buildPackages.gcc10.cc.overrideAttrs (previousAttrs: {
      version = "10.2.0";
      src = (
        pkgs.fetchurl {
          url = "https://github.com/tenstorrent/sfpi-gcc/archive/${gccRev}.tar.gz";
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
  );

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
    buildPackages.binutils-unwrapped.overrideAttrs (previousAttrs: {
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
        libopcodes
        libbfd
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

  #binutils-unwrapped = buildPackages.callPackage (
  #  {
  #    texinfo,
  #    flex,
  #    gmp,
  #    isl,
  #    mpfr,
  #    libmpc,
  #    libopcodes,
  #    libbfd,
  #    autoreconfHook269,
  #  }:
  #  (buildPackages.callPackage ./pkgs/binutils {
  #    noSysDirs = (stdenv.targetPlatform != stdenv.hostPlatform);
  #    autoreconfHook = autoreconfHook269;
  #  }).overrideAttrs
  #    (previousAtts: {
  #      # 2.38 is the closest ver in nixpkgs.
  #      version = "2.39";
  #      src = (
  #        pkgs.fetchurl {
  #          url = "https://github.com/ThePerfectComputer/sfpi-binutils/archive/${binutilsRev}.tar.gz";
  #          sha256 = "sha256-NlHelM9+QpMhPbYBQLUqjclqHEVW/go2RBfC8Zvlw3c=";
  #        }
  #      );

  #      nativeBuildInputs = previousAtts.nativeBuildInputs ++ [
  #        texinfo
  #        flex
  #      ];

  #      buildInputs = previousAtts.buildInputs ++ [
  #        gmp
  #        isl
  #        # configure:6290: checking for isl 0.15 or later
  #        # configure:6303: gcc -o conftest -g -O2      -lisl -lmpc -lmpfr -lgmp conftest.c  -lisl -lgmp >&5
  #        # /nix/store/81xsp348yfgmaan9r5055mcdjfw7a8wc-binutils-2.42/bin/ld: cannot find -lmpc: No such file or directory
  #        # /nix/store/81xsp348yfgmaan9r5055mcdjfw7a8wc-binutils-2.42/bin/ld: cannot find -lmpfr: No such file or directory
  #        # collect2: error: ld returned 1 exit status
  #        mpfr
  #        libmpc
  #        libopcodes
  #        libbfd
  #      ];
  #      #configureFlags = previousAtts.configureFlags ++ [
  #      #  "--with-abi=ilp32"
  #      #  "--with-arch=rv32i"
  #      #];

  #    })
  #) { };

  newlib = buildPackages.gcc10.libc.overrideAttrs (previousAttrs: {
    version = newlibRev;
    src = (
      pkgs.fetchurl {
        url = "https://sourceware.org/pub/newlib/newlib-${newlibRev}.tar.gz";
        sha256 = "sha256-8pbjcvUTJCJNOHzBFtw3pr05cZh1Z0b5OisC6aXUAVQ=";
      }
    );

  });

  toolchain = pkgs.stdenv.mkDerivation {
    name = "riscv32-unknown-elf-toolchain";
    version = "1.0";

    srcs = [

    ];

    nativeBuildInputs = with pkgs; [
      wget
      which
      rsync
      gmp
      libmpc
      mpfr
      python3
      bison
      flex
      texinfo
      zlib
    ];

    # I believe the following prevents gcc from treating "-Werror=format-security"
    # warnings as errors
    hardeningDisable = [ "format" ];

    sourceRoot = ".";

    buildPhase = ''
      echo $PWD
      ls -lah .

      mkdir $out

      # Build binutils
      mkdir build-binutils
      cd build-binutils
      ../sfpi-binutils-${binutilsRev}/configure \
        --target=riscv32-unknown-elf \
        --prefix=$out \
        --disable-shared \
        --disable-threads \
        --disable-multilib \
        --with-gmp=${pkgs.gmp}\
        --with-mpfr=${pkgs.mpfr}\
        --with-mpc=${pkgs.libmpc} \
        --with-abi=ilp32 \
        --with-arch=rv32i

      make -j$(nproc)
      make install
      cd ..

      # Build GCC
      mkdir build-gcc
      cd build-gcc
      ../sfpi-gcc-${gccRev}/configure \
        --target=riscv32-unknown-elf \
        --prefix=$out \
        --disable-shared \
        --disable-threads \
        --disable-multilib \
        --with-headers=../newlib-${newlibRev}/newlib/libc/include \
        --with-gmp=${pkgs.gmp}\
        --with-mpfr=${pkgs.mpfr}\
        --with-mpc=${pkgs.libmpc} \
        --with-abi=ilp32 \
        --with-arch=rv32i
      make -j$(nproc) all-gcc
      make install-gcc

      cd ..

      mkdir newlib-gcc
      cd newlib-gcc

      export PATH=$out/bin:$PATH

      ../newlib-${newlibRev}/configure \
        --target=riscv32-unknown-elf \
        --prefix=$out \
        --disable-shared \
        --disable-threads \
        --disable-multilib \
        --with-abi=ilp32 \
        --with-arch=rv32i

      make -j$(nproc)
      make install

      cd ..

      # build gcc again with newlib
      cd build-gcc
      make -j$(nproc)
      make install
    '';

    meta = {
      description = "RISC-V 32-bit bare-metal toolchain.";
      homepage = "https://example.com";
      license = pkgs.lib.licenses.gpl2;
    };
  };
in
#gcc-fork
buildPackages.wrapCCWith {
  cc = gcc-fork-unwrapped;
  bintools = buildPackages.wrapBintoolsWith {
    bintools = binutils-unwrapped;
  };
}
