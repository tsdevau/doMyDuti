#!/bin/bash

# Script to set default application handler for code file extensions
# Uses duti to modify Launch Services database
# Created: $(date +"%d/%m/%Y %H:%M")

set -e  # Exit on error

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG_FILE="${SCRIPT_DIR}/doMyDuti.jsonc"
DEFAULT_BUNDLE_ID="com.todesktop.230313mzl4w4u92"

# Parse command-line arguments
CONFIG_FILE=""
USER_BUNDLE_ID=""
BUNDLE_ID=""

# Function to resolve config file path
resolve_config_file() {
    local user_specified="$1"
    
    # 1. Use config file passed with --config or -c flag
    if [[ -n "$user_specified" ]]; then
        echo "$user_specified"
        return
    fi
    
    # 2. Look for config file in $XDG_CONFIG_HOME/doMyDuti/doMyDuti.jsonc
    if [[ -n "$XDG_CONFIG_HOME" ]] && [[ -f "${XDG_CONFIG_HOME}/doMyDuti/doMyDuti.jsonc" ]]; then
        echo "${XDG_CONFIG_HOME}/doMyDuti/doMyDuti.jsonc"
        return
    fi
    
    # 3. Look for config file in ~/.doMyDuti.jsonc
    if [[ -f "${HOME}/.doMyDuti.jsonc" ]]; then
        echo "${HOME}/.doMyDuti.jsonc"
        return
    fi
    
    # 4. Use script default
    echo "${DEFAULT_CONFIG_FILE}"
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Set default application handler for code file extensions using duti.

OPTIONS:
    -c, --config FILE       Config file path
    -b, --bundleId ID       Application bundle ID
    -h, --help             Show this help message

BUNDLE ID RESOLUTION ORDER:
    1. CLI parameter (-b/--bundleId)
    2. Config file in \$XDG_CONFIG_HOME/doMyDuti/doMyDuti.jsonc
    3. Config file in ~/.doMyDuti.jsonc
    4. Script default: ${DEFAULT_BUNDLE_ID}

CONFIG FILE RESOLUTION ORDER:
    1. File specified with -c/--config flag
    2. \$XDG_CONFIG_HOME/doMyDuti/doMyDuti.jsonc
    3. ~/.doMyDuti.jsonc
    4. Script directory default: ${DEFAULT_CONFIG_FILE}

EXAMPLES:
    # Use default resolution (checks XDG_CONFIG_HOME, ~/.doMyDuti.jsonc, then script default)
    $(basename "$0")

    # Use custom config file
    $(basename "$0") -c ~/my_config.jsonc

    # Use different application (e.g., VS Code)
    $(basename "$0") -b com.microsoft.VSCode

    # Combine both
    $(basename "$0") -c ~/my_config.jsonc -b com.microsoft.VSCode

CONFIG FILE FORMAT:
    JSONC format: Object with bundleId and extensions array
    Example:
    {
      "bundleId": "com.todesktop.230313mzl4w4u92",
      "extensions": [
        [".ts", "all"],
        [".js", "all"],
        [".py", "all"]
      ]
    }
    
    Lines starting with // are comments and will be ignored.
    The bundleId field is optional and will be used if not specified via CLI.

EOF
    exit 0
}

# Parse arguments
USER_CONFIG_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            USER_CONFIG_FILE="$2"
            shift 2
            ;;
        -b|--bundleId)
            USER_BUNDLE_ID="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Resolve config file path
CONFIG_FILE=$(resolve_config_file "$USER_CONFIG_FILE")

