# U-Boot for dubai as a boot.img for Motorola's ABL. Work in progress: test
# with `fastboot boot` only, never flash it.
#
# ABL loads it like a Linux kernel: gzip'd u-boot-nodtb.bin with the dubai DTB
# appended and in the header v2 dtb section, the same layout as our Linux
# boot.img. U-Boot then runs on the DTB as ABL fixed it up (memory, cmdline).
# Config: qcom_defconfig + board/qualcomm/qcom-phone.config (boot menu, USB
# console gadget, fastboot), cross-compiled from x86_64. dubai.env boots the
# extlinux.conf that userspace writes to /boot (a menu entry per generation).
{ pkgs ? import ../userspace/mobile-nixos/pkgs.nix {
    overlays = [ (import ../userspace/mobile-nixos/overlay/overlay.nix) ];
  }
  # Only the dubai DTB is used from it
, kernel ? (import ../userspace/default.nix { }).config.mobile.boot.stage-1.kernel.package
, panel ? "csot"
}:

assert pkgs.lib.assertMsg (builtins.pathExists ./u-boot/Makefile)
  "u-boot/ is empty: run `git submodule update --init --recursive --depth 1`";

let
  dtb = "${kernel}/dtbs/qcom/sm7325-motorola-dubai-${panel}.dtb";

  u-boot = (pkgs.pkgsCross.aarch64-multiplatform.buildUBoot {
    # upstream main past v2026.10: has qcom UFS vcc/vccq regulator support
    version = "2027.01-pre-8649a54d";
    src = builtins.path {
      name = "u-boot-src";
      path = ./u-boot;
      filter = path: _: baseNameOf path != ".git";
    };
    defconfig = "qcom_defconfig";
    extraConfig = builtins.readFile ./u-boot/board/qualcomm/qcom-phone.config + ''
      CONFIG_ENV_DEFAULT_ENV_TEXT_FILE="board/qualcomm/dubai.env"
      # extlinux APPEND + ABL's ~1 KB command line ($abl_bootargs)
      CONFIG_SYS_CBSIZE=4096
      CONFIG_SYS_PBSIZE=4132
      # dubai.env boots /boot/extlinux/extlinux.conf with sysboot
      CONFIG_CMD_SYSBOOT=y
    '';
    filesToInstall = [ "u-boot-nodtb.bin" "u-boot.bin" ".config" ];
    extraMeta.platforms = [ "aarch64-linux" ];
  }).overrideAttrs (old: {
    # qcom-phone.config's ENV_DEFAULT_ENV_TEXT_FILE is converted with xxd
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.xxd ];
    postPatch = old.postPatch + ''
      cp ${./dubai.env} board/qualcomm/dubai.env
    '';
  });
in
pkgs.runCommand "u-boot-dubai-bootimg" {
  nativeBuildInputs = [ pkgs.mkbootimg pkgs.gzip pkgs.cpio ];
  passthru = { inherit u-boot; };
} ''
  mkdir $out
  gzip -9n < ${u-boot}/u-boot-nodtb.bin > u-boot.gz
  cat u-boot.gz ${dtb} > kernel
  # ABL may refuse an image without a ramdisk; give it an empty one
  : | cpio -o -H newc --quiet | gzip -9n > ramdisk
  # Same header as userspace/devices/motorola-dubai/default.nix (pmOS deviceinfo_flash_*)
  mkbootimg \
    --kernel kernel --ramdisk ramdisk \
    --base 0x00000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 \
    --second_offset 0x00000000 --tags_offset 0x00000100 --pagesize 4096 \
    --header_version 2 --dtb ${dtb} --dtb_offset 0x01f00000 \
    --os_patch_level 2026-06-26 \
    -o $out/u-boot.img
  cp ${u-boot}/.config $out/u-boot.config
''
