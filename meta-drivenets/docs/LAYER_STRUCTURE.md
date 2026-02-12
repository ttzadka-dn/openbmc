# meta-drivenets Layer Structure

This document describes the organization and structure of the meta-drivenets layer.

## Directory Layout

```
meta-drivenets/
├── conf/                                 # Layer configuration
│   ├── layer.conf                       # Layer metadata and dependencies
│   ├── machine/                         # Machine configurations
│   │   └── drivenets-ast2600.conf      # AST2600 machine config
│   └── templates/                       # Build templates
│       └── default/
│           ├── bblayers.conf.sample    # Sample layer configuration
│           ├── local.conf.sample       # Sample local configuration
│           └── conf-notes.txt          # Build completion notes
│
├── recipes-phosphor/                    # OpenBMC/Phosphor recipes
│   └── images/
│       └── obmc-phosphor-image.bbappend # Image customizations
│
├── docs/                                # Documentation
│   ├── QUICKSTART.md                   # Quick start guide
│   ├── ADDING_NEW_HARDWARE.md          # Guide for adding new hardware
│   └── LAYER_STRUCTURE.md              # This file
│
├── CONTRIBUTING.md                      # Contribution guidelines
├── COPYING.apache-2.0                   # Apache 2.0 license text
├── COPYING.MIT                          # MIT license text
├── LICENSE                              # License summary
├── MAINTAINERS                          # Maintainer information
├── OWNERS                               # Code owners
├── README.md                            # Main documentation
└── .gitignore                           # Git ignore patterns

```

## File Descriptions

### Core Configuration Files

#### `conf/layer.conf`
Main layer configuration file that defines:
- Layer name and paths
- Recipe paths (BBFILES)
- Layer dependencies
- Compatible Yocto versions

```bitbake
BBFILE_COLLECTIONS += "meta-drivenets"
BBFILE_PATTERN_meta-drivenets = "^${LAYERDIR}/"
LAYERSERIES_COMPAT_meta-drivenets = "nanbield scarthgap"
```

#### `conf/machine/<machine>.conf`
Individual machine configurations containing:
- Kernel device tree
- U-Boot settings
- Serial console configuration
- Flash size
- SOC-specific includes

### Template Files

#### `conf/templates/default/bblayers.conf.sample`
Template for BitBake layers configuration:
- Lists all required layers
- Used by setup script to initialize builds
- Must include meta-phosphor and meta-aspeed

#### `conf/templates/default/local.conf.sample`
Template for local build configuration:
- Sets default MACHINE
- Defines build options
- Includes common settings

#### `conf/templates/default/conf-notes.txt`
Information displayed after build setup:
- Common build targets
- Quick usage tips

### Recipe Directories

Recipe directories follow OpenBMC naming conventions:

```
recipes-<category>/
└── <package-name>/
    ├── <package-name>.bb          # Recipe
    ├── <package-name>.bbappend    # Recipe modification
    └── files/                      # Recipe files
        └── *.conf, *.json, etc.
```

Common categories:
- `recipes-phosphor/` - OpenBMC phosphor components
- `recipes-kernel/` - Kernel and device trees
- `recipes-bsp/` - Board support packages
- `recipes-core/` - Core system recipes
- `recipes-extended/` - Extended functionality

### Documentation Files

#### `README.md`
Main layer documentation:
- Overview and purpose
- Supported hardware list
- Quick start instructions
- Layer structure
- How to add new hardware

#### `docs/QUICKSTART.md`
Step-by-step guide:
- Prerequisites
- Build instructions
- Flashing procedures
- Common commands

#### `docs/ADDING_NEW_HARDWARE.md`
Developer guide:
- How to add new machine configs
- Configuration examples
- Testing procedures

#### `docs/LAYER_STRUCTURE.md`
This document describing layer organization.

### Legal Files

#### `LICENSE`
Overall license summary for the layer.

#### `COPYING.apache-2.0`
Full Apache 2.0 license text.

#### `COPYING.MIT`
Full MIT license text.