# Function to extract bundle_id from JSONC config file
extract_bundle_id_from_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # Try using jq if available (preferred method)
    if command -v jq &> /dev/null; then
        # Strip comments and extract bundleId
        local bundle_id=$(sed 's|//.*||' "$config_file" | jq -r '.bundleId // empty' 2>/dev/null)
        if [[ -n "$bundle_id" ]] && [[ "$bundle_id" != "null" ]]; then
            echo "$bundle_id"
            return 0
        fi
    fi
    
    # Fallback: Simple parser for JSONC format
    while IFS= read -r line; do
        # Strip comments
        line=$(echo "$line" | sed 's|//.*||' | sed 's|#.*||')
        # Trim whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Match: "bundleId": "value" or 'bundleId': 'value'
        local bundle_id_regex="^[\"']bundleId[\"'][[:space:]]*:[[:space:]]*[\"']([^\"']+)[\"']"
        if [[ "$line" =~ $bundle_id_regex ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done < "$config_file"
    
    return 1
}

# Function to resolve bundle ID in priority order
resolve_bundle_id() {
    # 1. CLI parameter (highest priority)
    if [[ -n "$USER_BUNDLE_ID" ]]; then
        echo "$USER_BUNDLE_ID"
        return
    fi
    
    # 2. Config file in XDG_CONFIG_HOME
    if [[ -n "$XDG_CONFIG_HOME" ]] && [[ -f "${XDG_CONFIG_HOME}/doMyDuti/doMyDuti.jsonc" ]]; then
        local bundle_id=$(extract_bundle_id_from_config "${XDG_CONFIG_HOME}/doMyDuti/doMyDuti.jsonc")
        if [[ -n "$bundle_id" ]]; then
            echo "$bundle_id"
            return
        fi
    fi
    
    # 3. Config file in user root
    if [[ -f "${HOME}/.doMyDuti.jsonc" ]]; then
        local bundle_id=$(extract_bundle_id_from_config "${HOME}/.doMyDuti.jsonc")
        if [[ -n "$bundle_id" ]]; then
            echo "$bundle_id"
            return
        fi
    fi
    
    # 4. Script default config file (if it exists and hasn't been checked yet)
    if [[ -f "$DEFAULT_CONFIG_FILE" ]] && \
       [[ "$DEFAULT_CONFIG_FILE" != "${XDG_CONFIG_HOME}/doMyDuti/doMyDuti.jsonc" ]] && \
       [[ "$DEFAULT_CONFIG_FILE" != "${HOME}/.doMyDuti.jsonc" ]]; then
        local bundle_id=$(extract_bundle_id_from_config "$DEFAULT_CONFIG_FILE")
        if [[ -n "$bundle_id" ]]; then
            echo "$bundle_id"
            return
        fi
    fi
    
    # 5. Script default bundle ID (lowest priority)
    echo "${DEFAULT_BUNDLE_ID}"
}

# Resolve bundle ID
BUNDLE_ID=$(resolve_bundle_id)

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Default File Handler Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Bundle ID:${NC}    ${BUNDLE_ID}"
echo -e "${CYAN}Config File:${NC} ${CONFIG_FILE}"
echo ""

# Check if duti is installed
if ! command -v duti &> /dev/null; then
    echo -e "${RED}✗ Error: duti is not installed${NC}"
    echo -e "${YELLOW}  Install it with: brew install duti${NC}"
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}✗ Error: Config file not found: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}  Config file resolution tried:${NC}"
    if [[ -n "$USER_CONFIG_FILE" ]]; then
        echo -e "${YELLOW}    1. User-specified: $USER_CONFIG_FILE${NC}"
    fi
    if [[ -n "$XDG_CONFIG_HOME" ]]; then
        echo -e "${YELLOW}    2. XDG_CONFIG_HOME: ${XDG_CONFIG_HOME}/doMyDuti/doMyDuti.jsonc${NC}"
    else
        echo -e "${YELLOW}    2. XDG_CONFIG_HOME: (not set)${NC}"
    fi
    echo -e "${YELLOW}    3. Home directory: ~/.doMyDuti.jsonc${NC}"
    echo -e "${YELLOW}    4. Script default: ${DEFAULT_CONFIG_FILE}${NC}"
    echo -e "${YELLOW}  Please create a config file or specify one with -c option${NC}"
    exit 1
fi

