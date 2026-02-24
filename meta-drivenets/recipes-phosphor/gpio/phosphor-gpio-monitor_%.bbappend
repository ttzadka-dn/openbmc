FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Install machine-specific GPIO monitor configuration.
# Each entry maps a GPIO line name (as defined in the DTS gpio-line-names
# property) to the D-Bus event / action to trigger on edge detection.

SRC_URI:append:drivenets-ast2600 = " file://phosphor-gpio-monitor.json"
SRC_URI:append:drivenets-q2c     = " file://phosphor-gpio-monitor.json"

do_install:append:drivenets-ast2600() {
    install -d ${D}${datadir}/phosphor-gpio-monitor
    install -m 0644 ${WORKDIR}/phosphor-gpio-monitor.json \
        ${D}${datadir}/phosphor-gpio-monitor/
}

do_install:append:drivenets-q2c() {
    install -d ${D}${datadir}/phosphor-gpio-monitor
    install -m 0644 ${WORKDIR}/phosphor-gpio-monitor.json \
        ${D}${datadir}/phosphor-gpio-monitor/
}
