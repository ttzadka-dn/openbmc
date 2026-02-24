# dbus-sensors bbappend for DriveNets platforms
#
# dbus-sensors is a SINGLE package — all sensor daemons are compiled into it.
# PACKAGECONFIG flags select which sensor daemons are compiled in at build time.
#
# Available PACKAGECONFIG options (from dbus-sensors_git.bb):
#   adcsensor         — ADC voltage/current via IIO
#   intelcpusensor    — Intel CPU (PECI) temperature   [Intel-only]
#   exitairtempsensor — Exit-air temperature
#   fansensor         — PWM fan tach via hwmon
#   hwmontempsensor   — Generic hwmon temperature (LM75, TMP75, TMP435, etc.)
#   intrusionsensor   — Chassis intrusion via GPIO
#   ipmbsensor        — Sensors over IPMB
#   mcutempsensor     — MCU temperature
#   nvmesensor        — NVMe drive temperature (SMBus)
#   psusensor         — PMBus power-supply metrics
#   external          — External sensor interface

# drivenets-ast2600 (EVB):
#   hwmontempsensor — LM75/TMP75 on I2C
#   fansensor       — PWM fans via AST2600 pwm-tacho hwmon
#   psusensor       — PSU PMBus
PACKAGECONFIG:drivenets-ast2600 = "fansensor hwmontempsensor psusensor"

# drivenets-q2c (DC-SCM, AST2620):
#   hwmontempsensor — Inlet/Outlet LM75 on DC-SCM + carrier board LM75#0-2 / TMP435
#   fansensor       — fan tach exposed by Fan Expander Board driver via hwmon
#   psusensor       — PSU0/PSU1 PMBus via PCA9548#15 mux
PACKAGECONFIG:drivenets-q2c = "fansensor hwmontempsensor psusensor"
