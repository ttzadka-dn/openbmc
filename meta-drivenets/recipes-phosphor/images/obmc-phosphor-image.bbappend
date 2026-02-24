# DriveNets image customizations
# Packages listed here are added to the image for ALL DriveNets machines.
# Machine-specific additions can be guarded with :append:<machine>.

IMAGE_INSTALL:append = " \
    drivenets-ipmi-oem \
    entity-manager \
    phosphor-led-manager \
    phosphor-pid-control \
    phosphor-gpio-monitor \
    phosphor-ipmi-fru \
    dbus-sensors \
    phosphor-network \
    bmcweb \
    phosphor-software-manager-updater \
    phosphor-software-manager-version \
"

# SSH server: switch from dropbear (pulled in by debug-tweaks) to openssh.
# IMAGE_FEATURES is the correct Yocto mechanism — it handles mutual exclusion
# between dropbear and openssh automatically.  Adding openssh directly to
# IMAGE_INSTALL conflicts with packagegroup-core-ssh-dropbear (from debug-tweaks).
IMAGE_FEATURES:remove = "ssh-server-dropbear"
IMAGE_FEATURES:append = " ssh-server-openssh"

# Set a meaningful hostname for each machine at image-build time.
hostname:pn-base-files:drivenets-ast2600 = "drivenets-ast2600-bmc"
hostname:pn-base-files:drivenets-q2c     = "drivenets-q2c-bmc"
