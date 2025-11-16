#!/bin/bash

# doMyDuti.sh Installation Script
# Install via: curl -fsSL https://raw.githubusercontent.com/tsdevau/doMyDuti/main/install.sh | bash

set -e

# Repository details
REPO_URL="https://raw.githubusercontent.com/tsdevau/doMyDuti/main"
SCRIPT_NAME="doMyDuti.sh"
CONFIG_NAME="doMyDuti.jsonc"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  doMyDuti.sh - File Handler Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if running via curl | bash
if [[ -t 0 ]]; then
    echo -e "${BLUE}Installing doMyDuti.sh from remote repository...${NC}"
else
    echo -e "${BLUE}Installing doMyDuti.sh via curl | bash...${NC}"
fi
echo ""

# Check if duti is installed
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v duti &> /dev/null; then
    echo -e "${YELLOW}⚠ duti is not installed${NC}"
    echo -e "${BLUE}Installing duti via Homebrew...${NC}"

    if ! command -v brew &> /dev/null; then
        echo -e "${RED}✗ Homebrew is not installed${NC}"
        echo -e "${YELLOW}Please install Homebrew first: https://brew.sh${NC}"
        echo -e "${YELLOW}Then run: curl -fsSL ${REPO_URL}/install.sh | bash${NC}"
        exit 1
    fi

    brew install duti
    echo -e "${GREEN}✓ duti installed${NC}"
else
    echo -e "${GREEN}✓ duti is already installed${NC}"
fi

echo ""

# Determine installation directory for the script
echo -e "${BLUE}Determining installation location for script...${NC}"

# Use INSTALL_DIR if set (for testing), otherwise find suitable location
if [[ -z "$INSTALL_DIR" ]]; then
    # Try to find a suitable location in PATH
    for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
        if [[ -d "$dir" ]] && [[ ":$PATH:" == *":$dir:"* ]]; then
            INSTALL_DIR="$dir"
            break
        fi
    done

    # If no suitable directory found, create ~/.local/bin
    if [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR="$HOME/.local/bin"
    fi
fi

echo -e "${BLUE}Creating directory: ${INSTALL_DIR}${NC}"
mkdir -p "$INSTALL_DIR"

echo -e "${GREEN}✓ Script will be installed to: ${INSTALL_DIR}${NC}"
echo ""

# Determine config file location
echo -e "${BLUE}Determining config file location...${NC}"

if [[ -n "$XDG_CONFIG_HOME" ]]; then
    CONFIG_DIR="$XDG_CONFIG_HOME/doMyDuti"
    CONFIG_FILE="$CONFIG_DIR/doMyDuti.jsonc"
else
    CONFIG_FILE="$HOME/.doMyDuti.jsonc"
    CONFIG_DIR=""
fi

echo -e "${GREEN}✓ Config will be installed to: ${CONFIG_FILE}${NC}"
echo ""

# Download and install the script
echo -e "${BLUE}Downloading and installing script...${NC}"

if ! curl -fsSL "${REPO_URL}/${SCRIPT_NAME}" -o "${INSTALL_DIR}/${SCRIPT_NAME}"; then
    echo -e "${RED}✗ Failed to download ${SCRIPT_NAME}${NC}"
    exit 1
fi

chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
echo -e "${GREEN}✓ Downloaded and made executable: ${INSTALL_DIR}/${SCRIPT_NAME}${NC}"

# Download and install the config file
echo ""
echo -e "${BLUE}Downloading and installing config...${NC}"

if [[ -n "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR"
fi

if ! curl -fsSL "${REPO_URL}/${CONFIG_NAME}" -o "${CONFIG_FILE}"; then
    echo -e "${RED}✗ Failed to download ${CONFIG_NAME}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Downloaded config: ${CONFIG_FILE}${NC}"

# Check if installation directory is in PATH
echo ""
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo -e "${GREEN}✓ ${INSTALL_DIR} is in your PATH${NC}"
    echo -e "${GREEN}You can now run: ${BLUE}doMyDuti.sh${NC}"
else
    echo -e "${YELLOW}⚠ ${INSTALL_DIR} is not in your PATH${NC}"
    echo -e "${BLUE}To add it permanently, add this to your ~/.zshrc or ~/.bashrc:${NC}"
    echo -e "${YELLOW}export PATH=\"\$PATH:${INSTALL_DIR}\"${NC}"
    echo ""
    echo -e "${BLUE}For this session, you can run using full path:${NC}"
    echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Installation Complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Quick test:${NC}"
echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh -h${NC}"
echo ""
echo -e "${BLUE}To configure Cursor (default):${NC}"
echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh${NC}"
echo ""
echo -e "${BLUE}To configure VS Code:${NC}"
echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh -b com.microsoft.VSCode${NC}"
echo ""
echo -e "${BLUE}To configure another editor:${NC}"
echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh -b <bundle-id>${NC}"
echo ""
echo -e "${BLUE}Find bundle IDs with:${NC}"
echo -e "${YELLOW}osascript -e 'id of application \"App Name\"'${NC}"
echo ""

# Offer to run the configuration immediately
if [[ -t 0 ]]; then
    echo -e "${BLUE}Would you like to configure file handlers now?${NC}"
    echo -e "${YELLOW}This will set Cursor as the default handler for code files.${NC}"
    read -p "Run configuration now? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Running configuration...${NC}"
        echo ""
        "${INSTALL_DIR}/${SCRIPT_NAME}"
    fi
fi
