# Supporting Multiple Hardware Platforms in meta-drivenets

This guide explains how to add multiple hardware platforms to your meta-drivenets layer using the flat architecture.

## Overview

The flat architecture makes it easy to support multiple hardware variants:
- All machine configs in: `conf/machine/`
- All device trees in: `recipes-kernel/linux/linux-aspeed/`
- Each machine specifies which device tree to use

## Directory Structure for Multiple Machines

```
meta-drivenets/
├── conf/
│   └── machine/
│       ├── drivenets-ast2600.conf          # EVB-based platform
│       ├── drivenets-server1.conf          # Server variant 1
│       ├── drivenets-server2.conf          # Server variant 2
│       └── drivenets-switch1.conf          # Switch variant
│
└── recipes-kernel/linux/
    ├── linux-aspeed_%.bbappend             # Lists all DTS files
    └── linux-aspeed/
        ├── aspeed-bmc-drivenets-ast2600.dts      # For EVB
        ├── aspeed-bmc-drivenets-server1.dts      # For server1
        ├── aspeed-bmc-drivenets-server2.dts      # For server2
        └── aspeed-bmc-drivenets-switch1.dts      # For switch1
```

## Step-by-Step: Adding a New Hardware Platform

### Step 1: Create Machine Configuration

Create `conf/machine/drivenets-<new-hw>.conf`:

```bitbake
# DriveNets <Hardware Name> Machine Configuration
# Description of this hardware variant

# Specify the device tree for THIS hardware
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-drivenets-<new-hw>.dtb"

# U-Boot configuration (may be same or different)
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
UBOOT_DEVICETREE = "ast2600-<board>"
SPL_BINARY = "spl/u-boot-spl.bin"

# Secure boot
SOCSEC_SIGN_ENABLE = "0"

# Include SOC base configuration
require conf/machine/include/ast2600.inc

# Serial console (customize for your hardware)
SERIAL_CONSOLES = "115200;ttyS4"

# Flash size (customize for your hardware)
FLASH_SIZE = "65536"

# Remove obmc-system-mgmt feature for basic setup
IMAGE_FEATURES:remove = "obmc-system-mgmt"

# Hardware-specific customizations
# PREFERRED_PROVIDER_virtual/... = "..."
```

### Step 2: Create Device Tree

Create `recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-<new-hw>.dts`:

```dts
// SPDX-License-Identifier: GPL-2.0+
// Copyright (c) 2024 DriveNets

// Include base EVB and extend
#include "aspeed-ast2600-evb.dts"

/ {
	model = "DriveNets <Hardware Name> BMC";
	compatible = "drivenets,<new-hw>-bmc", "aspeed,ast2600";

	// Add hardware-specific LEDs
	leds {
		compatible = "gpio-leds";
		
		led-status {
			label = "status";
			gpios = <&gpio0 ASPEED_GPIO(A, 0) GPIO_ACTIVE_LOW>;
		};
	};
};

// Add hardware-specific I2C devices
&i2c0 {
	temp_sensor: tmp75@48 {
		compatible = "ti,tmp75";
		reg = <0x48>;
	};
};

// Override network if different
&mac0 {
	use-ncsi;  // Example: use NC-SI instead of direct PHY
};
```

### Step 3: Add DTS to Recipe

Edit `recipes-kernel/linux/linux-aspeed_%.bbappend`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Add ALL DriveNets device trees
SRC_URI += "file://aspeed-bmc-drivenets-ast2600.dts"
SRC_URI += "file://aspeed-bmc-drivenets-<new-hw>.dts"  # Add this line
```

### Step 4: Build for New Hardware

```bash
cd /home/ttzadka/ws_wsl/openbmc_fork

# Set up for new hardware
. setup drivenets-<new-hw>

# Build
bitbake obmc-phosphor-image
```

## Example: Three Different Hardware Platforms

### Machine 1: EVB AST2600 (Already created)

**conf/machine/drivenets-ast2600.conf:**
```bitbake
KERNEL_DEVICETREE = "aspeed/aspeed-ast2600-evb.dtb"
# Uses standard EVB device tree
```

### Machine 2: Server with Custom Sensors

**conf/machine/drivenets-server1.conf:**
```bitbake
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-drivenets-server1.dtb"
SERIAL_CONSOLES = "115200;ttyS4"
FLASH_SIZE = "65536"
require conf/machine/include/ast2600.inc
IMAGE_FEATURES:remove = "obmc-system-mgmt"
```

**recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-server1.dts:**
```dts
#include "aspeed-ast2600-evb.dts"

/ {
	model = "DriveNets Server 1 BMC";
	compatible = "drivenets,server1-bmc", "aspeed,ast2600";
};

// Add server-specific sensors
&i2c0 {
	cpu_temp: tmp421@4c {
		compatible = "ti,tmp421";
		reg = <0x4c>;
	};
};

