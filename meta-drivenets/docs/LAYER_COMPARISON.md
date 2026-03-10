# Layer Comparison: meta-alphanetworks (Hawk) vs meta-drivenets

> Last updated: 2026-03-04
>
> This document compares the Alpha Networks Hawk OpenBMC layer with meta-drivenets,
> documents what was ported, what was intentionally skipped, and what remains open.

---

## 1. Layer Structure

| Aspect | meta-alphanetworks (Hawk) | meta-drivenets |
|--------|--------------------------|----------------|
| Layout | Parent layer + `meta-hawk` sub-layer | Flat single layer |
| Machines | 1 (`hawk`) | 2 (`drivenets-ast2600`, `drivenets-q2c`) |
| Yocto series | `whinlatter`, `walnascar` (Aspeed SDK fork) | `nanbield`, `scarthgap` (upstream Yocto) |
| LAYERDEPENDS | `aspeed-sdk-layer` | `phosphor-layer`, `aspeed-layer` |
| BBFILE_PRIORITY | Not set (default 6) | Not set (default 6) — consistent with all OpenBMC vendor layers |
| Documentation | None | `docs/` folder with 9+ guides |

---

## 2. Machine Configuration

| Feature | meta-alphanetworks (hawk) | meta-drivenets |
|---------|--------------------------|----------------|
| SoC | AST2600 | AST2600 (EVB), AST2620 (Q2C DC-SCM) |
| U-Boot defconfig | `evb-ast2600_defconfig` | `ast2600_openbmc_spl_defconfig` (SPL) |
| Console UART | ttyS2 (UART3) | **ttyS4 (UART5)** — confirmed from `ast2600_openbmc_spl_defconfig` |
| Flash size | 64 MB | 64 MB |
| Boot media | NOR + eMMC | NOR only |
| Secure boot | Enabled (COT, OTP, RSA4096/SHA512) | Disabled (`SOCSEC_SIGN_ENABLE=0`) |
| TPM2 | Yes (via `aspeed-tpm2.inc`) | Yes (in `drivenets-common.inc`) |
| Host power control | `x86-power-control` | GPIO-based (power/reset via SCM PLD) |
| Host IPMI interface | Standard | KCS (`phosphor-ipmi-kcs`) on Q2C |

---

## 3. Recipes — Side-by-Side

| Area | meta-alphanetworks | meta-drivenets | Status |
|------|--------------------|----------------|--------|
| **Image** | Minimal (secureboot dep) | Full package list, OpenSSH, hostname | ✅ Done |
| **Kernel DTS** | hawk DTS/cfg + `prepare_dts` | Machine DTS + `do_configure` | ✅ Done |
| **U-Boot DTS** | hawk DTS/cfg, eMMC env, socsec-sign | Machine-specific kconfig fragments | ✅ Done |
| **U-Boot fw-utils** | `fw_env_nor.config` + `fw_env_mmc.config` | **`fw_env_nor.config`** (NOR only) | ✅ Ported |
| **Console** | ttyS2 + software UART routing | **ttyS4, port 2200, concurrent servers** | ✅ Added |
| **IPMI device ID** | `phosphor-ipmi-config.bbappend` + `dev_id.json` | **`dev_id.json` (manuf_id: 49739)** | ✅ Added |
| **OEM IPMI** | None | `drivenets-ipmi-oem_1.0.bb` (NetFn 0x30) | ✅ Done |
| **Entity manager** | hawk.json + ast2600-evb.json + blacklist.json | Machine-specific JSON | ✅ Done |
| **FRU** | Entity-manager based | `phosphor-ipmi-fru_%.bbappend` + `fru-read.json` | ✅ Done |
| **Fan control** | None | `phosphor-pid-control_%.bbappend` + PID config | ✅ Done |
| **GPIO monitor** | None | `phosphor-gpio-monitor_%.bbappend` | ✅ Done |
| **LED manager** | None | `phosphor-led-manager-config-native.bb` + YAML | ✅ Done |
| **Network** | None | `phosphor-network_%.bbappend` (hostname, NTP, NCSI) | ✅ Done |
| **BMC web** | None | `bmcweb_%.bbappend` (Redfish journal, host logger) | ✅ Done |
| **Software update** | None | `phosphor-software-manager_%.bbappend` (dual slots) | ✅ Done |
| **dbus-sensors** | External sensor flag | fansensor + hwmontempsensor + psusensor | ✅ Done |
| **Secure boot image** | `aspeed-image-gen-secureboot.bb` | Not needed | ⏭ Skipped |
| **eMMC WIC layout** | `ast2600-emmc.wks.in` (dual A/B) | Not needed (NOR only) | ⏭ Skipped |
| **UART routing** | Software routing (uart3↔uart1, io1↔uart4) | Not needed (physical MUX on Q2C) | ⏭ Skipped |

