SUMMARY = "DriveNets OEM IPMI Commands"
DESCRIPTION = "Custom OEM IPMI command handlers for DriveNets platform"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://src/drivenets_oem_cmds.cpp \
           file://meson.build"

S = "${WORKDIR}"

inherit meson pkgconfig

DEPENDS += " \
    phosphor-ipmi-host \
    phosphor-logging \
    sdbusplus \
"

FILES:${PN} += "${libdir}/ipmid-providers"
