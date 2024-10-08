{
  lib,
  flex,
  gcc10,
  fetchFromGitHub,
  bintools-wrapped,

}:
gcc10.cc.overrideAttrs (previousAttrs: {
  version = "10.2.0";

  src = fetchFromGitHub {
    owner = "tenstorrent";
    repo = "sfpi-gcc";
    rev = "9b05394f53925372db0330098916a94fde47bda5";
    sha256 = "sha256-L29yCD52Wv/cxbgeOPerpZYtQ8HiVYJbmNkMpCmMev8=";
  };


  nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
    # fix `cc1plus: fatal error: gengtype-lex.c: No such file or directory`
    # Found in https://gibsonic.org/tools/2019/08/08/gcc_building.html
    flex
  ];

  buildInputs = (lib.remove (lib.elemAt previousAttrs.buildInputs 4) previousAttrs.buildInputs) ++ [
    bintools-wrapped
  ];

  configureFlags =
    let
      flagsToRemove = [
        "--with-as"
        "--with-ld"
      ];
    in
    (lib.filter (
      flag: !(lib.any (unwanted: lib.hasPrefix unwanted flag) flagsToRemove)
    ) previousAttrs.configureFlags)
    ++ [
      "--with-as=${bintools-wrapped}/bin/${gcc10.cc.stdenv.targetPlatform.config}-as"
      "--with-ld=${bintools-wrapped}/bin/${gcc10.cc.stdenv.targetPlatform.config}-ld"
      "--disable-threads"
    ];

  passthru = previousAttrs.passthru // {
    inherit bintools-wrapped;
  };
  # TODO: why not automatically patched in https://github.com/NixOS/nixpkgs/blob/49be301a59b894ffe96a964a525cfa6bcdab5cf6/pkgs/stdenv/generic/setup.sh#L1400
  postPatch = ''
    substituteInPlace libcc1/configure \
      --replace-fail "/usr/bin/file" "file"
  '';

})
