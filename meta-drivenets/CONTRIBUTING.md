# Contributing to meta-drivenets

Thank you for your interest in contributing to the DriveNets OpenBMC layer!

## Development Workflow

### Setting Up Your Environment

1. Clone the OpenBMC repository with all submodules
2. Navigate to the meta-drivenets layer
3. Make your changes

### Making Changes

1. Create a new branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the guidelines below

3. Test your changes:
   ```bash
   . setup drivenets-ast2600
   bitbake obmc-phosphor-image
   ```

4. Commit your changes with a descriptive message:
   ```bash
   git commit -s -m "Brief description of your change
   
   Detailed explanation of what changed and why."
   ```

### Coding Guidelines

#### BitBake Recipes (.bb, .bbappend)

- Follow the [Yocto Project style guide](https://www.openembedded.org/wiki/Styleguide)
- Use 4 spaces for indentation
- Keep lines under 80 characters when possible
- Order recipe components as: LICENSE, SRC_URI, dependencies, tasks

#### Machine Configuration Files

- Keep machine configs focused and minimal
- Document any non-obvious settings with comments
- Use `require` for required includes, `include` for optional ones

#### Commit Messages

- Use the imperative mood ("Add feature" not "Added feature")
- First line should be 50 characters or less
- Add a blank line after the first line
- Wrap subsequent lines at 72 characters
- Include Signed-off-by line (`git commit -s`)

Example:
```
Add support for custom GPIO configuration

This change adds support for configuring custom GPIO pins
in the machine configuration file, allowing platforms to
define their specific GPIO requirements.

Signed-off-by: Your Name <your.email@example.com>
```

### Testing

Before submitting changes:

1. **Build test**: Ensure the image builds successfully
   ```bash
   bitbake obmc-phosphor-image
   ```

2. **Runtime test**: If possible, test on actual hardware or QEMU

3. **Layer check**: Verify layer compatibility
   ```bash
   bitbake-layers show-layers
   ```

### Submitting Changes

1. Push your branch to your fork
2. Create a pull request with:
   - Clear description of what changed
   - Why the change is needed
   - Any testing performed
   - Screenshots/logs if relevant

### Code Review Process

- All changes require review from maintainers
- Address review comments promptly
- Be open to feedback and suggestions

### Adding New Hardware Support

When adding support for new hardware:

1. Create a new machine configuration in `conf/machine/`
2. Update README.md to list the new hardware
3. Provide documentation on any hardware-specific features
4. Include device tree or hardware description if applicable

### Questions?

If you have questions:
- Open an issue in the repository
- Contact the maintainers (see MAINTAINERS file)
- Refer to [OpenBMC documentation](https://github.com/openbmc/docs)

Thank you for contributing!
