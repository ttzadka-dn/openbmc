# meta-drivenets

DriveNets OpenBMC Layer - A scalable flat architecture layer supporting multiple hardware platforms.

## Overview

This layer provides OpenBMC support for DriveNets hardware platforms. The layer is designed with a flat architecture to easily support multiple hardware configurations.

## Currently Supported Hardware

- **drivenets-ast2600**: DriveNets platforms based on ASPEED AST2600 EVB
- **drivenets-q2c**: DriveNets Q2C platform (skeleton/template - customize for your hardware)

## Getting Started

### Setup

To build an image for DriveNets hardware:

```bash
# Source the OpenBMC environment
. setup drivenets-ast2600

# Build the image
bitbake obmc-phosphor-image
```

### Manual Configuration

If you prefer to manually configure your build:

1. Add `meta-drivenets` to your `bblayers.conf`:
```
BBLAYERS += "${OEROOT}/meta-drivenets"
```

2. Set the machine in your `local.conf`:
```
MACHINE = "drivenets-ast2600"
```

## Layer Structure

```
meta-drivenets/
├── conf/
│   ├── layer.conf                    # Layer configuration
│   ├── machine/                      # Machine configurations
│   │   └── drivenets-ast2600.conf   # AST2600 machine config
│   └── templates/                    # Build templates
│       └── default/
│           ├── bblayers.conf.sample
│           ├── local.conf.sample
│           └── conf-notes.txt
├── recipes-phosphor/                 # Phosphor recipes
│   └── images/                       # Image recipes
└── README.md
```

## Adding New Hardware

The flat architecture makes it easy to add new hardware platforms. Simply:

1. Create a new machine configuration in `conf/machine/drivenets-<new-hw>.conf`
2. Create a device tree in `recipes-kernel/linux/linux-aspeed/aspeed-bmc-drivenets-<new-hw>.dts`
3. Add the DTS to `recipes-kernel/linux/linux-aspeed_%.bbappend`

**See detailed guide:** [docs/MULTIPLE_MACHINES.md](docs/MULTIPLE_MACHINES.md)

**Quick example:**
```bitbake
# conf/machine/drivenets-<new-hw>.conf
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-drivenets-<new-hw>.dtb"
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
require conf/machine/include/ast2600.inc
SERIAL_CONSOLES = "115200;ttyS4"
FLASH_SIZE = "65536"
IMAGE_FEATURES:remove = "obmc-system-mgmt"
```

All machines live in `conf/machine/` with a flat structure - no nested layers!

## Dependencies

This layer depends on:
- meta-phosphor (OpenBMC base layer)
- meta-aspeed (for AST2600 support)
- meta-openembedded/meta-oe
- meta-openembedded/meta-networking
- meta-openembedded/meta-python

## Layer Compatibility

This layer is compatible with:
- Yocto Nanbield (4.3)
- Yocto Scarthgap (5.0)

## Contact

For issues or questions about this layer, please contact the DriveNets BMC team.

## License

See LICENSE file for details.
