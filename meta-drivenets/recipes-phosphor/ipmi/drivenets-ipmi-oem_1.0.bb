SUMMARY = "DriveNets OEM IPMI Commands"
DESCRIPTION = "Custom OEM IPMI command handlers for DriveNets platform"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

# Yocto automatically searches files/${MACHINE}/ before files/ when resolving
# file:// URIs, so sensors.json is resolved to the correct machine variant.
SRC_URI = "file://src/drivenets_oem_cmds.cpp \
           file://meson.build \
           file://sensors.json"

S = "${WORKDIR}"

inherit meson pkgconfig

DEPENDS += " \
    phosphor-ipmi-host \
    phosphor-logging \
    sdbusplus \
    nlohmann-json \
"

do_install:append() {
    install -d ${D}${datadir}/drivenets-ipmi-oem
    install -m 0644 ${WORKDIR}/sensors.json \
        ${D}${datadir}/drivenets-ipmi-oem/sensors.json
}

FILES:${PN} += " \
    ${libdir}/ipmid-providers \
    ${datadir}/drivenets-ipmi-oem \
"
