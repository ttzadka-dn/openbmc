# DriveNets Entity Manager Configuration

## Overview

This entity-manager configuration defines the hardware inventory for the DriveNets AST2600 platform.

## Current Inventory Items

### 1. **BMC** - The management controller itself
   - Provides UUID interface for IPMI
   - Asset information (manufacturer, model, serial number)

### 2. **Chassis** - Physical enclosure
   - Top-level container for all hardware

### 3. **Baseboard** - Main motherboard
   - Contains all other components

### 4. **Power Supplies** (PSU0, PSU1)
   - Configured as hot-swappable power supplies
   - Include operational status monitoring
   - **TODO**: Update with actual PSU hardware addresses if using PMBus/I2C

### 5. **Fans** (Fan0-Fan3)
   - Four fan modules
   - Operational status monitoring
   - **TODO**: Connect to actual PWM/tach channels in device tree

### 6. **Temperature Sensors**
   - **Inlet_Temp** (TMP75 @ I2C0:0x48) - Front panel inlet
   - **CPU_Temp** (TMP75 @ I2C0:0x49) - CPU zone temperature
   - Includes warning and critical thresholds
   - **TODO**: Verify I2C addresses match your actual hardware

### 7. **FRU EEPROM** (Board_FRU)
   - 24C256 EEPROM @ I2C4:0x50
   - Stores board FRU information (VPD)
   - **TODO**: Verify I2C bus and address

## How to Customize

### Adding Real Hardware

1. **Check your device tree** (`aspeed-bmc-drivenets-ast2600.dts`)
   - Uncomment and configure actual I2C devices
   - Add real GPIO definitions for fans/LEDs

2. **Update I2C addresses** in entity-manager JSON
   - Match bus numbers and device addresses from DTS
   - Verify with `i2cdetect` on the BMC

3. **Add more sensors** as needed:
   ```json
   {
       "Name": "Outlet_Temp",
       "Type": "TMP75",
       "Address": "0x4a",
       "Bus": 1,
       "xyz.openbmc_project.Sensor.Threshold.Critical": {
           "CriticalHigh": 75,
           "CriticalLow": 0
       }
   }
   ```

4. **Add PMBus power supplies**:
   ```json
   {
       "Name": "PSU0",
       "Type": "pmbus",
       "Address": "0x58",
       "Bus": 6,
       "Labels": ["vin", "vout", "iin", "iout", "pin", "pout", "temp1", "fan1"]
   }
   ```

### Supported Sensor Types

Common types entity-manager supports:
- **TMP75/TMP175/LM75** - Temperature sensors
- **ADM1275/LTC4287** - Hot swap controllers
- **INA219/INA230** - Current/power monitors
- **EMC1413/EMC1414** - Multi-zone temperature
- **pmbus** - PMBus power supplies
- **MAX31725** - Temperature sensors
- **EEPROM/FRU** - FRU information storage

### Testing Your Configuration

After rebuilding and flashing:

1. Check entity-manager loaded your config:
   ```bash
   systemctl status xyz.openbmc_project.EntityManager
   journalctl -u xyz.openbmc_project.EntityManager
   ```

2. Verify D-Bus inventory objects:
   ```bash
   busctl tree xyz.openbmc_project.Inventory.Manager
   ```

3. Check for your BMC UUID (fixes IPMI error):
   ```bash
   busctl introspect xyz.openbmc_project.Inventory.Manager \
       /xyz/openbmc_project/inventory/system/chassis/motherboard/bmc
   ```

4. View sensor data:
   ```bash
   busctl tree xyz.openbmc_project.HwmonTempSensor
   ```

## Building

```bash
bitbake -c cleansstate entity-manager
bitbake obmc-phosphor-image
```

## References

- [Entity Manager Documentation](https://github.com/openbmc/entity-manager)
- [Sensor Configuration Examples](https://github.com/openbmc/entity-manager/tree/master/configurations)
- [D-Bus Interface Definitions](https://github.com/openbmc/phosphor-dbus-interfaces)
