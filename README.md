# dubai-mainline-bootloader

Second-stage bootloader for [dubai-mainline](https://github.com/tuxdotrs/dubai-mainline)
(Motorola Edge 30, SM7325): mainline [U-Boot](https://github.com/u-boot/u-boot),
chainloaded by Motorola's stock ABL as the boot.img.

**Status: work in progress, not used for booting yet.** The phone currently
boots ABL → boot.img (kernel + Mobile NixOS stage-1) directly.

Goal: ABL → U-Boot (boot.img) → kernel + initrd from the rootfs, with a
generation menu, so `nixos-rebuild switch` updates the kernel without writing
`boot_a`. Test only with `fastboot boot`; never flash until it boots.

    u-boot/       submodule: u-boot/u-boot, tag v2026.10 (no fork)

Starting points in U-Boot: `qcm6490_defconfig` (sc7280 family),
`board/qualcomm/qcom-phone.config`, `drivers/clk/qcom/clock-sc7280.c`,
`drivers/pinctrl/qcom/pinctrl-sc7280.c`, `drivers/phy/qcom/phy-qcom-qmp-ufs.c`.