&i2c4 {
	dimm_temp: jc42@18 {
		compatible = "jedec,jc-42.4-temp";
		reg = <0x18>;
	};
};
```

### Machine 3: Switch with NC-SI

**conf/machine/drivenets-switch1.conf:**
```bitbake
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-drivenets-switch1.dtb"
SERIAL_CONSOLES = "115200;ttyS4"
FLASH_SIZE = "131072"  # 128MB flash
require conf/machine/include/ast2600.inc
IMAGE_FEATURES:remove = "obmc-system-mgmt"
```

**recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-switch1.dts:**
```dts
#include "aspeed-ast2600-evb.dts"

/ {
	model = "DriveNets Switch 1 BMC";
	compatible = "drivenets,switch1-bmc", "aspeed,ast2600";
};

// Use NC-SI for network
&mac0 {
	use-ncsi;
};

// Add switch-specific devices
&i2c6 {
	psu0: power-supply@58 {
		compatible = "pmbus";
		reg = <0x58>;
	};
	
	psu1: power-supply@59 {
		compatible = "pmbus";
		reg = <0x59>;
	};
};
```

## Building Different Machines

```bash
# Build for EVB
. setup drivenets-ast2600
bitbake obmc-phosphor-image

# Build for Server
. setup drivenets-server1
bitbake obmc-phosphor-image

# Build for Switch
. setup drivenets-switch1
bitbake obmc-phosphor-image
```

## Sharing Common Configuration

### Option 1: Include Files

Create common configuration that multiple machines can include:

**conf/machine/include/drivenets-common.inc:**
```bitbake
# Common DriveNets configuration
IMAGE_FEATURES:remove = "obmc-system-mgmt"
SOCSEC_SIGN_ENABLE = "0"

# Common build optimizations
# ... shared settings ...
```

**In machine configs:**
```bitbake
require conf/machine/include/ast2600.inc
require conf/machine/include/drivenets-common.inc  # Add this
```

### Option 2: Common DTS Base

Create a common DTS that multiple hardware variants include:

**recipes-kernel/linux/linux-aspeed/drivenets-common.dtsi:**
```dts
// Common DriveNets device tree definitions
/ {
	aliases {
		serial4 = &uart5;
	};
	
	// Common LEDs pattern
	leds {
		compatible = "gpio-leds";
		// Common LED definitions
	};
};
```

**In specific DTS files:**
```dts
#include "aspeed-ast2600-evb.dts"
#include "drivenets-common.dtsi"  // Add common definitions

/ {
	model = "DriveNets Specific Hardware";
};
```

## Device Tree Selection Summary

| File | What It Does |
|------|--------------|
| `conf/machine/<machine>.conf` | Specifies `KERNEL_DEVICETREE = "..."` |
| `recipes-kernel/linux/linux-aspeed_%.bbappend` | Lists all DTS files in `SRC_URI` |
| `recipes-kernel/linux/linux-aspeed/<name>.dts` | Device tree source for specific hardware |

**Key Point:** BitBake compiles **only** the DTB specified in the active machine's `KERNEL_DEVICETREE` variable, even though all DTS files are listed in `SRC_URI`.

## Listing All Machines

Users can see all available DriveNets machines:

```bash
# List all machines
. setup 2>&1 | grep drivenets

# Output example:
# drivenets-ast2600
# drivenets-server1
# drivenets-switch1
```

## Best Practices

1. **Name consistently**: `drivenets-<descriptive-name>`
2. **Document each machine**: Add comments in machine config
3. **Extend EVB DTS**: Use `#include "aspeed-ast2600-evb.dts"` when possible
4. **Share common code**: Use include files for repeated configuration
5. **Test each machine**: Build and test on actual hardware

## Flat Architecture Benefits

With this approach:
- ✅ All machines visible at a glance in `conf/machine/`
- ✅ Easy to add new hardware (just add .conf and .dts)
- ✅ No nested layers to navigate
- ✅ Clear which device tree goes with which machine
- ✅ Scales easily to dozens of hardware variants

## Example: Complete Layer with 3 Machines

```
meta-drivenets/
├── conf/
│   ├── layer.conf
│   ├── machine/
│   │   ├── drivenets-ast2600.conf
│   │   ├── drivenets-server1.conf
│   │   └── drivenets-switch1.conf
│   └── templates/default/
│       ├── bblayers.conf.sample
│       └── local.conf.sample
│
├── recipes-kernel/linux/
│   ├── linux-aspeed_%.bbappend
│   └── linux-aspeed/
│       ├── aspeed-bmc-drivenets-ast2600.dts
│       ├── aspeed-bmc-drivenets-server1.dts
│       └── aspeed-bmc-drivenets-switch1.dts
│
└── recipes-phosphor/images/
    └── obmc-phosphor-image.bbappend
```

Simple, flat, and scalable! 🚀
