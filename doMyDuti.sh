#!/bin/bash

# Script to set default application handler for code file extensions
# Writes Launch Services preferences directly to avoid macOS 26.4+ confirmation dialogs
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

Set default application handler for code file extensions on macOS.

OPTIONS:
    -c, --config FILE       Config file path
    -b, --bundleId ID       Application bundle ID
    -i, --immediate        Apply via duti with auto-accepted prompts (macOS 26.4+)
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
USE_IMMEDIATE=false
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
        -i|--immediate)
            USE_IMMEDIATE=true
            shift
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

# Function to ensure all configured extensions have a registered UTI in Launch Services.
# Generates a minimal app bundle with UTImportedTypeDeclarations and registers it,
# so that LSSetDefaultRoleHandlerForContentType (used by duti) doesn't return kLSUnknownTypeErr.
ensure_utis_registered() {
    local config_file="$1"
    local helper_app="/tmp/DoMyDutiHelper.app"
    local contents_dir="${helper_app}/Contents"

    mkdir -p "$contents_dir"

    # Build one UTImportedTypeDeclaration dict per extension
    local uti_declarations=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        read -r extension role <<< "$line"
        local ext_clean="${extension#.}"          # strip leading dot
        local uti_id="com.domduti.type.${ext_clean}"

        uti_declarations+="        <dict>
            <key>UTTypeIdentifier</key>
            <string>${uti_id}</string>
            <key>UTTypeDescription</key>
            <string>${ext_clean} file</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>${ext_clean}</string>
                </array>
            </dict>
        </dict>
"
    done < <(parse_jsonc_config "$config_file")

    cat > "${contents_dir}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.domduti.helper</string>
    <key>CFBundleName</key>
    <string>DoMyDutiHelper</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>UTImportedTypeDeclarations</key>
    <array>
${uti_declarations}    </array>
</dict>
</plist>
PLIST

    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$helper_app" 2>/dev/null
    echo -e "${CYAN}ℹ Registered UTIs for all configured extensions${NC}"
    echo ""
}

# Ensure UTIs exist before mapping handlers
ensure_utis_registered "$CONFIG_FILE"

# Apply handlers by updating Launch Services preferences in one batch.
# macOS 26.4+ shows a confirmation dialog for every LSSetDefaultRoleHandler call
# (what duti uses). Writing LSHandlers via UserDefaults avoids those prompts entirely.
apply_handlers_via_plist() {
    local bundle_id="$1"
    local config_file="$2"
    local entries_file
    entries_file=$(mktemp)

    parse_jsonc_config "$config_file" > "$entries_file"

    swift - "$bundle_id" "$entries_file" << 'SWIFT'
import Foundation

let bundleId = CommandLine.arguments[1]
let entriesPath = CommandLine.arguments[2]
let entriesURL = URL(fileURLWithPath: entriesPath)
let suiteName = "com.apple.LaunchServices/com.apple.launchservices.secure"

let roleKeys: [String: String] = [
    "all": "LSHandlerRoleAll",
    "viewer": "LSHandlerRoleViewer",
    "editor": "LSHandlerRoleEditor",
    "shell": "LSHandlerRoleShell",
]

guard let defaults = UserDefaults(suiteName: suiteName) else {
    fputs("ERROR\tCould not open Launch Services preferences\n", stderr)
    exit(1)
}

var handlers = defaults.array(forKey: "LSHandlers") as? [[String: Any]] ?? []
let modificationDate = Int(Date().timeIntervalSinceReferenceDate)

func handlerMatches(_ entry: [String: Any], contentType: String, roleKey: String) -> Bool {
    entry["LSHandlerContentType"] as? String == contentType && entry[roleKey] != nil
}

guard let entriesData = try? String(contentsOf: entriesURL, encoding: .utf8) else {
    fputs("ERROR\tCould not read extension entries\n", stderr)
    exit(1)
}

var failCount = 0

for rawLine in entriesData.split(separator: "\n") {
    let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
    if line.isEmpty { continue }

    let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
    guard parts.count == 2 else {
        print("SKIP\t\(line)")
        continue
    }

    let extensionValue = parts[0]
    let role = parts[1]
    guard let roleKey = roleKeys[role.lowercased()] else {
        print("FAIL\t\(extensionValue)\tunknown role: \(role)")
        failCount += 1
        continue
    }

    let extClean = extensionValue.hasPrefix(".")
        ? String(extensionValue.dropFirst())
        : extensionValue
    if extClean.isEmpty {
        print("SKIP\t\(extensionValue)")
        continue
    }

    let contentType = "com.domduti.type.\(extClean)"
    handlers.removeAll { handlerMatches($0, contentType: contentType, roleKey: roleKey) }
    handlers.append([
        "LSHandlerContentType": contentType,
        "LSHandlerModificationDate": modificationDate,
        "LSHandlerPreferredVersions": [roleKey: "-"],
        roleKey: bundleId,
    ])
    print("OK\t\(extensionValue)")
}

defaults.set(handlers, forKey: "LSHandlers")
defaults.synchronize()
exit(failCount == 0 ? 0 : 1)
SWIFT

    local swift_status=$?
    rm -f "$entries_file"

    if [[ $swift_status -ne 0 ]]; then
        echo -e "${RED}✗ Error: Failed to update Launch Services preferences${NC}"
        exit 1
    fi
}