### Maintainer Files

#### `MAINTAINERS`
Lists maintainers and reviewers:
- Contact information
- Areas of responsibility
- Review process

#### `OWNERS`
Code ownership for automation:
- Used by CI/CD systems
- Defines approval requirements

#### `CONTRIBUTING.md`
Guidelines for contributors:
- Development workflow
- Coding standards
- Commit message format
- Review process

## Flat Architecture Benefits

The meta-drivenets layer uses a flat architecture where:

1. **Machine configs are at single level**: All in `conf/machine/`
2. **No nested sub-layers**: Unlike meta-evb which has meta-evb-aspeed/meta-evb-ast2600
3. **Easy to scale**: Just add new .conf files for new hardware
4. **Simple to maintain**: No complex layer hierarchies

### Comparison

**Traditional (nested)**:
```
meta-drivenets/
├── meta-drivenets-aspeed/
│   ├── meta-drivenets-ast2600/
│   │   └── conf/machine/...
│   └── meta-drivenets-ast2500/
│       └── conf/machine/...
└── meta-drivenets-nuvoton/
    └── conf/machine/...
```

**Flat (meta-drivenets)**:
```
meta-drivenets/
└── conf/machine/
    ├── drivenets-ast2600.conf
    ├── drivenets-ast2500.conf
    ├── drivenets-npcm750.conf
    └── (future hardware configs...)
```

## Adding New Hardware

To add new hardware to this flat structure:

1. Create `conf/machine/drivenets-<hardware>.conf`
2. Configure the machine file
3. Update README.md
4. Test the build

That's it! No need to create sub-layers or complex directory structures.

## Layer Dependencies

The meta-drivenets layer depends on:

```
meta-drivenets
    ├── meta-phosphor (OpenBMC base)
    ├── meta-aspeed (for AST2x00 support)
    ├── meta-nuvoton (for NPCM support)
    ├── meta-openembedded/meta-oe
    ├── meta-openembedded/meta-python
    └── meta-openembedded/meta-networking
```

Dependency graph:
```
┌──────────────────┐
│  meta-drivenets  │
└────────┬─────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    │         │          │          │
┌───▼────┐ ┌─▼────┐ ┌───▼─────┐ ┌──▼──────┐
│ meta-  │ │ meta-│ │  meta-  │ │  meta-  │
│phosphor│ │aspeed│ │openembed│ │  poky   │
└────────┘ └──────┘ └─────────┘ └─────────┘
```

## Recipe Override Order

BitBake searches layers in order defined in bblayers.conf:

1. meta-drivenets (highest priority for overrides)
2. meta-aspeed
3. meta-phosphor
4. meta-openembedded layers
5. meta (poky base)

This allows meta-drivenets to override configurations from other layers.

## Best Practices

### For Maintainers

1. Keep machine configs minimal and focused
2. Use comments to explain non-obvious settings
3. Follow OpenBMC naming conventions
4. Document all hardware-specific features
5. Test on actual hardware before committing

### For Contributors

1. Review CONTRIBUTING.md before making changes
2. Follow the flat architecture pattern
3. Don't create unnecessary subdirectories
4. Update documentation with changes
5. Test builds before submitting

### For Users

1. Start with QUICKSTART.md
2. Use the setup script for configuration
3. Refer to docs/ for detailed information
4. Check machine configs for hardware specifics

## Related Documentation

- [OpenBMC Yocto Layers](https://github.com/openbmc/docs/blob/master/yocto-development.md)
- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [BitBake User Manual](https://docs.yoctoproject.org/bitbake/)

## Future Expansion

As the layer grows, maintain the flat structure:

```
meta-drivenets/
├── conf/machine/
│   ├── drivenets-ast2600.conf     # Current
│   ├── drivenets-ast2500.conf     # Future
│   ├── drivenets-ast1030.conf     # Future
│   ├── drivenets-npcm750.conf     # Future
│   └── drivenets-custom.conf      # Future
```

Keep it simple, keep it flat!
