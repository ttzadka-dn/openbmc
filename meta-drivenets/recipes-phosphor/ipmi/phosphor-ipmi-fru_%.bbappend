FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# phosphor-ipmi-fru reads FRU data from EEPROM and publishes it on D-Bus.
# The JSON config maps EEPROM sysfs paths to FRU inventory D-Bus paths.
#
# The EEPROM path follows the kernel naming convention:
#   /sys/bus/i2c/devices/<bus>-<addr_hex>/eeprom
# where <addr_hex> is zero-padded to 4 hex digits (e.g. bus 1, addr 0x50 → 1-0050).

SRC_URI:append:drivenets-ast2600 = " file://fru-read.json"
SRC_URI:append:drivenets-q2c     = " file://fru-read.json"

do_install:append:drivenets-ast2600() {
    install -d ${D}${datadir}/phosphor-ipmi-fru
    install -m 0644 ${WORKDIR}/fru-read.json \
        ${D}${datadir}/phosphor-ipmi-fru/
}

do_install:append:drivenets-q2c() {
    install -d ${D}${datadir}/phosphor-ipmi-fru
    install -m 0644 ${WORKDIR}/fru-read.json \
        ${D}${datadir}/phosphor-ipmi-fru/
}
