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
  # NOTE: use the correct `callPackage` for everything so the dependency offsets will be correct.
  # If simply getting `gmp` from the arguments at the top
  # `error: GMP is missing or unusable`
  #binutils-unwrapped = buildPackages.callPackage (

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
