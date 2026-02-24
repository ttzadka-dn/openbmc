FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Append machine-specific U-Boot kconfig fragments for u-boot-aspeed-sdk.
# Each fragment overrides only the symbols that differ from the upstream
# defconfig (ast2600_openbmc_spl_defconfig) and the upstream flash-size cfg
# (u-boot_flash_64M.cfg, applied automatically via uboot-flash-65536 override).
#
# Key override: CONFIG_ENV_OFFSET is set to 0x120000 (1152 KB) to match the
# DriveNets flash layout which shifts the env partition forward by 256 KB to
# accommodate the full-size AST2600 U-Boot binary.

SRC_URI:append:drivenets-ast2600 = " file://drivenets-ast2600.cfg"
SRC_URI:append:drivenets-q2c     = " file://drivenets-q2c.cfg"
