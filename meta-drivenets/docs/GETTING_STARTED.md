# Getting Started with meta-drivenets

Welcome to meta-drivenets! This guide will walk you through using your new OpenBMC layer.

## ✅ What Has Been Created

Your meta-drivenets layer has been successfully created with:

```
meta-drivenets/
├── conf/
│   ├── layer.conf                           # Layer configuration
│   ├── machine/
│   │   └── drivenets-ast2600.conf          # AST2600 machine config
│   └── templates/default/
│       ├── bblayers.conf.sample
│       ├── local.conf.sample
│       └── conf-notes.txt
├── recipes-phosphor/images/
│   └── obmc-phosphor-image.bbappend        # Image customizations
├── docs/
│   ├── QUICKSTART.md                        # Build instructions
│   ├── ADDING_NEW_HARDWARE.md              # Hardware guide
│   ├── LAYER_STRUCTURE.md                  # Architecture info
│   └── GETTING_STARTED.md                  # This file
├── CONTRIBUTING.md                          # Contribution guide
├── LICENSE, COPYING.*                       # License files
├── MAINTAINERS                              # Maintainer info
├── OWNERS                                   # Code owners
└── README.md                                # Main documentation
```

## 🚀 Quick Start (5 Minutes)

### 1. Verify the Layer is Recognized

```bash
cd /home/ttzadka/ws_wsl/openbmc_fork

# List all available machines (should include drivenets-ast2600)
. setup 2>&1 | grep drivenets
```

You should see:
```
drivenets-ast2600
```

### 2. Set Up Build Environment

```bash
# Initialize build for drivenets-ast2600
. setup drivenets-ast2600

# This creates build/drivenets-ast2600/ directory
# and configures all layers automatically
```

### 3. Start Building

```bash
# Build the complete OpenBMC image
# First build takes 2-6 hours depending on your system
bitbake obmc-phosphor-image
```

### 4. Find Your Image

After successful build:
```bash
ls build/drivenets-ast2600/tmp/deploy/images/drivenets-ast2600/

# Key file:
# obmc-phosphor-image-drivenets-ast2600.static.mtd
```

## 📖 Next Steps

### For First-Time Users

1. **Read the Quick Start Guide**
   ```bash
   cat meta-drivenets/docs/QUICKSTART.md
   ```
   - Prerequisites and system requirements
   - Detailed build instructions
   - Flashing procedures
   - Tips and tricks

2. **Understand the Architecture**
   ```bash
   cat meta-drivenets/docs/LAYER_STRUCTURE.md
   ```
   - Layer organization
   - Flat architecture benefits
   - File descriptions

3. **Explore Machine Configuration**
   ```bash
   cat meta-drivenets/conf/machine/drivenets-ast2600.conf
   ```
   - See what's configured
   - Learn the settings
   - Understand the includes

### For Developers

1. **Review Contribution Guidelines**
   ```bash
   cat meta-drivenets/CONTRIBUTING.md
   ```
   - Coding standards
   - Commit message format
   - Review process

2. **Learn to Add New Hardware**
   ```bash
   cat meta-drivenets/docs/ADDING_NEW_HARDWARE.md
   ```
   - Step-by-step guide
   - Configuration examples
   - Testing procedures

3. **Customize the Image**
   ```bash
   # Edit image customizations
   vim meta-drivenets/recipes-phosphor/images/obmc-phosphor-image.bbappend
   ```

## 🎯 Common Use Cases

### Building for Development

```bash
# Set up environment
. setup drivenets-ast2600

# Add debug features to conf/local.conf
echo 'EXTRA_IMAGE_FEATURES:append = " ssh-server-openssh dev-pkgs tools-debug"' >> conf/local.conf

# Build
bitbake obmc-phosphor-image
```

### Building for Production

```bash
# Set up environment
. setup drivenets-ast2600

# Remove debug features from conf/local.conf
sed -i 's/EXTRA_IMAGE_FEATURES.*debug-tweaks.*//' conf/local.conf

# Build
bitbake obmc-phosphor-image
```

### Cleaning and Rebuilding

```bash
# Clean everything
bitbake -c cleanall obmc-phosphor-image

# Or clean specific recipe
bitbake -c cleanall <recipe-name>

# Rebuild
bitbake obmc-phosphor-image
```

### Building SDK

```bash
# Generate SDK for application development
bitbake obmc-phosphor-image -c populate_sdk

# SDK will be in:
# build/drivenets-ast2600/tmp/deploy/sdk/
```

