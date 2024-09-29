{
  texinfo,
  flex,
  gmp,
  isl,
  mpfr,
  libmpc,
  bintools,
  fetchurl,
}:
(bintools.bintools.override { enableShared = false; }).overrideAttrs (previousAttrs: {
  version = "2.39";
  src = (
    fetchurl {
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
