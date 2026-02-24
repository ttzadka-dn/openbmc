# bmcweb bbappend for DriveNets platforms
#
# bmcweb serves the Redfish API and web UI.
# PACKAGECONFIG controls optional features compiled in at build time.
#
# Common optional features:
#   ibm-management-console  — IBM-specific management console
#   insecure-disable-csrf   — disable CSRF checks (dev only, NOT for production)
#   insecure-disable-ssl    — disable HTTPS (dev only, NOT for production)
#   insecure-push-style-logging — verbose logging (dev only)
#   redfish-bmc-journal     — expose BMC journal via Redfish
#   redfish-host-logger     — expose host serial console log
#   redfish-new-powersubsystem-powercontrol — new Redfish power API
#   experimental-redfish-multi-computer-system — multi-host support

# Features enabled for all DriveNets machines
PACKAGECONFIG:append = " \
    redfish-bmc-journal \
    redfish-host-logger \
"

# During development/bringup: enable insecure logging for easier debugging.
# Remove before production release.
PACKAGECONFIG:append = " insecure-push-style-logging"

# OEM-specific Redfish manufacturer / model strings
# These map to the Redfish /redfish/v1/Managers/bmc resource.
# Set via compile-time defines; override when upstreaming to bmcweb.
# EXTRA_OECMAKE:append = " -DBMCWEB_VENDOR_NAME=DriveNets"
