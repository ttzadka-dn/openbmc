#!/bin/sh
# Generate a per-board BMC UUID from /etc/machine-id and publish it
# to D-Bus via an entity-manager configuration file so that netipmid
# (phosphor-ipmi-net) can read it for RMCP+ session establishment.

UUID_FILE="/var/lib/network/bmc_system_uuid"
EM_CONF_DIR="/etc/entity-manager/configurations"
EM_UUID_CONF="${EM_CONF_DIR}/bmc-uuid.json"

mkdir -p /var/lib/network
mkdir -p "${EM_CONF_DIR}"

# Generate and persist UUID on first boot; reuse on subsequent boots.
if [ ! -f "$UUID_FILE" ]; then
    if [ -f /etc/machine-id ]; then
        UUID=$(sed 's/^\(........\)\(....\)\(....\)\(....\)\(............\)$/\1-\2-\3-\4-\5/' \
               /etc/machine-id)
    else
        UUID=$(cat /proc/sys/kernel/random/uuid)
    fi
    echo "$UUID" > "$UUID_FILE"
else
    UUID=$(cat "$UUID_FILE")
fi

# Write an entity-manager config that exposes the UUID on D-Bus at
# /xyz/openbmc_project/inventory/system/board/BMC_System_UUID with
# interface xyz.openbmc_project.Common.UUID, property UUID.
# netipmid finds this via a subtree search under /xyz/openbmc_project/inventory.
cat > "${EM_UUID_CONF}" << EOF
{
    "Name": "BMC System UUID",
    "Probe": "TRUE",
    "Type": "Board",
    "xyz.openbmc_project.Common.UUID": {
        "UUID": "${UUID}"
    }
}
EOF

exit 0