---

## 4. IPMI: Device ID vs OEM Commands

These are two separate IPMI mechanisms that serve different purposes.

### IPMI Device ID — `phosphor-ipmi-config.bbappend` + `dev_id.json`

**Standard IPMI command:** `Get Device ID` — NetFn 0x06, Cmd 0x01

Mandatory, read-only identity record defined by the IPMI spec. Tells any IPMI client
*who this BMC is* — manufacturer, product, and firmware version.

**DriveNets `dev_id.json`:**

```json
{
    "id": 1,
    "revision": 1,
    "firmware_revision": { "major": 0, "minor": 1 },
    "addn_dev_support": 11,
    "manuf_id": 49739,
    "prod_id": 1,
    "aux": 0
}
```

`manuf_id: 49739` is DriveNets' officially registered IANA Private Enterprise Number
(confirmed at iana.org/assignments/enterprise-numbers, contact: Gal Zolkover).

**Use case:** Any IPMI client — BIOS, OS, `ipmitool mc info` — uses this to identify
the BMC before further communication.

### OEM IPMI Commands — `drivenets-ipmi-oem_1.0.bb`

**Custom commands:** NetFn 0x30 (OEM One), Cmd 0x01–0x03

Vendor-defined handlers compiled as a C++ shared library and loaded dynamically by
`ipmid`. Allow platform-specific actions not covered by the IPMI spec.

| Command | Cmd | Request | Response | Status |
|---------|-----|---------|----------|--------|
| Get Version | 0x01 | 1 byte (param) | major, minor, status | Stub (returns 1.0) |
| Get Sensor Data | 0x02 | 1 byte (sensor ID) | byte array | **Stub** — returns `0xDEADBEEF` |
| Get Build Timestamp | 0x03 | empty | null-terminated string | Returns `__DATE__ __TIME__` |

### Comparison

| | IPMI Device ID | OEM IPMI Commands |
|-|----------------|-------------------|
| Defined by | IPMI spec (mandatory) | Vendor (fully custom) |
| NetFn / Cmd | 0x06 / 0x01 | 0x30 / 0x01–0x03 |
| Implementation | Static JSON config file | Compiled C++ shared library |
| Purpose | BMC identity ("who am I?") | Platform-specific actions |
| Required | Yes — every IPMI BMC | No — optional extension |
| Caller | Any IPMI client | DriveNets-aware client only |

---

## 5. Console Configuration

### Hawk approach (ttyS2 + software UART routing)

Hawk routes the host serial console through the AST2600 UART routing block:

```
# server.ttyS2.conf
aspeed-uart-routing = uart3:uart1 uart1:uart3 io1:uart4 uart4:io1
```

And restores it on stop via a systemd override (`ExecStopPost`).

### DriveNets approach (ttyS4, physical MUX)

**ttyS4 (UART5) confirmed** from `ast2600_openbmc_spl_defconfig`:
```
CONFIG_BOOTARGS="console=ttyS4,115200n8 root=/dev/ram rw"
```
Also matches `drivenets-common.inc` (`SERIAL_CONSOLES = "115200;ttyS4"`) and the
upstream `evb-ast2600.conf`.

Q2C uses a physical UART_SEL push-button MUX to select between UART0_BMC and
UART1_BMC going to the Console Board → UART_RJ45. No software UART routing needed.

Files added:
- `recipes-phosphor/console/obmc-console_%.bbappend` — ttyS4, port 2200, concurrent servers
- `recipes-phosphor/console/obmc-console/server.ttyS4.conf`
- `recipes-phosphor/console/obmc-console/client.2200.conf`

---

## 6. U-Boot Environment Access (`fw_printenv` / `fw_setenv`)

Ported from Hawk. Allows Linux userspace to read and write U-Boot environment variables.
Required by firmware update scripts (boot partition selection, boot count, etc.).

**`fw_env_ast2600_nor.config`** — offsets match `drivenets-q2c.cfg`:

