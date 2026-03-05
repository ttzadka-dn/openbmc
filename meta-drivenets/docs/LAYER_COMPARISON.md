# Layer Comparison: meta-alphanetworks (Hawk) vs meta-drivenets

## Overview

| Aspect | meta-alphanetworks (Hawk) | meta-drivenets |
|--------|--------------------------|----------------|
| Hardware | Alpha Networks Hawk / AST2600 | DriveNets AST2600 EVB + Q2C DC-SCM (AST2620) |
| Layout | Parent layer + `meta-hawk` sub-layer | Flat single layer |
| Machines | 1 (`hawk`) | 2 (`drivenets-ast2600`, `drivenets-q2c`) |
| Yocto series | `whinlatter`, `walnascar` (Aspeed SDK fork) | `nanbield`, `scarthgap` (upstream Yocto) |
| LAYERDEPENDS | `aspeed-sdk-layer` | `phosphor-layer`, `aspeed-layer` |
| Documentation | None | 9 docs in `docs/` folder |

---

## Machine Configuration

| Feature | meta-alphanetworks (hawk) | meta-drivenets |
|---------|--------------------------|----------------|
| SoC | AST2600 | AST2600 (EVB), AST2620 (Q2C) |
| U-Boot defconfig | `evb-ast2600_defconfig` | `ast2600_openbmc_spl_defconfig` (SPL) |
| Console UART | ttyS2 | ttyS4 |
| Flash size | 64 MB | 64 MB |
| Boot media | NOR + eMMC | NOR only |
| Secure boot | Enabled (COT, OTP, RSA4096/SHA512) | Disabled (`SOCSEC_SIGN_ENABLE=0`) |
| TPM2 | Yes (via `aspeed-tpm2.inc`) | Yes (in `MACHINE_FEATURES`) |
| Host power control | `x86-power-control` | GPIO-based (power/reset buttons) |
| Host IPMI interface | Standard | KCS (`phosphor-ipmi-kcs`) on Q2C |

---

## Recipes Comparison

| Area | meta-alphanetworks | meta-drivenets |
|------|--------------------|----------------|
| Image | Minimal (secureboot dep only) | Full package list, SSH, hostname |
| Kernel | hawk DTS/cfg + `prepare_dts` task | Machine DTS + `do_configure` to register DTBs |
| U-Boot | hawk DTS/cfg, eMMC env, socsec-sign, otptool | Machine-specific kconfig fragments |
| Entity manager | hawk.json + ast2600-evb.json + blacklist.json | Machine-specific comprehensive JSON |
| Console | ttyS2 + UART routing (uart3↔uart1, io1↔uart4) | Not customized |
| IPMI device ID | `phosphor-ipmi-config.bbappend` → `dev_id.json` | Not set |
| OEM IPMI commands | None | `drivenets-ipmi-oem_1.0.bb` (NetFn 0x30, C++) |
| FRU | Entity-manager based | `phosphor-ipmi-fru_%.bbappend` + `fru-read.json` |
| Fan control | None | `phosphor-pid-control_%.bbappend` + PID config JSON |
| GPIO monitor | None | `phosphor-gpio-monitor_%.bbappend` (power/reset) |
| LED manager | None | `phosphor-led-manager-config-native.bb` + YAML |
| Network | None | `phosphor-network_%.bbappend` (hostname, NTP, NCSI) |
| BMC web | None | `bmcweb_%.bbappend` (Redfish journal, host logger) |
| Software update | None | `phosphor-software-manager_%.bbappend` (dual slots) |
| Secure boot image | `aspeed-image-gen-secureboot.bb` | None |
| dbus-sensors | External sensor flag only | fansensor + hwmontempsensor + psusensor |
| SSH | Default (dropbear) | OpenSSH |

---

## Hardware Feature Coverage

| Component | meta-alphanetworks | meta-drivenets |
|-----------|--------------------|----------------|
| Temperature sensors | TMP75 (AFO/HOTSPOT/AFI) via entity-manager | TMP75, TMP435 via entity-manager |
| Fan control | Not defined | PID loop (swampd) — Q2C writePath is TBD |
| LEDs | Not configured | Full LED groups (system, PSU, fan, SYNC) |
| GPIO (power/reset) | Not configured | Mapped via phosphor-gpio-monitor |
| FRU EEPROM | 24C128 @ 0x50, bus 4 | EEPROM @ 0x50, bus 0 |
| OEM IPMI | None | NetFn 0x30: Get Version, Get Sensor Data, Get Build Timestamp |
| UART routing | Custom (uart3↔uart1, io1↔uart4) | Standard |
| eMMC (dual A/B) | Yes (WIC: 2×24 MB boot, 2×160 MB rofs, 16 MB rwfs) | No |
| Secure boot | Full (RSA4096/SHA512, OTP, COT chain) | Disabled |
| BMC UUID | Not set | `set-bmc-uuid.service` from `/etc/machine-id` |

---