## 🔧 Customization Examples

### Adding Custom Packages

Edit `meta-drivenets/recipes-phosphor/images/obmc-phosphor-image.bbappend`:

```bitbake
IMAGE_INSTALL:append = " \
    your-custom-package \
    another-package \
"
```

### Creating Custom Machine Config

```bash
# Copy existing config
cp meta-drivenets/conf/machine/drivenets-ast2600.conf \
   meta-drivenets/conf/machine/drivenets-newboard.conf

# Edit the new config
vim meta-drivenets/conf/machine/drivenets-newboard.conf

# Build for new machine
. setup drivenets-newboard
bitbake obmc-phosphor-image
```

### Adding Device Tree

1. Create device tree file:
   ```bash
   mkdir -p meta-drivenets/recipes-kernel/linux/linux-aspeed
   vim meta-drivenets/recipes-kernel/linux/linux-aspeed/drivenets-myboard.dts
   ```

2. Create bbappend:
   ```bash
   vim meta-drivenets/recipes-kernel/linux/linux-aspeed_%.bbappend
   ```
   ```bitbake
   FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
   SRC_URI += "file://drivenets-myboard.dts"
   ```

3. Update machine config to use new DTS

## 📊 Build Configuration

### Current Settings

Check your build configuration:

```bash
# After ". setup drivenets-ast2600"

# Check machine
grep "^MACHINE" conf/local.conf

# Check layers
cat conf/bblayers.conf

# Check all variables for a recipe
bitbake -e obmc-phosphor-image | grep "^VARIABLE_NAME="
```

### Performance Tuning

Edit `conf/local.conf`:

```bitbake
# Use more CPU cores (adjust based on your system)
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# Share download cache
DL_DIR = "/path/to/shared/downloads"

# Share build cache
SSTATE_DIR = "/path/to/shared/sstate-cache"
```

## 🐛 Troubleshooting

### Setup Script Doesn't Find Machine

```bash
# Check that template files exist
ls meta-drivenets/conf/templates/default/

# Should show:
# bblayers.conf.sample
# local.conf.sample
# conf-notes.txt
```

### Build Fails with Missing Layers

```bash
# After ". setup drivenets-ast2600"
bitbake-layers show-layers

# Should include:
# meta-phosphor
# meta-aspeed
# meta-drivenets
```

### Out of Disk Space

```bash
# Clean temporary files
rm -rf build/drivenets-ast2600/tmp/

# Or move build to larger disk
. setup drivenets-ast2600 /path/to/large/disk/build
```

## 📚 Documentation Index

| Document | Purpose |
|----------|---------|
| [README.md](../README.md) | Main documentation and overview |
| [QUICKSTART.md](QUICKSTART.md) | Detailed build instructions |
| [ADDING_NEW_HARDWARE.md](ADDING_NEW_HARDWARE.md) | Guide for adding hardware |
| [LAYER_STRUCTURE.md](LAYER_STRUCTURE.md) | Architecture documentation |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Contribution guidelines |
| [GETTING_STARTED.md](GETTING_STARTED.md) | This file |

## 🤝 Getting Help

1. **Check Documentation**
   - Start with README.md
   - Review relevant docs in docs/

2. **Check OpenBMC Resources**
   - [OpenBMC Documentation](https://github.com/openbmc/docs)
   - [OpenBMC Mailing List](https://lists.ozlabs.org/listinfo/openbmc)
   - [OpenBMC Discord](https://discord.gg/openbmc)

3. **Contact Maintainers**
   - See MAINTAINERS file
   - Open an issue in your repository

## ✨ What Makes This Layer Special

### Flat Architecture
- No nested sub-layers
- Easy to add new hardware
- Simple to understand and maintain

### Well Documented
- Comprehensive guides
- Examples for common tasks
- Clear contribution guidelines

### Production Ready
- Based on OpenBMC best practices
- Compatible with latest Yocto releases
- Follows standard conventions

### Scalable
- Designed to support multiple hardware platforms
- Easy to extend and customize
- Maintainable as the project grows

## 🎉 You're All Set!

Your meta-drivenets layer is ready to use. Key commands to remember:

```bash
# Set up build environment
. setup drivenets-ast2600

# Build image
bitbake obmc-phosphor-image

# Check layers
bitbake-layers show-layers

# Clean and rebuild
bitbake -c cleanall obmc-phosphor-image
bitbake obmc-phosphor-image
```

Happy building! 🚀
