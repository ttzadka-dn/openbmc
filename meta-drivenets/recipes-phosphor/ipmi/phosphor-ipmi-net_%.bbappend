FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://dropbear"

do_install:append() {
    install -d ${D}${sysconfdir}/pam.d
    install -m 0644 ${WORKDIR}/dropbear ${D}${sysconfdir}/pam.d/dropbear
}
