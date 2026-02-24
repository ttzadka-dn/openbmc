# phosphor-network bbappend for DriveNets platforms
#
# Sets the BMC hostname and configures the management network interface.
# The values here are safe defaults; override in local.conf or distro conf
# for production deployments.

# BMC hostname — visible via Redfish /redfish/v1/Managers/bmc
HOSTNAME:drivenets-ast2600 = "drivenets-ast2600-bmc"
HOSTNAME:drivenets-q2c     = "drivenets-q2c-bmc"

# Default NTP servers; add site-specific servers as needed.
NTP_SERVERS ?= "pool.ntp.org"

# Management interfaces on Q2C (confirmed from block diagram 09172025):
#
#   eth0 / PCIe NIC — Intel I210 attached to DC-SCM via PCIe Gen2 x1.
#                     This is the primary dedicated OOB management port (MDI).
#                     No special PACKAGECONFIG needed; kernel I210 driver handles it.
#
#   mac1 (NCSI)     — AMD x86 COMe NIC → DC-SCM mac1 (in-band management path).
#                     Enable the 'ncsi' PACKAGECONFIG and set use-ncsi in DTS
#                     once the DC-SCM schematic confirms which MAC is wired for NCSI.
#
# Uncomment when NCSI MAC assignment is confirmed from DC-SCM schematic:
# PACKAGECONFIG:append:drivenets-q2c = " ncsi"
