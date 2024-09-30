{
  lib,
  texinfo,
  flex,
  gmp,
  isl,
  bintools,
  fetchFromGitHub,
}:
(bintools.bintools.override { enableShared = false; }).overrideAttrs (previousAttrs: {
  version = "2.39";

  src = fetchFromGitHub {
    owner = "ThePerfectComputer";
    repo = "sfpi-binutils";
    rev = "ef96897f5209541d2c6b3464e40430d5cb02b1f6";
    sha256 = "sha256-HJk5ffsdBGT2TZFeCn5m+OzOwlFSvKbcK/cd7MKxp7A=";
  };

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

  configureFlags =
    let
      flagsToRemove =
        [
        ];
    in
    (lib.filter (
      flag: !(lib.any (unwanted: lib.hasPrefix unwanted flag) flagsToRemove)
    ) previousAttrs.configureFlags)
    ++ [
      "--disable-sim"
    ];

})
