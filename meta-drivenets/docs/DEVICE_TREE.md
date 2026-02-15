# Device Tree Configuration for DriveNets Hardware

## Current Configuration

Your machine currently uses the standard EVB (Evaluation Board) device tree:
```
KERNEL_DEVICETREE = "aspeed/aspeed-ast2600-evb.dtb"
```

**Source location (in Linux kernel):**
- Repository: https://github.com/openbmc/linux
- Branch: dev-6.6
- Path: `arch/arm/boot/dts/aspeed/aspeed-ast2600-evb.dts`

This is **perfect for initial development and testing** with EVB hardware.

## Custom Device Tree for Production Hardware

When you move from EVB to your production DriveNets hardware, you'll need a custom device tree that describes your specific board configuration.

### Files Created

We've created a template custom device tree for you:

```
meta-drivenets/recipes-kernel/linux/
├── linux-aspeed_%.bbappend                          # Recipe append
└── linux-aspeed/
    └── aspeed-bmc-drivenets-ast2600.dts            # Custom DTS template
```

## Why Include/Extend Instead of Starting Fresh?

**You asked a great question!** You absolutely CAN and SHOULD include the EVB DTS and extend it. This is the **recommended approach** in device tree development.

### Include & Extend vs. Start From Scratch

| Approach | Pros | Cons |
|----------|------|------|
| **Include EVB** ✅ | • Get all EVB functionality<br>• Only write differences<br>• Less code<br>• Easier maintenance<br>• Automatic updates from EVB | None! |
| Start from scratch ❌ | None | • Duplicate 300+ lines<br>• Miss important configs<br>• Hard to maintain |

### How Include & Extend Works

```dts
// Your custom DTS file
#include "aspeed-ast2600-evb.dts"   // ← Get EVERYTHING from EVB

/ {
    model = "DriveNets AST2600";    // ← Override only model name
    // All EVB memory, aliases, etc. inherited automatically!
};

// Add your specific devices
&i2c0 {
    // EVB I2C0 config stays
    // You just ADD your devices:
    my_sensor@48 {
        compatible = "ti,tmp75";
        reg = <0x48>;
    };
};

// Override specific settings
&mac0 {
    use-ncsi;  // ← Change EVB's direct PHY to NC-SI
};
```

**Result:** You get the entire EVB configuration PLUS your customizations!

## How to Use the Custom Device Tree

### Step 1: Understand the Approach

The template uses **device tree overlay/extension** technique:

```dts
// Start with EVB as base
#include "aspeed-ast2600-evb.dts"

/ {
    // Override or add to root node
};

// Override or extend specific peripherals
&i2c0 {
    // Add your devices here
};
```

**Benefits:**
- ✅ Get all EVB functionality automatically
- ✅ Only specify what's different
- ✅ Easier to maintain
- ✅ Less code duplication

### Step 2: Customize Only What's Different

Edit `meta-drivenets/recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-ast2600.dts` to add/modify only your specific hardware differences:

#### Common Customizations:

**1. Add Custom LEDs** (EVB LEDs stay, you add more)
```dts
/ {
    leds {
        compatible = "gpio-leds";
        
        led-identify {
            label = "identify";
            gpios = <&gpio0 ASPEED_GPIO(A, 0) GPIO_ACTIVE_LOW>;
        };
        
        led-fault {
            label = "fault";
            gpios = <&gpio0 ASPEED_GPIO(A, 1) GPIO_ACTIVE_HIGH>;
        };
    };
};
```

**2. Add I2C Devices** (extends existing I2C buses)
```dts
&i2c0 {
    // EVB devices remain, add yours:
    inlet_temp: tmp75@48 {
        compatible = "ti,tmp75";
        reg = <0x48>;
        label = "inlet_temp";
    };
};

&i2c4 {
    board_fru: eeprom@50 {
        compatible = "atmel,24c256";
        reg = <0x50>;
        label = "board_fru";
    };
};
```

**3. Add/Modify Fans**
```dts
&pwm_tacho {
    // Extend with your fan configuration
    fan@0 {
        reg = <0x00>;
        aspeed,fan-tach-ch = /bits/ 8 <0x00>;
        cooling-min-state = <0>;
        cooling-max-state = <3>;
        #cooling-cells = <2>;
        cooling-levels = <125 151 177 203 229 255>;
        aspeed,pulse-pr = <2>;
    };
};
```

**4. Name GPIOs You Use**
```dts
&gpio0 {
    gpio-line-names =
    /*A0*/ "power-button",
    /*A1*/ "reset-button",
    /*A2*/ "identify-led",
    /*A3*/ "fault-led",
    // Only name the GPIOs you use, rest can be ""
};
```

**5. Modify Network** (if different from EVB)
```dts
&mac0 {
    use-ncsi;  // Override EVB to use NC-SI
};
```

