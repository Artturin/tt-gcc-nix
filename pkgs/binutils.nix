{
  texinfo,
  flex,
  gmp,
  isl,
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
