# DriveNets OpenBMC — Activities Summary

> **Base:** OpenBMC upstream (Scarthgap, subtree-synced through March 2025 plus subsequent upstream bumps).
> **Branch:** `code/meta-drivenets_support`
> **Author:** TalT \<ttzadka@drivenets.com\>

---

## Overview

All work below was done on top of an unmodified OpenBMC upstream tree.
Changes are isolated entirely inside the `meta-drivenets` Yocto layer and a
small set of accompanying documentation files at the repo root.  No upstream
layers were patched.

Two machine targets were developed in parallel:
- **`drivenets-ast2600`** — ASPEED AST2600 evaluation board, used as a testing machine to validate the layer, recipes, and Phosphor service stack before hardware-specific Q2C bringup.
- **`drivenets-q2c`** — production DriveNets Q2C platform (AST2620 DC-SCM module), the primary target.

---

## Commit-by-Commit Activity Log

### 1 — Add base layer of `meta-drivenets`

**Commit:** `49c5678290`

First commit that creates the DriveNets Yocto layer from scratch.

| Area | What was added |
|------|----------------|
| Layer scaffolding | `meta-drivenets/conf/layer.conf`, `CONTRIBUTING.md`, `LICENSE`, `MAINTAINERS`, `OWNERS`, `README.md`, `.gitignore` |
| First machine config | `conf/machine/drivenets-ast2600.conf` — AST2600 EVB target, used as a testing machine for layer and stack validation |
| BitBake templates | `conf/templates/default/` — `bblayers.conf.sample`, `local.conf.sample`, `conf-notes.txt` |
| Image recipe | `recipes-phosphor/images/obmc-phosphor-image.bbappend` — initial image feature set |
| Documentation | `docs/GETTING_STARTED.md`, `docs/LAYER_STRUCTURE.md`, `docs/FIXES_APPLIED.md`, `docs/ADDING_NEW_HARDWARE.md`, `docs/QUICKSTART.md` |
| Repo-level docs | `DELIVERY_WORKFLOW.md`, `SETUP_COMPLETE.md` (build verification guide) |

---

### 2 — Add Q2C skeleton support

**Commit:** `8e74ca822a`

Introduced the second machine target — the production Q2C platform.

| Area | What was added |
|------|----------------|
| Machine config | `conf/machine/drivenets-q2c.conf` — AST2620 (AST2600-family) DC-SCM module, KCS host IPMI interface, Q2C-specific LED provider |
| Common include | `conf/machine/include/drivenets-common.inc` — shared settings for all DriveNets AST2600/AST2620 machines: U-Boot defconfig, SPI flash size (64 MB), custom flash-layout offsets (U-Boot partition enlarged to 1088 KB, env/kernel shifted forward by 256 KB), serial console (`ttyS4 @ 115200`), TPM2 machine feature |
| Linux kernel bbappend | `recipes-kernel/linux/linux-aspeed_%.bbappend` — registers both DriveNets DTS files in the kernel Makefile and copies them into the kernel source tree at `do_configure` time |
| Device trees | `aspeed-bmc-drivenets-ast2600.dts` (testing machine / EVB), `aspeed-bmc-drivenets-q2c.dts` (initial skeleton for Q2C DC-SCM) |
| Documentation | `docs/DEVICE_TREE.md`, `docs/MULTIPLE_MACHINES.md`, `docs/Q2C_CUSTOMIZATION.md` |

**Hardware documented in Q2C DTS at this stage:**
- BMC SoC: ASPEED AST2620 on Alpha Networks DC-SCM module (OCP DC-SCM v2, part `8AESQ2CMB0A1G`)
- Host CPU: AMD x86 COMe module
- Host ↔ BMC: LPC via eSPI-to-LPC bridge (`ESPI_HPMCTRL`)
- UART console: `ttyS4` (UART5_BMC) — no software UART routing; physical MUX push-button
- OOB NIC: Intel I210 via PCIe Gen2 x1

---

### 3 — Expand meta-drivenets: Q2C basic DTS, entity-manager, full stack

**Commit:** `764a996260`

