{
  flex,
  gcc10,
  fetchurl,
}:
gcc10.cc.overrideAttrs (previousAttrs: {
  version = "10.2.0";
  src = (
    fetchurl {
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
