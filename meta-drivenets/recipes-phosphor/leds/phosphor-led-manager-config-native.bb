SUMMARY = "DriveNets LED Group Management configuration"
DESCRIPTION = "Machine-specific LED group YAML for phosphor-led-manager. \
Provides virtual/phosphor-led-manager-config-native so it takes priority \
over the upstream phosphor-led-manager-config-example-native recipe."

PROVIDES += "virtual/phosphor-led-manager-config-native"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

PV = "1.0"
PR = "r1"

inherit native

# Build once per machine so each machine gets its own led.yaml.
PACKAGE_ARCH = "${MACHINE_ARCH}"

# No remote sources — led.yaml files are maintained in-tree alongside this recipe.
# Avoid SRC_URI file:// entries entirely: native-recipe FILESPATH resolves via
# BPN (phosphor-led-manager-config) not PN, so FILESEXTRAPATHS machine overrides
# are unreliable at parse time.  Use THISDIR-relative paths in do_install instead.
SRC_URI = ""

do_install:drivenets-ast2600() {
    install -d ${D}${datadir}/phosphor-led-manager
    install -m 0644 \
        ${THISDIR}/phosphor-led-manager-config-native/drivenets-ast2600/led.yaml \
        ${D}${datadir}/phosphor-led-manager/led.yaml
}

do_install:drivenets-q2c() {
    install -d ${D}${datadir}/phosphor-led-manager
    install -m 0644 \
        ${THISDIR}/phosphor-led-manager-config-native/drivenets-q2c/led.yaml \
        ${D}${datadir}/phosphor-led-manager/led.yaml
}