Large expansion commit that adds the full Phosphor service stack for both machines (testing machine and Q2C).

| Area | What was added |
|------|----------------|
| Entity manager | `recipes-phosphor/configuration/entity-manager_%.bbappend` and per-machine JSON configs (`drivenets-ast2600.json`, `drivenets-q2c.json`) — hardware inventory: BMC, Chassis, SCM board, PSU0/PSU1, Fan 0-3, temperature sensors (TMP75 × 4, TMP435), SCM FRU EEPROM |
| IPMI OEM commands | `recipes-phosphor/ipmi/drivenets-ipmi-oem_1.0.bb` — new custom recipe; C++ OEM IPMI handler (`drivenets_oem_cmds.cpp`) compiled as a Phosphor IPMI provider shared library; sensor list read from a per-machine `sensors.json` |
| IPMI FRU | `phosphor-ipmi-fru_%.bbappend` + per-machine `fru-read.json` — maps I2C EEPROM addresses to IPMI FRU fields |
| IPMI host | `phosphor-ipmi-host_%.bbappend` — installs `set-bmc-uuid.sh` + `set-bmc-uuid.service`; generates a persistent per-board UUID from `/etc/machine-id` on first boot and publishes it to D-Bus so `netipmid` can use it for RMCP+ sessions |
| IPMI net | `phosphor-ipmi-net_%.bbappend` — Dropbear SSH key configuration |
| LED manager | `phosphor-led-manager-config-native.bb` + per-machine `led.yaml` — Q2C panel LEDs via SGPIO→SCM PLD: SYSTEM (green/amber), PSU0, PSU1, FAN aggregate, SYNC, and individual Fan0-3 LEDs |
| Fan PID control | `phosphor-pid-control_%.bbappend` + per-machine `config.json` — thermal zones linking TMP75/TMP435 temperature sensors to fan PWM output |
| GPIO monitor | `phosphor-gpio-monitor_%.bbappend` + per-machine JSON — power-button (FALLING → `phosphor-poweroff.target`), reset-button (FALLING → `phosphor-reboot.target`) |
| Network | `phosphor-network_%.bbappend` — per-machine hostnames (`drivenets-ast2600-bmc`, `drivenets-q2c-bmc`), NTP server, documented OOB (Intel I210) and NCSI management paths |
| Software manager | `phosphor-software-manager_%.bbappend` — 2-image BMC firmware slots (active + standby), optional image signing stubs |
| bmcweb | `bmcweb_%.bbappend` — enables `redfish-bmc-journal`, `redfish-host-logger`, and `insecure-push-style-logging` (dev bringup) |
| dbus-sensors | `dbus-sensors_%.bbappend` — per-machine sensor daemon selection: `fansensor`, `hwmontempsensor`, `psusensor` for both machines |
| U-Boot | `u-boot-aspeed-sdk_%.bbappend` + per-machine kconfig fragments (`drivenets-ast2600.cfg`, `drivenets-q2c.cfg`); `u-boot-fw-utils-aspeed-sdk_%.bbappend`; `fw_env_ast2600_nor.config` (env offset `0x120000` = 1152 KB, matching the enlarged flash layout) |

---

### 4 — Fix entity-manager / IPMI error

**Commit:** `696abd2d80`

Bug-fix pass after first integration test on the testing machine (AST2600 EVB).

| File changed | Fix |
|---|---|
| `entity-manager/drivenets-ast2600.json` | Extended inventory JSON (62 lines added) — corrected sensor types and probe conditions |
| `entity-manager/drivenets-q2c.json` | Minor JSON fix |
| `phosphor-ipmi-fru/drivenets-ast2600/fru-read.json` | Corrected FRU field mappings |
| `set-bmc-uuid.sh` | UUID derivation improved — fall back to `/proc/sys/kernel/random/uuid` when `/etc/machine-id` absent; entity-manager conf written atomically |
| `set-bmc-uuid.service` | `Before=` ordering corrected (network, ipmi-host, entity-manager) |

---

### 5 — Add Q2C support: DTS, I2C inventory, GPIO

