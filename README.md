# dubai-mainline-bootloader

Second-stage bootloader for [dubai-mainline](https://github.com/tuxdotrs/dubai-mainline)
(Motorola Edge 30, SM7325): mainline [U-Boot](https://github.com/u-boot/u-boot),
chainloaded by Motorola's stock ABL as the boot.img.

**Status: in use.** It is installed on `boot_b`, the active slot: ABL →
U-Boot (this boot.img) → a menu of NixOS generations (volume keys + power, 5 s
to the default) → each generation's kernel, initrd and own DTB from `/boot` on
userdata. `switch-to-configuration` updates the menu and DTBs, so kernel and
DT changes no longer need a boot partition write; `boot_b` is only rewritten
for U-Boot changes. Slot a keeps a plain Linux boot.img as the fallback
(`fastboot --set-active=a`).

Test a new build with `fastboot boot` first, and back up `boot_b` before
writing it. Details: dubai-mainline `docs/boot-chain.md` (U-Boot path).

    u-boot/       submodule: u-boot/u-boot, main at 8649a54d (no fork; past v2026.10
                  for ufs-qcom regulator support, needed on UFS 3.1 phones)
    patches/      applied on top: qcom PMIC GPIO for PM7325 (volume up)
    dubai.env     U-Boot environment: boot menu per NixOS generation
    default.nix   the boot.img; `--arg debug true` for a USB serial shell

Starting points in U-Boot: `qcm6490_defconfig` (sc7280 family),
`board/qualcomm/qcom-phone.config`, `drivers/clk/qcom/clock-sc7280.c`,
`drivers/pinctrl/qcom/pinctrl-sc7280.c`, `drivers/phy/qcom/phy-qcom-qmp-ufs.c`.
