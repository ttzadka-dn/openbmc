# meta-drivenets

DriveNets OpenBMC Layer - A scalable flat architecture layer supporting multiple hardware platforms.

## Overview

This layer provides OpenBMC support for DriveNets hardware platforms. The layer is designed with a flat architecture to easily support multiple hardware configurations.

## Currently Supported Hardware

- **drivenets-ast2600**: DriveNets platforms based on ASPEED AST2600 SOC

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

To add support for new hardware platforms:

1. Create a new machine configuration in `conf/machine/<machine-name>.conf`
2. Update the machine configuration with appropriate:
   - Kernel device tree
   - U-Boot configuration
   - Serial console settings
   - Flash size
   - SOC-specific includes

Example:
```bitbake
# conf/machine/drivenets-<new-hw>.conf
KERNEL_DEVICETREE = "..."
UBOOT_MACHINE = "..."
require conf/machine/include/<soc>.inc
```

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
