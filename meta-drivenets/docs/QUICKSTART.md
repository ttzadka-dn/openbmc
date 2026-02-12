# Quick Start Guide - meta-drivenets

This guide will help you quickly build and deploy OpenBMC for DriveNets hardware.

## Prerequisites

- Ubuntu 22.04 or similar Linux distribution (Ubuntu 20.04 or Debian 11 also work)
- At least 100GB of free disk space
- 8GB RAM minimum (16GB or more recommended)
- Multi-core CPU (build time scales with CPU cores)

## Required Packages

```bash
sudo apt-get update
sudo apt-get install -y git build-essential diffstat gawk chrpath \
    socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
    iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
    pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool
```

## Building OpenBMC for DriveNets AST2600

### Step 1: Set up the environment

```bash
cd /path/to/openbmc_fork

# Source the setup script for your target machine
. setup drivenets-ast2600
```

This will:
- Create a build directory at `build/drivenets-ast2600`
- Configure bblayers.conf with required layers
- Set MACHINE to drivenets-ast2600

### Step 2: Build the image

```bash
# This will take 2-6 hours on first build (subsequent builds are faster)
bitbake obmc-phosphor-image
```

### Step 3: Locate the output

After successful build, find your images in:
```
build/drivenets-ast2600/tmp/deploy/images/drivenets-ast2600/
```

Key files:
- `obmc-phosphor-image-drivenets-ast2600.static.mtd` - Full flash image
- `image-u-boot` - U-Boot bootloader
- `image-kernel` - Linux kernel
- `image-rofs` - Read-only root filesystem
- `image-rwfs` - Read-write filesystem

### Step 4: Flash the image

#### Option A: Flash entire MTD image (first time)

```bash
# Copy to TFTP server or use your preferred method
scp tmp/deploy/images/drivenets-ast2600/obmc-phosphor-image-drivenets-ast2600.static.mtd \
    user@tftp-server:/tftpboot/

# From BMC U-Boot console:
# tftp 0x83000000 obmc-phosphor-image-drivenets-ast2600.static.mtd
# sf probe
# sf erase 0 0x4000000
# sf write 0x83000000 0 ${filesize}
```

#### Option B: Update via BMC (for updates)

```bash
# If BMC is already running OpenBMC
scp tmp/deploy/images/drivenets-ast2600/obmc-phosphor-image-drivenets-ast2600.static.mtd \
    root@your-bmc-ip:/tmp/

# On the BMC:
# /usr/sbin/phosphor-software-manager --update /tmp/obmc-phosphor-image-drivenets-ast2600.static.mtd
```

## Quick Tips

### Speeding Up Builds

1. **Use more CPU cores:**
   Add to `conf/local.conf`:
   ```
   BB_NUMBER_THREADS = "8"
   PARALLEL_MAKE = "-j 8"
   ```

2. **Enable shared state cache:**
   ```
   SSTATE_DIR = "/path/to/shared/sstate-cache"
   ```

3. **Use download cache:**
   ```
   DL_DIR = "/path/to/shared/downloads"
   ```

### Customizing the Build

Edit `conf/local.conf` to:

- **Enable SSH for debugging:**
  ```
  EXTRA_IMAGE_FEATURES:append = " ssh-server-openssh"
  ```

- **Add development tools:**
  ```
  EXTRA_IMAGE_FEATURES:append = " dev-pkgs tools-debug"
  ```

- **Reduce image size (remove debug):**
  ```
  EXTRA_IMAGE_FEATURES:remove = "debug-tweaks"
  ```

### Common Commands

```bash
# Clean a specific recipe
bitbake -c cleanall <recipe-name>

# Show recipe information
bitbake -e <recipe-name> | grep ^VARIABLE=

# List all recipes
bitbake-layers show-recipes

# Show layer configuration
bitbake-layers show-layers

# Generate SDK
bitbake obmc-phosphor-image -c populate_sdk
```

### Troubleshooting

**Build fails with "Nothing provides..."**
- Check that all layers are added in `conf/bblayers.conf`
- Run `bitbake-layers show-layers` to verify

**Build fails with disk space error**
- Clean temporary files: `rm -rf tmp/`
- Check `df -h` for available space

**Build is very slow**
- Increase `BB_NUMBER_THREADS` and `PARALLEL_MAKE`
- Use SSD instead of HDD
- Check system load with `htop`

## Next Steps

- Customize image with meta-drivenets recipes
- Add hardware-specific configurations
- Set up automated builds
- Configure network and services

## Getting Help

- Check the main [README.md](../README.md)
- Review [CONTRIBUTING.md](../CONTRIBUTING.md)
- See OpenBMC documentation: https://github.com/openbmc/docs
- Contact maintainers (see MAINTAINERS file)