# Function to parse JSONC config file
parse_jsonc_config() {
    local config_file="$1"
    
    # Try using jq if available (preferred method)
    if command -v jq &> /dev/null; then
        # Strip comments and parse JSON - handle both array and object formats
        # First try object format with extensions array
        local result=$(sed 's|//.*||' "$config_file" | jq -r '.extensions[]? | "\(.[0]) \(.[1])"' 2>/dev/null)
        if [[ -n "$result" ]]; then
            echo "$result"
            return 0
        fi
        # Fallback to root array format
        sed 's|//.*||' "$config_file" | jq -r '.[] | "\(.[0]) \(.[1])"' 2>/dev/null && return 0
    fi
    
    # Fallback: Simple parser for JSONC format
    # Handles format: {"bundleId": "...", "extensions": [[".ext", "role"], ...]}
    local in_extensions=false
    while IFS= read -r line; do
        # Strip comments
        line=$(echo "$line" | sed 's|//.*||' | sed 's|#.*||')
        # Trim whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Check if we're entering the extensions array
        if [[ "$line" =~ ^[\"']extensions[\"'][[:space:]]*:[[:space:]]*\[ ]]; then
            in_extensions=true
            # Check if there's an entry on the same line
            local extension_entry_regex="\[[\"']([^\"']+)[\"'][[:space:]]*,[[:space:]]*[\"']([^\"']+)[\"']\]"
            if [[ "$line" =~ $extension_entry_regex ]]; then
                echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
            fi
            continue
        elif [[ "$line" =~ ^[\"']extensions[\"'][[:space:]]*: ]]; then
            in_extensions=true
            continue
        fi
        
        # Skip bundleId line
        if [[ "$line" =~ ^[\"']bundleId[\"'] ]]; then
            continue
        fi
        
        # Skip outer brackets and braces (but track when we exit extensions array)
        if [[ "$line" == "[" ]] && [[ "$in_extensions" == false ]]; then
            continue
        fi
        if [[ "$line" == "]" ]]; then
            in_extensions=false
            continue
        fi
        [[ "$line" == "{" ]] && continue
        [[ "$line" == "}" ]] && { in_extensions=false; continue; }
        
        # Only process array entries when inside extensions array
        if [[ "$in_extensions" == true ]]; then
            # Extract extension and role from array entries like [".ext", "role"] or [".ext", "role"],
            # Match: ["...", "..."] or ['...', '...'] with optional trailing comma
            local array_entry_regex="^\[[\"']([^\"']+)[\"'][[:space:]]*,[[:space:]]*[\"']([^\"']+)[\"']\]\,?"
            if [[ "$line" =~ $array_entry_regex ]]; then
                local extension="${BASH_REMATCH[1]}"
                local role="${BASH_REMATCH[2]}"
                
                if [[ -n "$extension" ]] && [[ -n "$role" ]]; then
                    echo "$extension $role"
                fi
            fi
        fi
    done < "$config_file"
}

# Try to get the application name from bundle ID
APP_NAME=$(osascript -e "try
    name of application id \"${BUNDLE_ID}\"
on error
    \"Unknown\"
end try" 2>/dev/null || echo "Unknown")

if [[ "$APP_NAME" == "Unknown" ]]; then
    echo -e "${YELLOW}⚠ Warning: Application with bundle ID '${BUNDLE_ID}' not found${NC}"
    echo -e "${YELLOW}  Continuing anyway...${NC}"
    echo ""
else
    echo -e "${GREEN}✓ Found application: ${APP_NAME}${NC}"
    echo ""
fi

# Count total entries
TOTAL_ENTRIES=$(parse_jsonc_config "$CONFIG_FILE" | wc -l | tr -d ' ')
echo -e "${BLUE}Found ${TOTAL_ENTRIES} file extension mappings to configure${NC}"
echo ""

# Process the config file
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Parse the line: extension role
    read -r extension role <<< "$line"
    
    # Validate the line has both components
    if [[ -z "$extension" ]] || [[ -z "$role" ]]; then
        echo -e "${YELLOW}⚠ Skipping malformed entry: $line${NC}"
        ((SKIP_COUNT++))
        continue
    fi
    
    # Set the default handler using duti
    if duti -s "$BUNDLE_ID" "$extension" "$role" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Set ${YELLOW}${extension}${NC} → ${APP_NAME}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗${NC} Failed to set ${YELLOW}${extension}${NC}"
        ((FAIL_COUNT++))
    fi
done < <(parse_jsonc_config "$CONFIG_FILE")

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Configuration Complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}Successful:${NC} $SUCCESS_COUNT"
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "  ${RED}Failed:${NC}     $FAIL_COUNT"
fi
if [[ $SKIP_COUNT -gt 0 ]]; then
    echo -e "  ${YELLOW}Skipped:${NC}    $SKIP_COUNT"
fi
echo ""
echo -e "${YELLOW}Note:${NC} Changes take effect immediately."
echo -e "      Existing files may need to be re-opened."
echo ""
