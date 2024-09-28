{ pkgs }:

let
  binutilsRev = "ef96897f5209541d2c6b3464e40430d5cb02b1f6";
  gccRev = "9b05394f53925372db0330098916a94fde47bda5";
  newlibRev = "4.1.0"; # Adjust the version if needed
  target = "riscv32-unknown-elf";
in
pkgs.stdenv.mkDerivation {
  name = "riscv32-unknown-elf-toolchain";
  version = "1.0";

  srcs = [
    (pkgs.fetchurl {
      url = "https://github.com/ThePerfectComputer/sfpi-binutils/archive/${binutilsRev}.tar.gz";
      sha256 = "sha256-NlHelM9+QpMhPbYBQLUqjclqHEVW/go2RBfC8Zvlw3c=";
    })
    (pkgs.fetchurl {
      url = "https://github.com/tenstorrent/sfpi-gcc/archive/${gccRev}.tar.gz";
      sha256 = "sha256-YOaybTRADLI+gfCMs61gEJKNDCkfpUTL8N+qq0z14SY=";
    })
    (pkgs.fetchurl {
      url = "https://sourceware.org/pub/newlib/newlib-${newlibRev}.tar.gz";
      sha256 = "sha256-8pbjcvUTJCJNOHzBFtw3pr05cZh1Z0b5OisC6aXUAVQ=";
    })
  ];

  buildInputs = with pkgs; [
    gcc
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
}
