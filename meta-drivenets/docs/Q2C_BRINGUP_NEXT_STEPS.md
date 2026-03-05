# Q2C Hardware Bringup — Next Steps

**Date:** 2026-03-04

---

## Current Status — What's Already Done

The `drivenets-q2c` machine target is scaffolded and compiles:

- Machine config (`drivenets-q2c.conf`) — complete
- DTS (`aspeed-bmc-drivenets-q2c.dts`) — I2C buses confirmed (`i2c5`, `i2c10`, `i2c11`, `i2c15`, `i2c16`), sensors, PSU mux, fan mux, SGPIOM1, ADC, GPIO line names partially filled in
- Entity manager, fan PID, LED YAML, GPIO monitor configs — all present

---

## 1. Fix Two Known Bugs Before First Boot

### A) GPIO monitor config is wrong for Q2C

`recipes-phosphor/gpio/phosphor-gpio-monitor/drivenets-q2c/phosphor-gpio-monitor.json`
references `"power-button"` and `"reset-button"` as direct GPIO line names — but on Q2C
those signals are routed through the SCM PLD (`GPIOO`/`GPIOP` bank), not connected
directly to the AST2620. Those line names do not exist in the Q2C DTS and
`phosphor-gpio-monitor` will fail at startup.

**Fix:** Clear the file to an empty JSON array `[]` until the PLD driver is ready,
or remap to the actual `pld-bmc-gpioq*` line names once schematic pages [27,28,31]
confirm which PLD bits carry the power/reset button signals.

### B) Entity manager `SCM_FRU` has wrong bus number

In `recipes-phosphor/configuration/entity-manager/drivenets-q2c.json`, the `SCM_FRU`
entry has `"Bus": 0` — but per the DTS the SCM FRU EEPROM is on `i2c15` (bus 15).
Linux will number it as bus 15 and the FRU will never be found.

**Fix:** Change `"Bus": 0` → `"Bus": 15`.

---

## 2. Migrate DTS off the EVB Include (Before Production)

Both the Q2C and EVB DTS still `#include "aspeed-ast2600-evb.dts"`.
The DTS itself flags this in a TODO comment:

> Replace this EVB include with the SoC dtsi (`#include "aspeed-g6.dtsi"`) and
> explicitly enable only the peripherals Q2C needs (fmc, spi, uart, mac, i2c, etc.).
> Keeping EVB for now to inherit working flash/uart/mac defaults while the I2C
> topology is being validated.

Safe to defer until I2C/sensor bringup is validated, but **must happen before
production** — the EVB include pulls in EVB-specific flash, MAC, and UART configs
that may conflict with real Q2C hardware.

---

## 3. Resolve Top DTS TBDs (Hardware-Dependent)

The DTS has 25 numbered TBDs at the bottom. Grouped by what is needed to resolve them:

| Priority | Item | Action |
|---|---|---|
| **Boot** | Console UART (ttyS0 vs ttyS4) | Check U-Boot boot log on first power-on |
| **Boot** | LPC/KCS enable | Uncomment `&lpc_ctrl` + `&kcs3` once KCS port confirmed (standard IPMI KCS3 = `0xCA2`/`0xCA3`) |
| **Boot** | DRAM size / SPI flash size | Check `dmesg`; AST2620 default is 512 MB DRAM, 32 MB flash |
| **Sensors** | TEMP1/TEMP2 actual part numbers on i2c15 | Check DC-SCM BOM — TMP75 is an assumption |
| **Sensors** | RTC part number on i2c15 (addr 0x32) | BOM lookup |
| **Sensors** | PMIC part number on i2c15 (addr 0x14) | BOM lookup |
| **Sensors** | Fan tach readback D-Bus path | Define once PLD exposes tach over i2c or SGPIO |
| **Network** | NCSI MAC selection (mac0 vs mac1) | Check block diagram; uncomment `&mac1 { use-ncsi; };` once confirmed |
| **GPIO** | GPIOO5–O7 signal names | Fill in from schematic page 28 |
| **GPIO** | `irq-bmc-smi-n`, `fm-bmc-ready-n` ball assignments | Locate in schematic |
| **GPIO** | `i210-rst-l` ball assignment | Intel I210 NIC reset output — find in schematic |
| **GPIO** | `rpm-rstind-n`, `spi-hpm-scm-irq0-n` bank/bit | Schematic pages [12,26,34] |
| **GPIO** | `irq-nmi-event-n` ball TBD | PLD U2B schematic page [21] |
| **PFR** | AST1060 I2C address (typically 0x38 or 0x70) | Confirm from PFR firmware docs |
| **PFR** | BMC → AST1060 bus topology (i2c12/7/9/6/HVI3C3) | Confirm from schematic |
| **PFR** | SCM PLD second address 0x6F (via PFR_I2C5) | Confirm from schematic page |
| **SGPIO** | SGPIOM2 bit count and data format | PLD firmware docs needed |
| **SGPIO** | SGPIOM2 pin assignments on AST2620 (GPIOM0-3 assumed) | Verify kernel pinctrl |
| **ADC** | Voltage divider ratios for hwmon calibration | Schematic page 32 |
| **Carrier** | Devices on i2c11 (I2C_3V3_0, gold finger A15/A16) | Block diagram / schematic |

