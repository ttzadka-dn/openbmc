# Q2C Hardware Customization Guide

This guide helps you customize the Q2C machine configuration and device tree for your actual hardware.

## Files Created

```
meta-drivenets/
├── conf/machine/drivenets-q2c.conf                     # Machine config
└── recipes-kernel/linux/linux-aspeed/
    └── aspeed-bmc-drivenets-q2c.dts                   # Device tree
```

## Quick Start

### Build for Q2C

```bash
cd /home/ttzadka/ws_wsl/openbmc_fork

# Set up for Q2C
. setup drivenets-q2c

# Build
bitbake obmc-phosphor-image
```

## Customization Checklist

### 1. Machine Configuration (`conf/machine/drivenets-q2c.conf`)

**Review and update:**

- [ ] **FLASH_SIZE**: Set to match Q2C flash chip size
  - 32MB: `FLASH_SIZE = "32768"`
  - 64MB: `FLASH_SIZE = "65536"`
  - 128MB: `FLASH_SIZE = "131072"`

- [ ] **SERIAL_CONSOLES**: Verify UART used for BMC console
  - Default: `"115200;ttyS4"`
  - Other options: `ttyS0`, `ttyS1`, etc.

- [ ] **PREFERRED_PROVIDER**: Add any Q2C-specific providers
  ```bitbake
  PREFERRED_PROVIDER_virtual/phosphor-led-manager-config-native = "q2c-led-config-native"
  ```

- [ ] **MACHINE_FEATURES**: Add Q2C-specific features if needed

### 2. Device Tree (`recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-q2c.dts`)

#### LEDs

**Update LED GPIOs to match Q2C hardware:**

1. Get GPIO information from Q2C schematic
2. Update the `leds` section:

```dts
leds {
    compatible = "gpio-leds";
    
    led-identify {
        label = "identify";
        gpios = <&gpio0 ASPEED_GPIO(A, 0) GPIO_ACTIVE_LOW>;  // Update GPIO
        default-state = "off";
    };
    
    // Add all Q2C LEDs...
};
```

**GPIO Naming Convention:**
- `ASPEED_GPIO(A, 0)` = GPIO A0
- `ASPEED_GPIO(B, 5)` = GPIO B5
- `ASPEED_GPIO(H, 7)` = GPIO H7

**Active Level:**
- `GPIO_ACTIVE_LOW` - LED on when GPIO is low
- `GPIO_ACTIVE_HIGH` - LED on when GPIO is high

#### I2C Devices

**Add all I2C sensors and devices on Q2C:**

1. **Temperature Sensors:**
```dts
&i2c0 {
    inlet_temp: tmp75@48 {
        compatible = "ti,tmp75";
        reg = <0x48>;
        label = "inlet_temp";
    };
};
```

Common temperature sensor compatibles:
- `"ti,tmp75"` - TMP75/TMP175
- `"ti,tmp421"` - TMP421/TMP422/TMP423
- `"national,lm75"` - LM75
- `"jedec,jc-42.4-temp"` - JEDEC JC-42.4 (DIMM)

2. **FRU EEPROMs:**
```dts
&i2c1 {
    board_fru: eeprom@50 {
        compatible = "atmel,24c256";
        reg = <0x50>;
        label = "board_fru";
        pagesize = <64>;
    };
};
```

Common EEPROM compatibles:
- `"atmel,24c256"` - 256Kbit (32KB)
- `"atmel,24c128"` - 128Kbit (16KB)
- `"atmel,24c64"` - 64Kbit (8KB)

3. **Power Supplies (PMBus):**
```dts
&i2c6 {
    psu0: power-supply@58 {
        compatible = "pmbus";
        reg = <0x58>;
        label = "psu0";
    };
};
```

4. **Voltage Regulators:**
```dts
&i2c4 {
    vr_cpu: regulator@60 {
        compatible = "pmbus";
        reg = <0x60>;
        label = "vr_cpu";
    };
};
```

5. **ADM1278 Hot Swap Controller:**
```dts
&i2c5 {
    hotswap: adm1278@11 {
        compatible = "adi,adm1278";
        reg = <0x11>;
        shunt-resistor-micro-ohms = <500>;
    };
};
```

**How to find I2C addresses:**
- Check Q2C schematic
- Boot EVB and run `i2cdetect -y 0` (for bus 0) on BMC
- Use `i2cdetect -y <bus>` for each I2C bus

#### GPIO Names

**Name all GPIOs that Q2C uses:**

```dts
&gpio0 {
    gpio-line-names =
    // A0-A7
    "led-identify", "led-status-green", "led-status-amber", "led-fault",
    "power-button", "reset-button", "bmc-ready", "host-power-good",
    // B0-B7
    "fan-present-1", "fan-present-2", "fan-present-3", "fan-present-4",
    "", "", "", "",
    // Continue for all banks...
    ;
};
```

**Benefits of naming:**
- GPIOs show up with names in `/sys/class/gpio/`
- Easier debugging
- Better documentation

#### Fans

**Configure fans based on Q2C hardware:**

1. Count how many fans Q2C has
2. Determine which PWM and Tach channels are used
3. Update fan configuration:

