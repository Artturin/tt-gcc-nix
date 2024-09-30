{
  lib,
  texinfo,
  flex,
  gmp,
  isl,
  binutils-unwrapped_2_39,
  fetchFromGitHub,
}:
(binutils-unwrapped_2_39.override { enableShared = false; }).overrideAttrs (previousAttrs: {
  version = "2.39";

  src = fetchFromGitHub {
    owner = "tenstorrent";
    repo = "sfpi-binutils";
    rev = "629e241cd35899ae705da9cea63ff4a20104b9a0";
    sha256 = "sha256-vR1RkhEkCG+LOyJ7fQJOE9IAjQhzlzCPCbN3oM9GqAU=";
  };

  patches = [];

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
      "--disable-gdb"
    ];

})