```
# CONFIG_ENV_OFFSET    = 0x120000
# CONFIG_ENV_SIZE      = 0x20000
# CONFIG_ENV_SECT_SIZE = 0x10000

/dev/mtd/u-boot-env   0x0000   0x20000   0x10000
```

Installed via `u-boot-fw-utils-aspeed-sdk_%.bbappend`.

The eMMC variant (`fw_env_mmc.config`) was not ported — Q2C is NOR-only.

---

## 7. BBFILE_PRIORITY

Not set in meta-drivenets. This is **intentional and correct** — consistent with every
other OpenBMC vendor layer (meta-ibm, meta-facebook, meta-google, meta-quanta, meta-aspeed,
meta-phosphor, etc., none of which set it). The default value of 6 already outranks
the base layers (`meta`, `meta-poky` at 5). Priority conflicts are resolved by
`bblayers.conf` ordering; since meta-drivenets is the outermost layer it naturally wins.

---

## 8. What Was Intentionally Skipped from Hawk

| Feature | Reason skipped |
|---------|---------------|
| Secure boot (COT, OTP, RSA4096, socsec-sign, otptool) | Disabled by design (`SOCSEC_SIGN_ENABLE=0`); port if production security is required |
| `aspeed-image-gen-secureboot.bb` | Secure boot only, not needed |
| eMMC WIC layout (`ast2600-emmc.wks.in`) | Q2C uses NOR flash only |
| `fw_env_mmc.config` | Q2C uses NOR flash only |
| eMMC U-Boot env (`u-boot-env.txt`) | Q2C uses NOR flash only |
| Software UART routing | Q2C uses physical UART_SEL MUX; no routing needed |
| `BBFILES_DYNAMIC` (meta-arm/zephyrcore) | No Zephyr or TF-A recipes in scope |
| `LAYERVERSION` | No versioning requirement at this stage |

---

## 9. Open Items / TODOs

| Item | Detail |
|------|--------|
| **OEM sensor data** | `ipmiOemGetSensorData` (Cmd 0x02) returns stub `0xDEADBEEF` — wire real D-Bus sensor reads |
| **Q2C fan writePath** | `phosphor-pid-control` config has placeholder writePath — needs real SCM PLD I2C register map |
| **SGPIO bit assignments** | Panel LED bit positions on SGPIOM1 are placeholders — verify from SCM PLD firmware docs |
| **LPC / KCS** | `&lpc_ctrl` and `&kcs3` commented out in DTS — enable once KCS port address confirmed from BIOS |
| **NCSI MAC** | Which MAC (mac0 or mac1) connects to AMD x86 COMe via NCSI — TBD |
| **SCM PLD second I2C address** | 0x6F via PFR_I2C5 — TBD from PFR firmware |
| **AST1060 I2C address** | PFR chip management address (typically 0x38 or 0x70) — TBD |
| **TEMP1/TEMP2 parts** | TMP75 assumed on i2c15 @0x48/0x49 — verify from DC-SCM BOM |
| **RTC / PMIC parts** | Placeholder compatibles on i2c15 @0x32/@0x14 — verify from BOM |
| **Secure boot** | Not enabled; port from meta-alphanetworks if required for production |
| **`prod_id` in dev_id.json** | Set to 1 as placeholder — assign a real product ID within DriveNets' namespace |

---

## 10. Where Each Layer Excels

### meta-alphanetworks (Hawk) strengths
- Full secure boot chain (COT, OTP, RSA4096/SHA512, multiple algorithms)
- eMMC dual A/B partition layout for robust firmware updates
- Custom UART routing for host console through BMC

### meta-drivenets strengths
- Application-layer completeness: fans, LEDs, GPIO, web, network, firmware update
- OEM IPMI extensions (extensible C++ handler framework, NetFn 0x30)
- IPMI device ID with registered DriveNets IANA PEN (49739)
- U-Boot environment access from Linux (`fw_printenv` / `fw_setenv`)
- Console on ttyS4 (confirmed from defconfig), SSH access on port 2200
- Multi-machine support (drivenets-ast2600 + drivenets-q2c) in a flat layout
- BMC UUID via `machine-id` for unique RMCP+ sessions
- OpenSSH instead of dropbear
- Upstream Yocto compatibility (nanbield / scarthgap)
- Rich documentation (9+ guides)
