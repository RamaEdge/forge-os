#!/bin/bash
# ForgeOS Version Management Script
# Parses packages.txt and exports version variables
# Implements THE-121 (Optimize Package Downloads)

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$PROJECT_ROOT/packages.txt"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" >&2
}

# Check if packages.txt exists
if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "Error: packages.txt not found at $PACKAGES_FILE" >&2
    exit 1
fi

# Parse packages.txt and export variables
parse_packages() {
    log_info "Loading package versions from $PACKAGES_FILE"
    
    # Read packages.txt line by line
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Parse package lines (name,version,url)
        if [[ "$line" =~ ^([^,]+),([^,]+),([^,]+)$ ]]; then
            local package_name="${BASH_REMATCH[1]}"
            local package_version="${BASH_REMATCH[2]}"
            local package_url="${BASH_REMATCH[3]}"
            
            # Convert package name to uppercase and replace hyphens with underscores
            local var_name=$(echo "$package_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
            
            # Export version variable
            export "${var_name}_VERSION"="$package_version"
            export "${var_name}_URL"="$package_url"
            
            # Special handling for version components
            if [[ "$package_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
                export "${var_name}_VERSION_MAJOR"="${BASH_REMATCH[1]}"
                export "${var_name}_VERSION_MINOR"="${BASH_REMATCH[2]}"
                export "${var_name}_VERSION_PATCH"="${BASH_REMATCH[3]}"
            fi
            
            log_success "Loaded $package_name version $package_version"
        fi
        
        # Parse configuration lines (KEY=VALUE)
        if [[ "$line" =~ ^([A-Z_]+)=(.+)$ ]]; then
            local config_key="${BASH_REMATCH[1]}"
            local config_value="${BASH_REMATCH[2]}"
            
            export "$config_key"="$config_value"
            log_success "Loaded config $config_key=$config_value"
        fi
        
    done < "$PACKAGES_FILE"
    
    log_success "All package versions loaded successfully"
}

# Main function
main() {
    if [[ "${1:-}" == "--verbose" ]]; then
        parse_packages
    else
        # Silent mode - just export variables
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
                continue
            fi
            
            if [[ "$line" =~ ^([^,]+),([^,]+),([^,]+)$ ]]; then
                local package_name="${BASH_REMATCH[1]}"
                local package_version="${BASH_REMATCH[2]}"
                local package_url="${BASH_REMATCH[3]}"
                
                local var_name=$(echo "$package_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
                export "${var_name}_VERSION"="$package_version"
                export "${var_name}_URL"="$package_url"
                
                if [[ "$package_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
                    export "${var_name}_VERSION_MAJOR"="${BASH_REMATCH[1]}"
                    export "${var_name}_VERSION_MINOR"="${BASH_REMATCH[2]}"
                    export "${var_name}_VERSION_PATCH"="${BASH_REMATCH[3]}"
                fi
            fi
            
            if [[ "$line" =~ ^([A-Z_]+)=(.+)$ ]]; then
                local config_key="${BASH_REMATCH[1]}"
                local config_value="${BASH_REMATCH[2]}"
                export "$config_key"="$config_value"
            fi
            
        done < "$PACKAGES_FILE"
    fi
}

# Run main function
main "$@"
