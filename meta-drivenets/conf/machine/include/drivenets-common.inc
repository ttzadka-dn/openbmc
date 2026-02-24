# DriveNets common machine settings for all AST2600/AST2620-based platforms
# Include this from every drivenets-*.conf machine file

# OpenBMC BSP common defaults (DISTRO_FEATURES, packagegroup defaults, etc.)
require conf/machine/include/obmc-bsp-common.inc

# U-Boot: shared defconfig; machine confs may override UBOOT_DEVICETREE
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
UBOOT_DEVICETREE ?= "ast2600-evb"
SPL_BINARY = "spl/u-boot-spl.bin"

# Hardware root-of-trust: disabled by default.
# To enable: set SOCSEC_SIGN_ENABLE = "1" and provide platform OTP config.
SOCSEC_SIGN_ENABLE = "0"

# Serial console — override in machine conf if the board uses a different UART
SERIAL_CONSOLES ?= "115200;ttyS4"

# SPI flash size (KB). 32 MB = 32768, 64 MB = 65536, 128 MB = 131072
# Use hard assignment (=) so this overrides obmc-bsp-common.inc's ?= "32768".
FLASH_SIZE = "65536"

# Flash layout overrides for 64 MB (flash-65536) flash.
#
# The upstream u-boot-aspeed-sdk binary for AST2600 exceeds the default 832 KB
# U-Boot partition (64→896 KB in the upstream flash-65536 defaults).
# Shift env/manifest/kernel forward by 256 KB; ROFS and RWFS are unchanged.
#
#  Upstream (flash-65536)       DriveNets (flash-65536)
#  0 KB     SPL    (64 KB)      0 KB     SPL    (64 KB)
#  64 KB    U-Boot (832 KB)     64 KB    U-Boot (1088 KB)
#  888 KB   Manifest            1144 KB  Manifest
#  896 KB   Env    (128 KB)     1152 KB  Env    (128 KB)
#  1024 KB  Kernel              1280 KB  Kernel
#  10240 KB ROFS   (unchanged)  10240 KB ROFS   (unchanged)
#  43008 KB RWFS   (unchanged)  43008 KB RWFS   (unchanged)
#
# u-boot-aspeed-sdk_%.bbappend also overrides CONFIG_ENV_OFFSET=0x120000
# (1152 KB) to keep U-Boot's env pointer in sync with this layout.
FLASH_MANIFEST_OFFSET:flash-65536 = "1144"
FLASH_UBOOT_ENV_OFFSET:flash-65536 = "1152"
FLASH_KERNEL_OFFSET:flash-65536 = "1280"

# obmc-system-mgmt pulls in a host-management stack that requires a configured
# provider (e.g. phosphor-state-manager). Remove it here so bare-metal bringup
# works without it; re-enable per-machine when the stack is ready.
IMAGE_FEATURES:remove = "obmc-system-mgmt"

# Common machine features for all DriveNets BMC platforms
MACHINE_FEATURES:append = " tpm2"
