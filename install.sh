#!/bin/bash

# Installation helper for doMyDuti.sh
# This script helps you set up the file handler configuration system

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  File Handler Configuration - Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if duti is installed
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v duti &> /dev/null; then
    echo -e "${YELLOW}⚠ duti is not installed${NC}"
    echo -e "${BLUE}Installing duti via Homebrew...${NC}"
    
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}✗ Homebrew is not installed${NC}"
        echo -e "${YELLOW}Please install Homebrew first: https://brew.sh${NC}"
        exit 1
    fi
    
    brew install duti
    echo -e "${GREEN}✓ duti installed${NC}"
else
    echo -e "${GREEN}✓ duti is already installed${NC}"
fi

echo ""

# Determine installation location
echo -e "${BLUE}Where would you like to install the script?${NC}"
echo -e "  1) ${GREEN}~/.local/bin${NC} (recommended if ~/bin is in your PATH)"
echo -e "  2) ${GREEN}~/scripts${NC}"
echo -e "  3) ${GREEN}~/bin${NC}"
echo -e "  4) ${GREEN}Custom location${NC}"
echo ""
read -p "Choose [1-4]: " choice

case $choice in
    1)
        INSTALL_DIR="$HOME/.local/bin"
        ;;
    2)
        INSTALL_DIR="$HOME/scripts"
        ;;
    3)
        INSTALL_DIR="$HOME/bin"
        ;;
    4)
        read -p "Enter custom path: " INSTALL_DIR
        INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"  # Expand tilde
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Create directory if it doesn't exist
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${BLUE}Creating directory: ${INSTALL_DIR}${NC}"
    mkdir -p "$INSTALL_DIR"
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy files
echo ""
echo -e "${BLUE}Installing files to ${INSTALL_DIR}...${NC}"

if [[ -f "$SCRIPT_DIR/doMyDuti.sh" ]]; then
    cp "$SCRIPT_DIR/doMyDuti.sh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/doMyDuti.sh"
    echo -e "${GREEN}✓ Copied doMyDuti.sh${NC}"
else
    echo -e "${RED}✗ doMyDuti.sh not found in current directory${NC}"
    exit 1
fi

if [[ -f "$SCRIPT_DIR/cursor_duti_config.txt" ]]; then
    cp "$SCRIPT_DIR/cursor_duti_config.txt" "$INSTALL_DIR/"
    echo -e "${GREEN}✓ Copied cursor_duti_config.txt${NC}"
else
    echo -e "${YELLOW}⚠ cursor_duti_config.txt not found (you'll need to provide a config file)${NC}"
fi

# Check if installation directory is in PATH
echo ""
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo -e "${GREEN}✓ ${INSTALL_DIR} is in your PATH${NC}"
    echo -e "${GREEN}You can now run: ${BLUE}doMyDuti.sh${NC}"
else
    echo -e "${YELLOW}⚠ ${INSTALL_DIR} is not in your PATH${NC}"
    echo -e "${BLUE}To add it, add this to your ~/.zshrc:${NC}"
    echo -e "${YELLOW}export PATH=\"\$PATH:${INSTALL_DIR}\"${NC}"
    echo ""
    echo -e "${BLUE}Or run using full path:${NC}"
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
echo -e "${BLUE}To configure Cursor:${NC}"
echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh${NC}"
echo ""
echo -e "${BLUE}To configure VS Code:${NC}"
echo -e "${YELLOW}${INSTALL_DIR}/doMyDuti.sh -b com.microsoft.VSCode${NC}"
echo ""