**Commit:** `7b0853a410`

First real hardware-mapping pass for Q2C, based on schematic and block-diagram review.

| Area | Changes |
|---|---|
| Q2C DTS (`aspeed-bmc-drivenets-q2c.dts`) | Extensive I2C bus mapping confirmed from schematic `8AESQ2SCM0A1G_SCH_20260203`: local DC-SCM bus (`i2c15`) — TEMP1 @0x48, TEMP2 @0x49, FRU EEPROM @0x50, RTC @0x32, PMIC @0x14, SCM PLD @0x40; Gold Finger buses: `i2c5` (UCD90120A, TMP435, TMP75s, PCA9548 fan/PSU/VR muxes), `i2c10` (PCA9539 BIOS GPIO), `i2c11`, `i2c8`, `i2c16`; PFR chip (AST1060) connections; GPIO definitions |
| Entity manager `drivenets-q2c.json` | Aligned sensor addresses and bus numbers to confirmed schematic values |
| Fan PID `drivenets-q2c/config.json` | Updated temperature sensor paths to match entity-manager names |
| `drivenets-q2c/fru-read.json` | Minor field correction |
| `docs/Q2C_I2C_INVENTORY_TEMPLATE.csv` | New: I2C device inventory table (30 lines) |
| `docs/Q2C_GPIO_MAPPING_TEMPLATE.csv` | New: GPIO signal mapping template (19 lines) |

---

### 6 — Edit Q2C machine files

**Commit:** `13683ebf28`

Schematic-accuracy refinement after deeper review.

| File | Change |
|---|---|
| Q2C DTS | Major update (435 → 462 nodes after diff); GPIO bank labels corrected; I2C mux sub-node addresses aligned with schematic page numbers; LPC/KCS interface corrected for the AMD eSPI-to-LPC bridge topology; host UART MUX documented |
| `Q2C_GPIO_MAPPING_TEMPLATE.csv` | Expanded from 19 → 119 lines: full GPIO A–Z bank survey |
| `Q2C_I2C_INVENTORY_TEMPLATE.csv` | Revised with confirmed device list per bus |

---

### 7 — Fix Q2C kernel build

**Commit:** `0c84f0ae59`

Fixed a build failure where the kernel Makefile injection in `linux-aspeed_%.bbappend` was not always finding the target line.

| File | Change |
|---|---|
| `recipes-kernel/linux/linux-aspeed_%.bbappend` | Hardened the `sed` pattern used to register `aspeed-bmc-drivenets-q2c.dtb` and `aspeed-bmc-drivenets-ast2600.dtb` in the kernel DTS Makefile (18 lines revised) |

---

### 8 — Add support for DriveNets manufacturer ID (dev\_id)

**Commit:** `fdff171b68`

Made the BMC identify itself as DriveNets in IPMI `Get Device ID` responses.

| Area | Change |
|---|---|
| `phosphor-ipmi-config.bbappend` | New bbappend — installs a per-machine `dev_id.json` |
| `phosphor-ipmi-config/dev_id.json` | New: sets IPMI manufacturer ID, product ID, firmware revision, and IPMI version fields for DriveNets hardware |
| `docs/Q2C_BRINGUP_NEXT_STEPS.md` | New: 167-line bringup checklist |
| `docs/LAYER_COMPARISON.md` | Expanded: 181 lines added comparing the DriveNets layer against reference layers |

---

### 9 — Add IPMI OEM sensor list + obmc-console + U-Boot fw-utils

**Commit:** `c483270ee7`

Completed IPMI sensor reporting and host console support.

