#!/bin/sh
# Generate and set BMC UUID if not already set

BMC_UUID_FILE="/var/lib/network/bmc_system_uuid"

# Create directory if it doesn't exist
mkdir -p /var/lib/network

# Generate UUID if file doesn't exist
if [ ! -f "$BMC_UUID_FILE" ]; then
    # Generate a UUID based on machine-id or random
    if [ -f /etc/machine-id ]; then
        UUID=$(cat /etc/machine-id | sed 's/^\(........\)\(....\)\(....\)\(....\)\(............\)$/\1-\2-\3-\4-\5/')
    else
        UUID=$(cat /proc/sys/kernel/random/uuid)
    fi
    echo "$UUID" > "$BMC_UUID_FILE"
    echo "Generated BMC UUID: $UUID"
fi

exit 0