## IPMI: Device ID vs OEM Commands

These are two completely separate IPMI mechanisms that serve different purposes.

### IPMI Device ID (`dev_id.json`) — used in meta-alphanetworks

**Standard IPMI command:** `Get Device ID` — NetFn 0x06, Cmd 0x01

This is a mandatory, read-only identity record defined by the IPMI spec. Every BMC must
respond to it. It tells the remote system *who this BMC is* — the manufacturer, product,
and firmware version.

```json
{
    "id": 3,
    "revision": 2,
    "firmware_revision": { "major": 0, "minor": 1 },
    "addn_dev_support": 11,
    "manuf_id": 31874,
    "prod_id": 0,
    "aux": 2969567232
}
```

| Field | Meaning |
|-------|---------|
| `id` | Device ID (board-specific) |
| `revision` | Device revision |
| `firmware_revision` | BMC firmware version reported to the host |
| `manuf_id` | IANA manufacturer ID (31874 = Alpha Networks) |
| `prod_id` | Product ID within the manufacturer's namespace |
| `aux` | Auxiliary firmware info (e.g. build date encoded) |

**Use case:** A host (BIOS, OS, management software) sends `Get Device ID` to discover the
BMC identity before further communication. Tools like `ipmitool mc info` use this.

---

### OEM IPMI Commands (`drivenets-ipmi-oem`) — used in meta-drivenets

**Custom commands:** NetFn 0x30 (OEM One), Cmd 0x01–0x03

These are *vendor-defined* command handlers compiled as a shared library and loaded by
`ipmid` at runtime. They let the host (or a remote operator) invoke platform-specific
actions that the standard IPMI spec does not cover.

| Command | NetFn | Cmd | Request | Response |
|---------|-------|-----|---------|----------|
| Get Version | 0x30 | 0x01 | 1 byte (param) | major, minor, status |
| Get Sensor Data | 0x30 | 0x02 | 1 byte (sensor ID) | variable byte array |
| Get Build Timestamp | 0x30 | 0x03 | empty | null-terminated string |

Currently the sensor data handler returns dummy bytes (`0xDEADBEEF`) — real D-Bus sensor
reads would be wired here.

**Use case:** A management system, host agent, or operator can call platform-specific
queries — firmware version, live sensor readings, build info — using raw IPMI over
LAN/KCS without needing a separate out-of-band protocol.

---

### Summary: Device ID vs OEM Commands

| | IPMI Device ID | OEM IPMI Commands |
|-|----------------|-------------------|
| **Defined by** | IPMI specification (mandatory) | Vendor (fully custom) |
| **NetFn / Cmd** | 0x06 / 0x01 | 0x30 / 0x01–0x03 (or any OEM NetFn) |
| **Implementation** | Static JSON config file | Compiled C++ shared library |
| **Purpose** | BMC identity (who am I?) | Platform-specific actions (what can I do?) |
| **Flexibility** | Fixed fields, fixed format | Arbitrary request/response defined by vendor |
| **Required** | Yes — every IPMI-compliant BMC | No — optional extension |
| **Caller** | BIOS, OS, `ipmitool mc info` | Custom host agent, management platform |

In short: **Device ID** identifies the BMC to any standard IPMI client. **OEM commands**
extend IPMI with platform-specific functionality that only DriveNets-aware clients know
how to use.

---

## Where Each Layer Excels

### meta-alphanetworks (Hawk) strengths
- Full secure boot (COT chain, OTP, RSA4096/SHA512, multiple algorithms)
- eMMC dual A/B partition layout for robust firmware updates
- Custom UART routing for console
- Tested with Aspeed SDK downstream Yocto

### meta-drivenets strengths
- Application-layer completeness: fans, LEDs, GPIO, web, network, firmware update
- OEM IPMI extensions (extensible C++ handler framework)
- Multi-machine support in a flat, easy-to-extend layout
- BMC UUID via `machine-id` for unique RMCP+ sessions
- OpenSSH instead of dropbear
- Upstream Yocto compatibility (nanbield/scarthgap)
- Rich documentation (9 guides covering setup, hardware addition, GPIO, I2C, device tree)

---

## Gaps to Address in meta-drivenets

| Gap | Notes |
|-----|-------|
| Secure boot | Disabled (`SOCSEC_SIGN_ENABLE=0`); port from meta-alphanetworks if needed for production |
| eMMC / dual-boot | NOR-only; no WIC layout |
| BBFILE_PRIORITY | Not set; add if layer ordering conflicts arise |
| Q2C fan writePath | Placeholder in `phosphor-pid-control` config — needs real PLD/hwmon path |
| OEM sensor data | `ipmiOemGetSensorData` returns dummy `0xDEADBEEF` — needs real D-Bus wiring |
| Console customization | ttyS4 assumed standard; add bbappend if UART routing is needed |
| IPMI device ID | No `dev_id.json` — default manufacturer ID will be wrong for DriveNets hardware |
