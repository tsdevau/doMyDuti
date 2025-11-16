# doMyDuti - Default File Handler Configuration

A portable, configurable script to set your preferred text editor/IDE as the default handler for code and development file extensions on macOS using `duti`.

## 🚀 Quick Start

```bash
# 1. Install prerequisites
brew install duti

# 2. Make script executable
chmod +x doMyDuti.sh

# 3. Configure file handlers (default: Cursor)
./doMyDuti.sh

# Or with VS Code
./doMyDuti.sh -b com.microsoft.VSCode
```

## 📋 Quick Reference

### Common Commands

```bash
# Default (uses config resolution order)
./doMyDuti.sh

# Different application
./doMyDuti.sh -b com.microsoft.VSCode

# Custom config file
./doMyDuti.sh -c ~/my_config.jsonc

# Both options
./doMyDuti.sh -b com.microsoft.VSCode -c ~/my_config.jsonc

# Check current handler
duti -x ts

# View help
./doMyDuti.sh -h
```

### Common Bundle IDs

| Application   | Bundle ID                       |
| ------------- | ------------------------------- |
| Cursor        | `com.todesktop.230313mzl4w4u92` |
| VS Code       | `com.microsoft.VSCode`          |
| Sublime Text  | `com.sublimetext.4`             |
| Zed           | `dev.zed.Zed`                   |
| BBEdit        | `com.barebones.bbedit`          |
| TextMate      | `com.macromates.TextMate`       |
| Atom          | `com.github.atom`               |
| Nova          | `com.panic.Nova`                |
| IntelliJ IDEA | `com.jetbrains.intellij`        |
| WebStorm      | `com.jetbrains.WebStorm`        |
| PyCharm       | `com.jetbrains.pycharm`         |

**Find any bundle ID:**
```bash
osascript -e 'id of application "App Name"'
```

## 📦 Package Contents

- **`doMyDuti.sh`** - Main executable script (portable, configurable)
- **`doMyDuti.jsonc`** - Configuration file with file extensions (JSONC format)
- **`install.sh`** - Interactive installation helper

## 🎯 Key Features

### Portability
- ✅ No hardcoded paths
- ✅ Config file auto-detected via multiple resolution strategies
- ✅ Works from any location
- ✅ Can be moved/copied anywhere

### Flexibility
- ✅ Support for any text editor/IDE
- ✅ Multiple config file resolution locations
- ✅ Override bundle ID via command line
- ✅ Single config file works with multiple apps
- ✅ Supports XDG_CONFIG_HOME standard

### Comprehensive Coverage
- ✅ 100+ file extensions configured
- ✅ Web development (HTML, CSS, JS, TS, Svelte, Astro, Vue)
- ✅ .NET and C# (project types)
- ✅ Python, Ruby, PHP, Java, Kotlin, Scala
- ✅ Go, Rust, C, C++, Swift
- ✅ Shell scripts, AppleScript
- ✅ Config files (JSON, YAML, TOML, ENV)
- ✅ Markup (Markdown, XML, LaTeX)
- ✅ Infrastructure (Docker, Terraform, CI/CD)

### Smart Configuration
- ✅ JSONC format with comments support
- ✅ Automatic bundle ID and config file resolution
- ✅ Priority-based configuration system

## 📋 Command-Line Options

