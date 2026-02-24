FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# --- drivenets-ast2600 ---
SRC_URI:append:drivenets-ast2600 = " file://drivenets-ast2600.json"

do_install:append:drivenets-ast2600() {
    install -d ${D}${datadir}/entity-manager/configurations
    install -m 0644 ${WORKDIR}/drivenets-ast2600.json ${D}${datadir}/entity-manager/configurations/
}

# --- drivenets-q2c ---
SRC_URI:append:drivenets-q2c = " file://drivenets-q2c.json"

do_install:append:drivenets-q2c() {
    install -d ${D}${datadir}/entity-manager/configurations
    install -m 0644 ${WORKDIR}/drivenets-q2c.json ${D}${datadir}/entity-manager/configurations/
}
