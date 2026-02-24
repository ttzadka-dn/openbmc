FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://set-bmc-uuid.sh \
                   file://set-bmc-uuid.service"

inherit obmc-phosphor-systemd

SYSTEMD_SERVICE:${PN}:append = " set-bmc-uuid.service"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/set-bmc-uuid.sh ${D}${bindir}/
}
