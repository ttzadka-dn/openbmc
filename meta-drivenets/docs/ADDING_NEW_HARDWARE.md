# Adding New Hardware to meta-drivenets

This guide explains how to add support for new hardware platforms to the meta-drivenets layer using the flat architecture approach.

## Overview

The meta-drivenets layer uses a flat architecture where each hardware platform is defined by a single machine configuration file. This makes it easy to scale and add new hardware variants.

## Step-by-Step Guide

### 1. Identify Hardware Specifications

Before creating the configuration, gather:
- SOC type (e.g., AST2500, AST2600, Nuvoton NPCM7xx)
- Device tree file name
- U-Boot configuration
- Flash size
- Serial console configuration
- Any special hardware features

### 2. Create Machine Configuration

Create a new file: `conf/machine/<your-hardware-name>.conf`

```bash
cd meta-drivenets
touch conf/machine/drivenets-<your-hw>.conf
```

### 3. Configure the Machine File

Use this template:

```bitbake
# DriveNets <Hardware Name> Machine Configuration
# Description of the hardware

# Kernel device tree
KERNEL_DEVICETREE = "aspeed/aspeed-<soc>-<board>.dtb"

# U-Boot configuration
UBOOT_MACHINE = "<soc>_openbmc_spl_defconfig"
UBOOT_DEVICETREE = "<soc>-<board>"
SPL_BINARY = "spl/u-boot-spl.bin"

# Secure boot configuration (optional)
SOCSEC_SIGN_ENABLE = "0"

# Include SOC-specific configuration
require conf/machine/include/<soc>.inc
include conf/machine/include/obmc-bsp-common.inc

# Serial console (adjust ttyS number based on hardware)
SERIAL_CONSOLES = "115200;ttyS4"

# Flash size in KB
FLASH_SIZE = "65536"

# Additional hardware-specific configurations
# Add custom settings here
```

### 4. Examples for Different SOCs

#### For AST2600-based hardware:

```bitbake
KERNEL_DEVICETREE = "aspeed/aspeed-ast2600-myboard.dtb"
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
UBOOT_DEVICETREE = "ast2600-myboard"
SPL_BINARY = "spl/u-boot-spl.bin"
SOCSEC_SIGN_ENABLE = "0"

require conf/machine/include/ast2600.inc
include conf/machine/include/obmc-bsp-common.inc

SERIAL_CONSOLES = "115200;ttyS4"
FLASH_SIZE = "65536"
```

#### For AST2500-based hardware:

```bitbake
KERNEL_DEVICETREE = "aspeed-ast2500-myboard.dtb"
UBOOT_MACHINE = "ast_g5_phy_config"

require conf/machine/include/ast2500.inc
include conf/machine/include/obmc-bsp-common.inc

SERIAL_CONSOLES = "115200;ttyS4"
FLASH_SIZE = "32768"
```

#### For Nuvoton NPCM750:

```bitbake
KERNEL_DEVICETREE = "nuvoton-npcm750-myboard.dtb"
UBOOT_MACHINE = "PolegSVB_config"

require conf/machine/include/npcm7xx.inc
include conf/machine/include/obmc-bsp-common.inc

SERIAL_CONSOLES = "115200;ttyS0"
FLASH_SIZE = "32768"
```

### 5. Device Tree

If you need a custom device tree:

1. Create device tree in the appropriate layer (usually meta-aspeed or meta-nuvoton)
2. Or add it to meta-drivenets in: `recipes-kernel/linux/linux-aspeed/`

Example structure:
```
recipes-kernel/linux/
├── linux-aspeed/
│   └── drivenets-myboard.dts
└── linux-aspeed_%.bbappend
```

In the `.bbappend`:
```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://drivenets-myboard.dts"
```

### 6. Test the Configuration

```bash
# Set up build environment
. setup drivenets-<your-hw>

# Verify configuration
bitbake-layers show-layers
cat conf/local.conf | grep MACHINE

# Test build
bitbake obmc-phosphor-image
```

### 7. Add Hardware-Specific Customizations

Create recipe appends or new recipes in `recipes-phosphor/`:

```
recipes-phosphor/
├── gpio/
│   └── phosphor-gpio-monitor_%.bbappend
├── images/
│   └── obmc-phosphor-image.bbappend
├── network/
│   └── network-config/
└── sensors/
    └── dbus-sensors_%.bbappend
```

### 8. Update Documentation

Update the following files:

1. **README.md**: Add new hardware to supported list
   ```markdown
   ## Currently Supported Hardware
   
   - **drivenets-ast2600**: DriveNets platforms based on ASPEED AST2600 SOC
   - **drivenets-<your-hw>**: Description of your hardware
   ```

2. **MAINTAINERS**: Add maintainer info if needed

### 9. Hardware-Specific Features

#### GPIO Configuration

Create `recipes-phosphor/gpio/phosphor-gpio-monitor/drivenets-<your-hw>.json`:

```json
{
  "gpio_definitions": [
    {
      "name": "power-button",
      "pin": "GPIOA0",
      "direction": "in"
    }
  ]
}
```

#### Sensor Configuration

Create sensor configurations in `recipes-phosphor/sensors/`:

```json
{
  "Name": "temperature_sensor_1",
  "Type": "ADC",
  "Index": 0,
  "ScaleFactor": 1.0,
  "Thresholds": {
    "Warning": 75.0,
    "Critical": 90.0
  }
}
```

#### Network Configuration

Set up network in `recipes-phosphor/network/network-config/`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:drivenets-<your-hw> = " \
    file://00-bmc-eth0.network \
"
```

### 10. Testing Checklist

- [ ] Image builds successfully
- [ ] U-Boot boots on hardware
- [ ] Kernel boots and mounts root filesystem
- [ ] Serial console accessible
- [ ] Network interfaces work
- [ ] Sensors are detected
- [ ] GPIO functions correctly
- [ ] Flash update works
- [ ] BMC web interface accessible

## Common Configurations

### Flash Sizes

| Flash Size | FLASH_SIZE Value |
|------------|------------------|
| 32MB       | 32768            |
| 64MB       | 65536            |
| 128MB      | 131072           |

### Serial Console Ports

| Port  | Configuration        |
|-------|---------------------|
| ttyS0 | 115200;ttyS0        |
| ttyS4 | 115200;ttyS4        |
| Custom| 115200;ttyS<N>      |

### Common SOCs

- **ast2600**: Latest ASPEED G6, ARMv7
- **ast2500**: ASPEED G5, ARMv6
- **ast2400**: ASPEED G4, ARMv5
- **npcm750**: Nuvoton NPCM7xx, Cortex-A9

## Troubleshooting

### Image doesn't build

- Check that SOC include file exists
- Verify layer dependencies in `conf/layer.conf`
- Check for typos in machine name

### U-Boot doesn't find device tree

- Verify UBOOT_DEVICETREE matches file name (without .dtb)
- Check device tree is in u-boot source

### Kernel doesn't boot

- Verify KERNEL_DEVICETREE path is correct
- Check serial console configuration
- Review kernel logs

## Additional Resources

- [OpenBMC Machine Configuration Guide](https://github.com/openbmc/docs/blob/master/architecture/code-update/code-update.md)
- [Yocto Machine Configuration](https://docs.yoctoproject.org/ref-manual/variables.html#term-MACHINE)
- [ASPEED SDK Documentation](https://github.com/AspeedTech-BMC/openbmc)

## Need Help?

Contact the meta-drivenets maintainers (see MAINTAINERS file) or open an issue.
