# Entity-Manager Probing Guide

## Why Was Your Configuration Rejected?

Entity-manager rejected your configuration because it contained **I2C devices without proper probe statements**. When entity-manager can't verify if hardware exists, it rejects the ENTIRE configuration file for safety.

## Probe Requirements by Device Type

### ✅ NO Probe Needed (Always Present)

These items are always present and don't need probing:

```json
{
    "Name": "BMC",
    "Type": "Bmc",
    // No Probe needed - BMC is always present
}
```

### ⚠️ Probe Recommended (Static Hardware)

For chassis/boards that are always present but you want to match specific hardware:

```json
{
    "Name": "Chassis",
    "Type": "Chassis",
    "Probe": "xyz.openbmc_project.Inventory.Decorator.Asset",
    // Probe checks if Asset interface exists (basic validation)
}
```

### ❌ Probe REQUIRED (I2C Devices)

Any device on I2C bus MUST have a probe:

```json
{
    "Name": "Temp_Sensor",
    "Type": "TMP75",
    "Address": "0x48",
    "Bus": 0,
    "Probe": "xyz.openbmc_project.FruDevice({'PRODUCT_PRODUCT_NAME': '.*'})",
    // Without this probe, entity-manager rejects the ENTIRE config!
}
```

## Probe Statement Types

### 1. FRU-Based Probing (Most Common)

Checks FRU EEPROM data to identify the board:

```json
"Probe": "xyz.openbmc_project.FruDevice({'BOARD_PRODUCT_NAME': 'DriveNets.*'})"
```

**Matches if:** Board FRU contains "DriveNets" in product name

**Examples:**
```json
// Match any board
"Probe": "xyz.openbmc_project.FruDevice({'BOARD_PRODUCT_NAME': '.*'})"

// Match specific board model
"Probe": "xyz.openbmc_project.FruDevice({'BOARD_PRODUCT_NAME': 'AST2600-EVB'})"

// Match by manufacturer
"Probe": "xyz.openbmc_project.FruDevice({'BOARD_MANUFACTURER': 'DriveNets'})"

// Multiple conditions (AND)
"Probe": "xyz.openbmc_project.FruDevice({'BOARD_MANUFACTURER': 'DriveNets', 'BOARD_PRODUCT_NAME': 'AST2600.*'})"
```

### 2. Interface-Based Probing

Checks if a D-Bus interface exists:

```json
"Probe": "xyz.openbmc_project.Inventory.Decorator.Asset"
```

**Use for:** Items that always exist and have Asset info

### 3. GPIO-Based Probing

Checks GPIO pin state to detect hardware presence:

```json
"Probe": "GPIO == 1",
"GPIOIndex": 10,
"GPIOPolarity": "High"
```

**Use for:** Hot-pluggable devices (PSUs, fans) with presence detect pins

### 4. I2C Device Probing

Entity-manager automatically probes I2C when you specify Address/Bus:

```json
{
    "Address": "0x48",
    "Bus": 0,
    "Probe": "xyz.openbmc_project.FruDevice({'BOARD_PRODUCT_NAME': '.*'})"
}
```

**What happens:**
1. Entity-manager checks if FRU matches
2. Then tries to communicate with device at I2C address
3. If both succeed, creates the inventory object

## Your Specific Problem

Your original config had this:

```json
{
    "Name": "Inlet_Temp",
    "Type": "TMP75",
    "Address": "0x48",    // ← I2C device
    "Bus": 0,             // ← I2C device  
    // ❌ NO PROBE!
}
```

**Result:** Entity-manager said "I can't verify this hardware exists" and rejected everything, including your BMC with UUID!

## How to Fix It

### Option 1: Minimal Config (Current - Works!)

Only include BMC (no probing needed):

```json
{
    "Exposes": [
        {
            "Name": "DriveNets AST2600 BMC",
            "Type": "Bmc",
            "xyz.openbmc_project.Common.UUID": {...}
        }
    ]
}
```

✅ **This works because BMC doesn't need probing**

### Option 2: Add Sensors When You Have FRU EEPROM

Once you have a FRU EEPROM programmed on your board:

```json
{
    "Exposes": [
        {
            "Name": "BMC",
            "Type": "Bmc",
            ...
        },
        {
            "Name": "Inlet_Temp",
            "Type": "TMP75",
            "Address": "0x48",
            "Bus": 0,
            "Probe": "xyz.openbmc_project.FruDevice({'BOARD_PRODUCT_NAME': '.*'})",
            ...
        }
    ]
}
```

### Option 3: Use Wildcard Probe

Match any board (less safe):

```json
"Probe": "xyz.openbmc_project.FruDevice({'PRODUCT_PRODUCT_NAME': '.*'})"
```

## Debugging Probes

### Check if FRU exists:
```bash
busctl tree xyz.openbmc_project.FruDevice
```

### Check FRU data:
```bash
busctl call xyz.openbmc_project.FruDevice \
    /xyz/openbmc_project/FruDevice/Board_0_50 \
    org.freedesktop.DBus.Properties GetAll s xyz.openbmc_project.FruDevice
```

### Check I2C device presence:
```bash
i2cdetect -y 0  # Check bus 0
i2cdetect -y 4  # Check bus 4
```

### Monitor entity-manager:
```bash
journalctl -u xyz.openbmc_project.EntityManager -f
```

## Next Steps

1. **Current state:** Your minimal config (BMC only) should work and fix the UUID error
2. **To add sensors:** First verify hardware exists with `i2cdetect`
3. **To add more inventory:** Add proper probe statements as shown above

## Real-World Example

Look at other platforms in `/usr/share/entity-manager/configurations/`:
```bash
cat /usr/share/entity-manager/configurations/asrock_e3c246d4i.json
```

These show working probe statements you can learn from.