---

## 4. The Critical Blocker — SCM PLD Driver

The Lattice `LCMXO3D-9400HC-5BG256C` PLD at i2c15 @0x40 is the central open item.
It controls:

- **Fan PWM/tach** — `phosphor-pid-control` fan `writePath` entries are currently
  all `"/TBD/fan_control_path_*"` placeholders; closed-loop fan control is impossible
  until the PLD register map is available.
- **Panel LED bit assignments** — the SGPIOM1 `gpio-line-names` in the DTS are
  placeholder bit positions; they need to match the PLD SGPIO chain firmware layout.
- **Power/reset button relay** — platform power button, reset button, and host ACPI
  sleep states arrive at the BMC via GPIOO/GPIOP PLD relay, not direct GPIO.
- **Platform power management** — PSU presence, PWROK, PSON, host power states,
  thermal trip relay all pass through the PLD.
- **UART5 extended channel** — `UART5_TX/RX_BMC_PLD_DATA` for extended BMC↔PLD
  communication (DTS node commented out pending protocol definition).

**What to request from the PLD team:**
1. PLD firmware register map for i2c15 @0x40 (fan PWM setpoint registers, status registers)
2. SGPIOM1 bit assignment table (which bit → which panel LED)
3. GPIOO/GPIOP pin-to-signal mapping (which `pld-bmc-gpioq*` bit = power button, reset, PSU presence, etc.)
4. UART5 protocol / frame format for the BMC↔PLD data channel

---

## 5. First-Boot Checklist (When HW Arrives)

Run the following immediately after the first successful boot to validate the DTS
and catch any bus-numbering mismatches:

```bash
# Verify I2C bus numbering matches DTS expectations
dmesg | grep -E "i2c|I2C"

# List all I2C buses
i2cdetect -l

# Scan local DC-SCM bus (i2c15)
i2cdetect -y 15   # expect: TEMP1@0x48, TEMP2@0x49, FRU@0x50, RTC@0x32, PMIC@0x14, PLD@0x40

# Scan carrier sensor bus (i2c5)
i2cdetect -y 5    # expect: UCD90120A@0x34, TMP435@0x4D, TMP75x@0x48–0x4B, mux@0x71, mux@0x72

# Scan BIOS GPIO bus (i2c10)
i2cdetect -y 10   # expect: PCA9539@0x74

# Check temperature sensors came up via hwmon
cat /sys/class/hwmon/*/temp1_input

# Verify EntityManager probed the Q2C platform
busctl tree xyz.openbmc_project.EntityManager

# Check fan control for TBD writePath errors
journalctl -u phosphor-pid-control

# Check GPIO monitor (should be empty / no errors after bug fix #1)
journalctl -u phosphor-gpio-monitor

# Confirm console UART (look for ttyS0 or ttyS4 in kernel args)
cat /proc/cmdline

# Check SGPIO / LED chain is alive
ls /sys/class/leds/
```

---

## 6. Summary Checklist

- [ ] Fix `phosphor-gpio-monitor.json` — remove invalid `power-button`/`reset-button` entries
- [ ] Fix entity-manager `SCM_FRU` bus number: `"Bus": 0` → `"Bus": 15`
- [ ] Get SCM PLD register map and SGPIOM1 bit assignment table from PLD team
- [ ] Fill in fan `writePath` entries once PLD fan control interface is known
- [ ] Confirm console UART on first boot and enable correct `&uart` DTS node
- [ ] Enable `&lpc_ctrl` + `&kcs3` once KCS port address is confirmed
- [ ] Identify NCSI MAC (mac0 vs mac1) and uncomment in DTS
- [ ] Confirm TEMP1/TEMP2/RTC/PMIC part numbers from DC-SCM BOM and update DTS
- [ ] Fill in remaining GPIO signal names from schematic pages [27,28,31]
- [ ] Migrate DTS from `aspeed-ast2600-evb.dts` include to `aspeed-g6.dtsi` before production
- [ ] Enable SGPIOM2 node once bit count and pin assignments are confirmed
- [ ] Add AST1060 PFR node to i2c16 once I2C address is confirmed
- [ ] Calibrate ADC voltage divider ratios (schematic page 32)