# macOS 26.4+ confirmation prompts for each duti call. Optional fallback that
# auto-clicks "Use" so the script can finish without manual interaction.
start_dialog_auto_acceptor() {
    # nohup prevents command substitution ($( ... )) from waiting on this job.
    nohup osascript << 'APPLESCRIPT' >/dev/null 2>&1 &
        tell application "System Events"
            repeat
                try
                    if exists (process "CoreServicesUIAgent") then
                        tell process "CoreServicesUIAgent"
                            repeat with promptWindow in windows
                                try
                                    if exists (button "Use" of promptWindow) then
                                        click button "Use" of promptWindow
                                    end if
                                end try
                            end repeat
                        end tell
                    end if
                end try
                delay 0.05
            end repeat
        end tell
APPLESCRIPT
    echo $!
}

stop_dialog_auto_acceptor() {
    local clicker_pid="$1"
    if [[ -n "$clicker_pid" ]]; then
        kill "$clicker_pid" 2>/dev/null || true
        wait "$clicker_pid" 2>/dev/null || true
    fi
}

apply_handlers_via_duti() {
    local bundle_id="$1"
    local config_file="$2"
    local clicker_pid=""
    local current=0
    local total
    total=$(parse_jsonc_config "$config_file" | wc -l | tr -d ' ')

    if ! command -v duti &> /dev/null; then
        echo -e "${RED}✗ Error: duti is not installed (required for --immediate)${NC}" >&2
        echo -e "${YELLOW}  Install it with: brew install duti${NC}" >&2
        exit 1
    fi

    cleanup_duti_clicker() {
        stop_dialog_auto_acceptor "$clicker_pid"
    }
    trap cleanup_duti_clicker EXIT INT TERM

    echo -e "${CYAN}ℹ Starting dialog auto-acceptor...${NC}" >&2
    clicker_pid=$(start_dialog_auto_acceptor)
    echo -e "${CYAN}ℹ Applying ${total} handlers via duti...${NC}" >&2

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        read -r extension role <<< "$line"
        if [[ -z "$extension" ]] || [[ -z "$role" ]]; then
            echo -e "SKIP\t${line}"
            continue
        fi

        current=$((current + 1))
        echo -e "${CYAN}  [${current}/${total}]${NC} Setting ${YELLOW}${extension}${NC}..." >&2

        if duti -s "$bundle_id" "$extension" "$role" 2>/dev/null; then
            echo -e "OK\t${extension}"
        else
            echo -e "FAIL\t${extension}\tduti returned an error"
        fi
    done < <(parse_jsonc_config "$config_file")

    trap - EXIT INT TERM
    stop_dialog_auto_acceptor "$clicker_pid"
}

macos_major_minor() {
    sw_vers -productVersion | awk -F. '{print $1 "." $2}'
}

needs_logout_for_handlers() {
    local version
    version=$(macos_major_minor)
    awk -v v="$version" 'BEGIN {
        split(v, parts, ".")
        major = parts[1] + 0
        minor = parts[2] + 0
        exit (major > 26 || (major == 26 && minor >= 4)) ? 0 : 1
    }'
}

# Count total entries
TOTAL_ENTRIES=$(parse_jsonc_config "$CONFIG_FILE" | wc -l | tr -d ' ')
echo -e "${BLUE}Found ${TOTAL_ENTRIES} file extension mappings to configure${NC}"
if [[ "$USE_IMMEDIATE" == true ]]; then
    echo -e "${CYAN}ℹ Using duti with auto-accepted prompts (--immediate)${NC}"
    echo -e "${YELLOW}  System dialogs may flash briefly; grant Automation access if prompted${NC}"
else
    echo -e "${CYAN}ℹ Using batch Launch Services update (no confirmation dialogs)${NC}"
fi
echo ""

# Process the config file
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

if [[ "$USE_IMMEDIATE" == true ]]; then
    APPLY_HANDLERS=(apply_handlers_via_duti)
else
    APPLY_HANDLERS=(apply_handlers_via_plist)
fi

while IFS=$'\t' read -r status extension detail; do
    case "$status" in
        OK)
            echo -e "${GREEN}✓${NC} Set ${YELLOW}${extension}${NC} → ${APP_NAME}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            ;;
        FAIL)
            echo -e "${RED}✗${NC} Failed to set ${YELLOW}${extension}${NC} (${detail})"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
        SKIP)
            echo -e "${YELLOW}⚠ Skipping malformed entry: ${extension}${NC}"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            ;;
    esac
done < <("${APPLY_HANDLERS[@]}" "$BUNDLE_ID" "$CONFIG_FILE")

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
if [[ "$USE_IMMEDIATE" == true ]]; then
    echo -e "${YELLOW}Note:${NC} Changes should take effect immediately."
    echo -e "      Existing files may need to be re-opened."
elif needs_logout_for_handlers; then
    echo -e "${YELLOW}Note:${NC} On macOS 26.4+, log out and back in once for all handlers to take effect."
    echo -e "      Or re-run with ${CYAN}--immediate${NC} to apply live via duti (dialogs auto-accepted)."
else
    echo -e "${YELLOW}Note:${NC} Changes take effect immediately."
    echo -e "      Existing files may need to be re-opened."
fi
echo ""