### Step 2: Update Machine Configuration

Once your custom DTS is ready, update the machine config to use it:

Edit `meta-drivenets/conf/machine/drivenets-ast2600.conf`:

```bitbake
# Change from:
KERNEL_DEVICETREE = "aspeed/aspeed-ast2600-evb.dtb"

# To:
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-drivenets-ast2600.dtb"
```

Also uncomment the line in `linux-aspeed_%.bbappend`:
```bitbake
KERNEL_DEVICETREE:drivenets-ast2600 = "aspeed/aspeed-bmc-drivenets-ast2600.dtb"
```

### Step 4: Rebuild

```bash
# Clean kernel to pick up new device tree
bitbake -c cleansstate linux-aspeed

# Rebuild image
bitbake obmc-phosphor-image
```

## Device Tree Resources

### AST2600 Peripheral Documentation

Key peripherals to configure:
- **UARTs**: Serial consoles (uart1-uart13)
- **MACs**: Network interfaces (mac0-mac3)
- **I2C**: 16 I2C buses for sensors, EEPROMs, etc.
- **PWM/TACH**: Fan control (8 PWM, 16 tachometer channels)
- **ADC**: 16 analog input channels
- **GPIO**: Multiple GPIO banks (A-Z, AA-AC)
- **SPI**: Flash controllers (FMC, SPI1, SPI2)
- **KCS**: IPMI interfaces
- **USB**: Virtual Hub, device mode
- **Video**: VGA capture engine
- **SD/MMC**: SD card controller

### Example Device Trees to Reference

Look at existing OpenBMC device trees for examples:

```bash
# In the kernel source (during build):
# build/drivenets-ast2600/tmp/work-shared/drivenets-ast2600/kernel-source/arch/arm/boot/dts/aspeed/

# Some good examples:
# - aspeed-bmc-facebook-*.dts
# - aspeed-bmc-ibm-*.dts
# - aspeed-bmc-supermicro-*.dts
```

### Pin Multiplexing

The AST2600 has extensive pin multiplexing. Check available pinctrl options in:
```
arch/arm/boot/dts/aspeed/aspeed-g6-pinctrl.dtsi
```

Common pinctrl groups:
- `pinctrl_rgmii1_default` - MAC0 RGMII
- `pinctrl_i2c*_default` - I2C buses
- `pinctrl_pwm*_default` - PWM outputs
- `pinctrl_tach*_default` - Fan tachometer inputs
- `pinctrl_adc*_default` - ADC channels

## Testing Your Device Tree

### Verify DTS Compilation

```bash
# Check that DTS compiled successfully
bitbake -c compile linux-aspeed

# Look for your DTB
ls tmp/work/drivenets_ast2600-openbmc-linux-gnueabi/linux-aspeed/*/arch/arm/boot/dts/aspeed/*drivenets*.dtb
```

### Check Device Tree on Running BMC

Once booted:
```bash
# View the active device tree
dtc -I fs /sys/firmware/devicetree/base

# Check specific node
ls /sys/firmware/devicetree/base/

# Check GPIO names
cat /sys/kernel/debug/gpio
```

## Common Device Tree Patterns

### Adding a New I2C Sensor

```dts
&i2c2 {
    status = "okay";
    
    inlet_temp: tmp421@4c {
        compatible = "ti,tmp421";
        reg = <0x4c>;
        label = "inlet_temp";
    };
};
```

### Adding FRU EEPROM

```dts
&i2c4 {
    status = "okay";
    
    board_eeprom: eeprom@50 {
        compatible = "atmel,24c256";
        reg = <0x50>;
        label = "board_eeprom";
    };
};
```

### Power Supply with PMBus

```dts
&i2c6 {
    status = "okay";
    
    psu0: power-supply@58 {
        compatible = "pmbus";
        reg = <0x58>;
    };
};
```

## When to Use Custom vs EVB Device Tree

| Use Case | Device Tree | Notes |
|----------|-------------|-------|
| Initial development on EVB | `aspeed-ast2600-evb.dts` | Current configuration |
| Testing basic BMC features | `aspeed-ast2600-evb.dts` | Works out of box |
| Production hardware | `aspeed-bmc-drivenets-ast2600.dts` | Custom DTS required |
| Hardware bring-up | Custom DTS | Needed for proper hardware support |
| Final product | Custom DTS | Reflects actual hardware |

## Need Help?

- Check existing device trees in the kernel source
- Reference ASP EED AST2600 datasheet
- Look at similar platforms in OpenBMC
- Test incrementally - add devices one at a time

## Summary

- ✅ Template DTS created at `meta-drivenets/recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-ast2600.dts`
- ✅ Recipe append created to include it
- 📝 Currently using EVB device tree (good for initial testing)
- 🔄 Switch to custom DTS when moving to production hardware
- 🎯 Customize DTS to match your actual hardware configuration
