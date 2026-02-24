FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The upstream recipe sets FILES:${PN} explicitly to only the binaries, so the
# swampd config directory is not included by default.  Add it here so the
# config.json we install passes the installed-vs-shipped QA check.
# config_datadir is defined in the upstream recipe as "${datadir}/swampd/".
FILES:${PN}:append = " ${config_datadir}"

# Install machine-specific phosphor-pid-control (swampd) JSON config.
# The daemon reads this file at /usr/share/swampd/config.json.

SRC_URI:append:drivenets-ast2600 = " file://config.json"
SRC_URI:append:drivenets-q2c     = " file://config.json"

do_install:append:drivenets-ast2600() {
    install -d ${D}${datadir}/swampd
    install -m 0644 ${WORKDIR}/config.json ${D}${datadir}/swampd/
}

do_install:append:drivenets-q2c() {
    install -d ${D}${datadir}/swampd
    install -m 0644 ${WORKDIR}/config.json ${D}${datadir}/swampd/
}
