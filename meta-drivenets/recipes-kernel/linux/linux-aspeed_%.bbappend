FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Add ALL DriveNets custom device tree sources
# BitBake will only compile the ones specified in machine configs
SRC_URI += "file://aspeed-bmc-drivenets-ast2600.dts"
SRC_URI += "file://aspeed-bmc-drivenets-q2c.dts"

# Add more DTS files as you create new hardware variants:
# SRC_URI += "file://aspeed-bmc-drivenets-hw2.dts"
# SRC_URI += "file://aspeed-bmc-drivenets-hw3.dts"

# Each machine specifies which DTB to use in its machine config
# (see conf/machine/*.conf files)

do_configure:append() {
    # Copy DriveNets custom DTS files into the kernel source tree.
    # SRC_URI places them in ${WORKDIR}; the kernel build requires them
    # to live under ${S}/arch/arm/boot/dts/aspeed/.
    install -m 0644 ${WORKDIR}/aspeed-bmc-drivenets-q2c.dts \
        ${S}/arch/arm/boot/dts/aspeed/
    install -m 0644 ${WORKDIR}/aspeed-bmc-drivenets-ast2600.dts \
        ${S}/arch/arm/boot/dts/aspeed/

    # Register DriveNets DTBs in the aspeed Makefile if not already present.
    # The entry must appear in the dtb-$(CONFIG_ARCH_ASPEED) list or the
    # kernel will refuse to build the requested .dtb target.
    if ! grep -q "aspeed-bmc-drivenets-q2c.dtb" ${S}/arch/arm/boot/dts/aspeed/Makefile; then
        sed -i 's/aspeed-bmc-vegman-sx20\.dtb$/aspeed-bmc-vegman-sx20.dtb \\\n\taspeed-bmc-drivenets-q2c.dtb \\\n\taspeed-bmc-drivenets-ast2600.dtb/' \
            ${S}/arch/arm/boot/dts/aspeed/Makefile
    fi
}