```dts
&pwm_tacho {
    fan@0 {
        reg = <0x00>;
        aspeed,fan-tach-ch = /bits/ 8 <0x00>;  // Tach channel 0
        cooling-min-state = <0>;
        cooling-max-state = <3>;
        #cooling-cells = <2>;
        cooling-levels = <125 151 177 203 229 255>;  // PWM duty cycles
        aspeed,pulse-pr = <2>;  // Pulses per revolution (check fan spec)
        label = "fan0";
    };
    
    // Add fan@1, fan@2, etc. for each fan
};
```

**PWM/Tach Mapping:**
- AST2600 has 8 PWM outputs (0-7)
- AST2600 has 16 Tach inputs (0-15)
- Check Q2C schematic for which channels connect to which fans

#### Network

**Configure network based on Q2C design:**

**Option 1: Direct PHY (like EVB):**
```dts
// No changes needed - inherited from EVB
```

**Option 2: NC-SI (Network Controller Sideband Interface):**
```dts
&mac0 {
    use-ncsi;
};
```

**Option 3: Disable unused MAC:**
```dts
&mac1 {
    status = "disabled";
};
```

#### Flash

**Update if Q2C has different flash:**

```dts
&fmc {
    flash@0 {
        spi-max-frequency = <100000000>;  // 100MHz if supported
        // Or change flash chip compatible if different
        compatible = "jedec,spi-nor";
    };
};
```

**Add host flash if present:**
```dts
&spi1 {
    flash@0 {
        status = "okay";
        compatible = "jedec,spi-nor";
        reg = <0>;
        label = "host-firmware";
        spi-max-frequency = <100000000>;
    };
};
```

#### Serial/UART

**Enable additional UARTs if Q2C uses them:**

```dts
// Host console on UART1
&uart1 {
    status = "okay";
};

// Debug console on UART2
&uart2 {
    status = "okay";
};
```

#### IPMI KCS

**Update KCS addresses if different from EVB:**

```dts
&kcs1 {
    status = "okay";
    aspeed,lpc-io-reg = <0xca0>;  // Update if different
};

&kcs2 {
    status = "okay";
    aspeed,lpc-io-reg = <0xca8>;
};

&kcs3 {
    status = "okay";
    aspeed,lpc-io-reg = <0xca2>;
};
```

Check host BIOS/UEFI settings or Q2C specification for KCS addresses.

## Testing Your Changes

### 1. Verify Device Tree Compiles

```bash
# Try to compile just the kernel
bitbake -c compile linux-aspeed

# Check for DTS compilation errors
```

### 2. Check Generated DTB

```bash
# After build, check the DTB exists
ls tmp/work/drivenets_q2c-openbmc-linux-gnueabi/linux-aspeed/*/deploy-linux-aspeed/aspeed-bmc-drivenets-q2c.dtb
```

### 3. Test on Hardware

After flashing to Q2C:

```bash
# View active device tree
dtc -I fs /sys/firmware/devicetree/base > /tmp/current-dt.dts

# Check I2C devices detected
for i in {0..15}; do echo "=== I2C Bus $i ==="; i2cdetect -y $i 2>/dev/null; done

# Check GPIO names
cat /sys/kernel/debug/gpio

# Check fans
ls /sys/class/hwmon/hwmon*/fan*

# Check LEDs
ls /sys/class/leds/
```

## Common Device Tree Compatibles

### Temperature Sensors
- `ti,tmp75` - TMP75, TMP175, TMP275
- `ti,tmp421` - TMP421/422/423
- `national,lm75` - LM75, LM75A
- `jedec,jc-42.4-temp` - JC-42.4 (DIMM sensors)

### EEPROMs
- `atmel,24c256` - 32KB EEPROM
- `atmel,24c128` - 16KB EEPROM
- `atmel,24c64` - 8KB EEPROM

### Power/PMBus
- `pmbus` - Generic PMBus device
- `adi,adm1278` - ADM1278 hot swap controller
- `ti,ucd90160` - UCD90160 sequencer/monitor
- `infineon,ir38064` - IR38064 voltage regulator

### GPIO Expanders
- `nxp,pca9555` - PCA9555 16-bit I/O expander
- `nxp,pca9535` - PCA9535 16-bit I/O expander

## Getting Hardware Information

### From Schematic
- GPIO assignments
- I2C device addresses
- PWM/Tach connections
- LED connections
- UART routing

### From Running BMC (EVB)
```bash
# Scan all I2C buses
for i in {0..15}; do i2cdetect -y $i; done

# List all GPIOs
cat /sys/kernel/debug/gpio

# Check existing fans
ls -la /sys/class/hwmon/
```

### From Q2C Specification
- Flash size
- Number of fans
- Power supply models
- Network configuration (direct PHY vs NC-SI)
- IPMI KCS addresses

## Next Steps

1. **Gather Q2C hardware info** - schematic, spec sheet
2. **Update machine config** - flash size, console
3. **Update device tree** - LEDs, I2C devices, GPIOs, fans
4. **Build and test** - compile and verify
5. **Flash to Q2C hardware** - test on actual board
6. **Iterate** - fix any issues found during testing

## Need Help?

- Check Q2C schematic for GPIO and I2C assignments
- Reference EVB device tree for examples
- Look at other OpenBMC platforms in meta-facebook, meta-ibm for examples
- Test incrementally - add devices one at a time

Good luck with your Q2C bring-up! 🚀