| Area | Change |
|---|---|
| `drivenets_oem_cmds.cpp` | Expanded OEM IPMI handler: added `Get Sensor List` command (OEM netfn) — lazy-loads `sensors.json` into an in-memory map; returns sensor IDs, descriptions, and live D-Bus values; added `Get Manufacturer Info` command returning DriveNets OUI/name string |
| `files/drivenets-q2c/sensors.json` | 5 temperature sensors mapped: `Ambient_Temp_AFO`, `HotSpot_Temp`, `HotSpot_Temp_AFI`, `OP2_Temp`, `CPU_Remote_Temp` with full D-Bus paths |
| `files/meson.build` | Updated for new source files |
| `recipes-phosphor/ipmi/drivenets-ipmi-oem_1.0.bb` | Removed obsolete `phosphor-ipmi-config.bbappend` dependency; cleaned recipe |
| **obmc-console** | New bbappend `obmc-console_%.bbappend`: sets `OBMC_CONSOLE_TTYS = "ttyS4"`, `CONSOLE_CLIENT = "2200"`, enables `concurrent-servers` PACKAGECONFIG, installs `server.ttyS4.conf` (115200 baud, no software UART routing) and `client.2200.conf` (SSH console client on port 2200) |
| **U-Boot fw-utils** | `u-boot-fw-utils-aspeed-sdk_%.bbappend` + `fw_env_ast2600_nor.config` — fw_env config aligning with the 64 MB flash layout (env at 0x120000) |
| `docs/Q2C_GPIO_MAPPING_TEMPLATE.csv` | Final pass: corrected GPIO line names to match DTS |
| `docs/Q2C_I2C_INVENTORY_TEMPLATE.csv` | Final pass: 12 rows revised |
| `docs/LAYER_COMPARISON.md` | Further expanded (290 lines total) |

---

## Bug Fix Applied During Bringup (not a commit)

**obmc-console `${UNPACKDIR}` → `${WORKDIR}`**

The `do_install:append` in `obmc-console_%.bbappend` used `${UNPACKDIR}` to
reference `client.*.conf`.  In this version of OpenEmbedded/Yocto, `UNPACKDIR`
is not defined, so it expanded to an empty string and the install path became
`/client.*.conf` (filesystem root), causing a `do_install` failure.  Fixed by
changing the variable reference to `${WORKDIR}`, where `file://` SRC_URI items
are placed by BitBake.

---

## File Inventory (all files added/owned by meta-drivenets)

