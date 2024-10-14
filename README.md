Got stuck on these warnings `/nix/store/n70bcc92l5pzs52vlv13ljcj3abp01ri-riscv32-none-elf-binutils-2.39/bin/riscv32-none-elf-ld: /nix/store/ryn5n2jhnplg97maxyc5sa7nvi7cdb3q-newlib-riscv32-none-elf-4.1.0/riscv32-none-elf/lib/libgloss.a(sys_exit.o): unsupported relocation type 0x3d` in `checks.x86_64-linux.simple`

Decided to use the `sfpi-tt-gcc` repo to build everything `tt-gcc` at once instead of separating them and fitting them in to the nixpkgs framework https://github.com/Artturin/tt-flake
