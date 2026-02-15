FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Add ALL DriveNets custom device tree sources
# BitBake will only compile the ones specified in machine configs
SRC_URI += "file://aspeed-bmc-drivenets-ast2600.dts"
SRC_URI += "file://aspeed-bmc-drivenets-q2c.dts"

# Add more DTS files as you create new hardware variants:
# SRC_URI += "file://aspeed-bmc-drivenets-hw2.dts"
# SRC_URI += "file://aspeed-bmc-drivenets-hw3.dts"

# Each machine specifies which DTB to use in its machine config
# (see conf/machine/*.conf files)