```
meta-drivenets/
├── conf/
│   ├── layer.conf
│   ├── machine/
│   │   ├── drivenets-ast2600.conf          # Testing machine (AST2600 EVB)
│   │   ├── drivenets-q2c.conf              # Production Q2C machine
│   │   └── include/drivenets-common.inc    # Shared AST2600/AST2620 settings
│   └── templates/default/                  # BitBake init templates
├── docs/
│   ├── ACTIVITIES_SUMMARY.md               # This file
│   ├── ADDING_NEW_HARDWARE.md
│   ├── DEVICE_TREE.md
│   ├── FIXES_APPLIED.md
│   ├── GETTING_STARTED.md
│   ├── LAYER_COMPARISON.md
│   ├── LAYER_STRUCTURE.md
│   ├── MULTIPLE_MACHINES.md
│   ├── Q2C_BRINGUP_NEXT_STEPS.md
│   ├── Q2C_CUSTOMIZATION.md
│   ├── Q2C_GPIO_MAPPING_TEMPLATE.csv
│   ├── Q2C_I2C_INVENTORY_TEMPLATE.csv
│   └── QUICKSTART.md
├── recipes-bsp/u-boot/
│   ├── u-boot-aspeed-sdk_%.bbappend
│   ├── u-boot-aspeed-sdk/drivenets-ast2600.cfg
│   ├── u-boot-aspeed-sdk/drivenets-q2c.cfg
│   ├── u-boot-aspeed-sdk/fw_env_ast2600_nor.config
│   └── u-boot-fw-utils-aspeed-sdk_%.bbappend
├── recipes-kernel/linux/
│   ├── linux-aspeed_%.bbappend
│   ├── linux-aspeed/aspeed-bmc-drivenets-ast2600.dts
│   └── linux-aspeed/aspeed-bmc-drivenets-q2c.dts
└── recipes-phosphor/
    ├── bmcweb/bmcweb_%.bbappend
    ├── configuration/
    │   ├── entity-manager_%.bbappend
    │   ├── entity-manager/drivenets-ast2600.json
    │   ├── entity-manager/drivenets-q2c.json
    │   └── entity-manager/{PROBING_GUIDE,README}.md
    ├── console/
    │   ├── obmc-console_%.bbappend
    │   ├── obmc-console/client.2200.conf
    │   └── obmc-console/server.ttyS4.conf
    ├── dbus-sensors/dbus-sensors_%.bbappend
    ├── fans/
    │   ├── phosphor-pid-control_%.bbappend
    │   ├── phosphor-pid-control/drivenets-ast2600/config.json
    │   └── phosphor-pid-control/drivenets-q2c/config.json
    ├── gpio/
    │   ├── phosphor-gpio-monitor_%.bbappend
    │   ├── phosphor-gpio-monitor/drivenets-ast2600/phosphor-gpio-monitor.json
    │   └── phosphor-gpio-monitor/drivenets-q2c/phosphor-gpio-monitor.json
    ├── images/obmc-phosphor-image.bbappend
    ├── ipmi/
    │   ├── drivenets-ipmi-oem_1.0.bb          # Custom OEM IPMI recipe
    │   ├── files/src/drivenets_oem_cmds.cpp
    │   ├── files/meson.build
    │   ├── files/drivenets-ast2600/sensors.json
    │   ├── files/drivenets-q2c/sensors.json
    │   ├── phosphor-ipmi-config.bbappend
    │   ├── phosphor-ipmi-config/dev_id.json
    │   ├── phosphor-ipmi-fru_%.bbappend
    │   ├── phosphor-ipmi-fru/drivenets-ast2600/fru-read.json
    │   ├── phosphor-ipmi-fru/drivenets-q2c/fru-read.json
    │   ├── phosphor-ipmi-host_%.bbappend
    │   ├── phosphor-ipmi-host/set-bmc-uuid.service
    │   ├── phosphor-ipmi-host/set-bmc-uuid.sh
    │   ├── phosphor-ipmi-net_%.bbappend
    │   └── phosphor-ipmi-net/dropbear
    ├── leds/
    │   ├── phosphor-led-manager-config-native.bb
    │   ├── phosphor-led-manager-config-native/drivenets-ast2600/led.yaml
    │   └── phosphor-led-manager-config-native/drivenets-q2c/led.yaml
    ├── network/phosphor-network_%.bbappend
    └── software/phosphor-software-manager_%.bbappend
```

---

## Capability Summary

| Capability | Status |
|---|---|
| Two machine targets: `drivenets-ast2600` (testing / EVB), `drivenets-q2c` (production DC-SCM) | ✅ |
| Custom Linux device trees for both machines | ✅ |
| 64 MB SPI flash layout with enlarged U-Boot partition | ✅ |
| U-Boot kconfig fragments per machine | ✅ |
| U-Boot fw-utils env config (fw_printenv / fw_setenv) | ✅ |
| Redfish API via bmcweb (journal, host-logger enabled) | ✅ |
| Hardware inventory via entity-manager (BMC, chassis, board, PSUs, fans, sensors) | ✅ |
| Temperature sensors: TMP75 × 4, TMP435 (Q2C); I2C bus 5 via entity-manager/dbus-sensors | ✅ |
| Fan PID thermal control configuration | ✅ |
| PSU PMBus monitoring (PCA9548#15 mux CH0/CH1) | ✅ |
| GPIO-based power-button and reset-button | ✅ |
| Panel LED management (SYSTEM, PSU0/1, FAN aggregate, SYNC, Fan0-3 individual) | ✅ |
| Host console via obmc-console (ttyS4 @ 115200, SSH port 2200) | ✅ |
| IPMI FRU read (I2C EEPROM) | ✅ |
| IPMI `Get Device ID` returning DriveNets manufacturer ID | ✅ |
| IPMI OEM commands: `Get Sensor List`, `Get Manufacturer Info` | ✅ |
| Per-board BMC UUID generated on first boot, published to D-Bus | ✅ |
| BMC hostnames via phosphor-network | ✅ |
| Dual BMC image slots (active + standby) | ✅ |
| TPM2 machine feature declared | ✅ |