| Option               | Description                   | Default                                      |
| -------------------- | ----------------------------- | -------------------------------------------- |
| `-c, --config FILE`  | Path to config file           | See [Config Resolution](#config-file-resolution) |
| `-b, --bundleId ID`  | Application bundle identifier | See [Bundle ID Resolution](#bundle-id-resolution) |
| `-h, --help`         | Show help message             | -                                            |

## 🔍 Configuration Resolution

### Config File Resolution Order

The script searches for configuration files in this order:

1. **CLI parameter** - File specified with `-c/--config` flag
2. **XDG_CONFIG_HOME** - `$XDG_CONFIG_HOME/doMyDuti/doMyDuti.jsonc`
3. **User home** - `~/.doMyDuti.jsonc`
4. **Script directory** - `doMyDuti.jsonc` in the same directory as the script

### Bundle ID Resolution Order

The bundle ID is resolved in this priority order:

1. **CLI parameter** - Bundle ID specified with `-b/--bundleId` flag
2. **XDG_CONFIG_HOME config** - `bundleId` field in `$XDG_CONFIG_HOME/doMyDuti/doMyDuti.jsonc`
3. **User home config** - `bundleId` field in `~/.doMyDuti.jsonc`
4. **Script default config** - `bundleId` field in script directory's `doMyDuti.jsonc`
5. **Script default** - `com.todesktop.230313mzl4w4u92` (Cursor)

## 📝 Configuration File Format

The configuration file uses **JSONC** (JSON with Comments) format:

```jsonc
{
  "bundleId": "com.todesktop.230313mzl4w4u92",
  "extensions": [
    // Comments are supported with //
    [".ts", "all"],
    [".js", "all"],
    [".py", "all"],
    [".md", "all"]
  ]
}
```

### Format Details

- **`bundleId`** (optional): Application bundle identifier. Ignored if `-b` option is used.
- **`extensions`**: Array of `[extension, role]` pairs
  - **Extension**: File extension (e.g., `.ts`, `.js`, `.py`)
  - **Role**: Always `"all"` (handles extension in all contexts)

### Example Configurations

**Minimal config (extensions only):**
```jsonc
{
  "extensions": [
    [".ts", "all"],
    [".js", "all"]
  ]
}
```

**With bundle ID:**
```jsonc
{
  "bundleId": "com.microsoft.VSCode",
  "extensions": [
    [".ts", "all"],
    [".js", "all"],
    [".py", "all"]
  ]
}
```

**With comments:**
```jsonc
{
  // This bundle ID will be used if -b is not specified
  "bundleId": "com.todesktop.230313mzl4w4u92",
  "extensions": [
    // TypeScript files
    [".ts", "all"],
    [".tsx", "all"],
    // JavaScript files
    [".js", "all"],
    [".jsx", "all"]
  ]
}
```

## 💻 Usage Examples

### Basic Usage

```bash
# Use default resolution (checks XDG_CONFIG_HOME, ~/.doMyDuti.jsonc, then script default)
./doMyDuti.sh

# Use custom config file
./doMyDuti.sh -c ~/my_config.jsonc

# Use different application (e.g., VS Code)
./doMyDuti.sh -b com.microsoft.VSCode

# Combine both options
./doMyDuti.sh -c ~/my_config.jsonc -b com.microsoft.VSCode
```

### Use with Different Applications

```bash
# VS Code
./doMyDuti.sh -b com.microsoft.VSCode

# Sublime Text
./doMyDuti.sh -b com.sublimetext.4

# Zed
./doMyDuti.sh -b dev.zed.Zed

# BBEdit
./doMyDuti.sh -b com.barebones.bbedit
```

### XDG_CONFIG_HOME Setup

```bash
# Create XDG config directory
mkdir -p ~/.config/doMyDuti

# Copy config file
cp doMyDuti.jsonc ~/.config/doMyDuti/

# Run script (will automatically find config in XDG_CONFIG_HOME)
./doMyDuti.sh
```

### User Home Config

```bash
# Copy config to home directory
cp doMyDuti.jsonc ~/.doMyDuti.jsonc

# Run script (will automatically find config in home)
./doMyDuti.sh
```

## 🎨 Finding Bundle IDs

To find the bundle ID of any installed application:

```bash
# Method 1: Using osascript (recommended)
osascript -e 'id of application "Application Name"'

# Method 2: Using mdls
mdls -name kMDItemCFBundleIdentifier -r /Applications/Application.app

# Examples:
osascript -e 'id of application "Cursor"'        # com.todesktop.230313mzl4w4u92
osascript -e 'id of application "Visual Studio Code"'  # com.microsoft.VSCode
osascript -e 'id of application "Sublime Text"'  # com.sublimetext.4
```

## 📂 Installation Options

### Option 1: Use Installation Helper

```bash
chmod +x install.sh
./install.sh
```

The installation helper will:
- Check for `duti` and install if needed
- Guide you through choosing an installation location
- Copy files and set permissions
- Provide instructions for adding to PATH

### Option 2: Manual Installation

**Personal scripts directory:**
```bash
mkdir -p ~/scripts
cp doMyDuti.sh doMyDuti.jsonc ~/scripts/
chmod +x ~/scripts/doMyDuti.sh
```

**User bin (if in PATH):**
```bash
mkdir -p ~/bin
cp doMyDuti.sh doMyDuti.jsonc ~/bin/
chmod +x ~/bin/doMyDuti.sh
```

**XDG_CONFIG_HOME (recommended for config):**
```bash
mkdir -p ~/.config/doMyDuti
cp doMyDuti.jsonc ~/.config/doMyDuti/
# Script will automatically find config here
```

**User home (alternative for config):**
```bash
cp doMyDuti.jsonc ~/.doMyDuti.jsonc
# Script will automatically find config here
```

### Making Script Globally Accessible

Add the installation directory to your PATH in `~/.zshrc`:

```bash
export PATH="$PATH:$HOME/bin"
# or
export PATH="$PATH:$HOME/scripts"
# or
export PATH="$PATH:$HOME/.local/bin"
```

Then reload your shell:
```bash
source ~/.zshrc
```

## 🔍 Verification

After running the script, verify the configuration:

```bash
# Check handler for a specific extension
duti -x ts

# List all handlers for your application
duti -l | grep -i cursor
duti -l | grep -i "visual studio code"
```

## 📊 Coverage

The default configuration covers:

### Web Development
- HTML, CSS, SCSS, Sass, Less
- JavaScript, TypeScript (all variants)
- Vue, Svelte, Astro
- EJS, Handlebars, Pug, Jade
- WebAssembly (.wasm, .wat)

### .NET & C#
- C#, VB.NET, F#
- Project files (.csproj, .sln)
- XAML, RESX

### Languages
- Python, Ruby, PHP
- Java, Kotlin, Scala, Groovy
- Go, Rust
- C, C++, Objective-C
- Swift (non-Xcode files)
- Lua, Perl, R
- Haskell, Elixir, Erlang
- Clojure, Dart, Julia, Zig
- Crystal, Nim, OCaml, Reason/ReScript
- V, Nix

### Shell & Scripting
- Bash, Zsh, Fish
- AppleScript

### Configuration & Data
- JSON, YAML, TOML, XML
- INI, ENV files
- CSV, TSV
- Markdown, reStructuredText
- JSON-LD, GeoJSON, TopoJSON

### Build & Infrastructure
- Docker, Terraform
- CMake, Makefile
- Package manager configs (npmrc, yarnrc, bunfig)
- CI/CD configs (GitLab CI, Travis, CircleCI)
- Prisma, Deno configs
- Cloudflare Workers, Vercel configs

### Development Tools
- ESLint, Prettier configs
- Husky configs
- Vite, Svelte Kit configs
- Diff and patch files

### Explicitly NOT Handled
The script intentionally leaves these for Xcode:
- `.plist` files
- `.xib` files
- `.storyboard` files
- Xcode project files (`.xcodeproj`, `.xcworkspace`)

## 🛠️ Customization

### Adding More Extensions

Edit your config file and add entries to the `extensions` array:

```jsonc
{
  "extensions": [
    [".ts", "all"],
    [".js", "all"],
    [".your_extension", "all"]  // Add your extension here
  ]
}
```

### Creating Multiple Config Files

You can create different config files for different purposes:

```bash
# Web development config
./doMyDuti.sh -c ~/configs/webdev.jsonc

# Python development config
./doMyDuti.sh -c ~/configs/python.jsonc

# .NET development config
./doMyDuti.sh -c ~/configs/dotnet.jsonc
```

### Using jq for Advanced Parsing

The script prefers `jq` for parsing JSONC if available. Install it for better performance:

```bash
brew install jq
```

## 🐛 Troubleshooting

### Script fails to run
- Ensure it's executable: `chmod +x doMyDuti.sh`
- Check duti is installed: `which duti`
- Verify config file exists or use `-c` to specify location

### Application not found
- Verify application is installed
- Check bundle ID: `osascript -e 'id of application "App Name"'`
- Use correct bundle ID with `-b` option

### Config file not found
- Check the [Config File Resolution](#config-file-resolution) order
- Specify custom location with `-c /path/to/config.jsonc`
- Use absolute paths for clarity

### Changes not taking effect
- Try rebuilding Launch Services database:
  ```bash
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
  ```
- Restart Finder: `killall Finder`
- Log out and log back in

### JSONC parsing issues
- Ensure file is valid JSONC format
- Check for syntax errors (matching brackets, quotes)
- Comments must use `//` format
- Try installing `jq` for better parsing: `brew install jq`

## 📝 Notes

- Changes take effect immediately
- Existing open files may need to be re-opened
- The script provides colored output with success/failure indicators
- Summary statistics are shown at the end

## 🔄 Workflow Examples

### Setup for Cursor (Default)
```bash
cd ~/Downloads  # Or wherever you saved the files
chmod +x doMyDuti.sh
./doMyDuti.sh
```

### Setup for VS Code
```bash
./doMyDuti.sh -b com.microsoft.VSCode
```

### Setup with XDG_CONFIG_HOME
```bash
mkdir -p ~/.config/doMyDuti
cp doMyDuti.jsonc ~/.config/doMyDuti/
./doMyDuti.sh  # Automatically finds config
```

### Setup with User Home Config
```bash
cp doMyDuti.jsonc ~/.doMyDuti.jsonc
./doMyDuti.sh  # Automatically finds config
```

---

**Created:** 16/11/2025  
**Platform:** macOS  
**Requirements:** macOS with `duti` installed (`brew install duti`)
