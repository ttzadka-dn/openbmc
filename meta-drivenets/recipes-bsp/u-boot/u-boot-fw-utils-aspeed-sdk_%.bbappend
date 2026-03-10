FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-aspeed-sdk:"

SRC_URI:append = " file://fw_env_ast2600_nor.config "

ENV_CONFIG_FILE = "fw_env_ast2600_nor.config"
