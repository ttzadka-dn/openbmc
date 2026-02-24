# phosphor-software-manager bbappend for DriveNets platforms
#
# phosphor-software-manager (upstream recipe: phosphor-software-manager_git.bb)
# provides the BMC firmware update stack: version tracking, image download,
# UBI/static flash update, and optional image signing.
#
# Key packages produced by the upstream recipe:
#   phosphor-software-manager-version   — version daemon (Redfish FirmwareInventory)
#   phosphor-software-manager-updater   — flash update daemon
#   phosphor-software-manager-download-mgr — download manager

# Allow up to 2 BMC images stored simultaneously (active + standby).
ACTIVE_BMC_MAX_ALLOWED = "2"

# Signing: disabled by default.
# To enable, provide key/cert and uncomment in local.conf or a signing bbappend:
# IMAGE_SIGN_PRIVATE_KEY ?= "${TOPDIR}/keys/drivenets-sign.key"
# IMAGE_SIGN_PUBLIC_KEY  ?= "${TOPDIR}/keys/drivenets-sign.pub"

# Ensure the version daemon is installed so Redfish FirmwareInventory
# reflects the running BMC version correctly.
RDEPENDS:${PN}-updater:append = " phosphor-software-manager-version"
