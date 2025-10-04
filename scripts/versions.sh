#!/bin/bash
# ForgeOS JSON-based Version Management Script
# Parses packages.json and build.json
# Implements THE-121 (Optimize Package Downloads)

set -e

# Script configuration
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
else
    PROJECT_ROOT="$(pwd)"
fi

PACKAGES_JSON="$PROJECT_ROOT/packages.json"
BUILD_JSON="$PROJECT_ROOT/build.json"

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

# Check if jq is available
check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        echo "Please install jq: brew install jq (macOS) or apt-get install jq (Ubuntu)" >&2
        exit 1
    fi
}

# Check if required files exist
check_files() {
    local missing_files=()
    
    if [[ ! -f "$PACKAGES_JSON" ]]; then
        missing_files+=("packages.json")
    fi
    
    if [[ ! -f "$BUILD_JSON" ]]; then
        missing_files+=("build.json")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "Error: Missing required files: ${missing_files[*]}" >&2
        echo "Please ensure all files exist in the project root" >&2
        exit 1
    fi
}

# Parse packages from packages.json
parse_packages() {
    log_info "Loading package data from $PACKAGES_JSON"
    
    # Get all package names and versions
    local packages=$(jq -r '.packages | to_entries[] | .key as $category | .value | to_entries[] | "\(.key) \(.value.version) \($category)"' "$PACKAGES_JSON")
    
    while IFS= read -r line; do
        local package_name=$(echo "$line" | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        local package_version=$(echo "$line" | cut -d' ' -f2)
        local package_category=$(echo "$line" | cut -d' ' -f3)
        
        # Export version variable
        export "${package_name}_VERSION"="$package_version"
        export "${package_name}_CATEGORY"="$package_category"
        
        log_success "Loaded $package_name version $package_version (category: $package_category)"
    done <<< "$packages"
}

# Parse URLs from packages.json
parse_urls() {
    log_info "Loading package URLs from $PACKAGES_JSON"
    
    # Get all package URLs
    local urls=$(jq -r '.packages | to_entries[] | .key as $category | .value | to_entries[] | "\(.key) \(.value.url)"' "$PACKAGES_JSON")
    
    while IFS= read -r line; do
        local package_name=$(echo "$line" | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        local url_template=$(echo "$line" | cut -d' ' -f2-)
        
        # Get the version for this package
        local version_var="${package_name}_VERSION"
        local package_version=$(eval echo \$${version_var})
        
        # Replace {version} placeholder with actual version using sed
        local resolved_url=$(echo "$url_template" | sed "s/{version}/$package_version/g")
        
        # Export resolved URL
        export "${package_name}_URL"="$resolved_url"
        
        log_success "Loaded ${package_name}_URL: $resolved_url"
    done <<< "$urls"
}

# Parse build configuration from build.json
parse_build_config() {
    log_info "Loading build configuration from $BUILD_JSON"
    
    # Parse build directories
    local build_dir=$(jq -r '.build.directories.build' "$BUILD_JSON")
    local output_dir=$(jq -r '.build.directories.output' "$BUILD_JSON")
    local repo_dir=$(jq -r '.build.directories.repo' "$BUILD_JSON")
    
    export BUILD_DIR="$build_dir"
    export OUTPUT_DIR="$output_dir"
    export REPO_DIR="$repo_dir"
    
    # Parse architecture
    local arch=$(jq -r '.build.architecture.default' "$BUILD_JSON")
    local target_musl=$(jq -r '.build.architecture.targets.musl' "$BUILD_JSON")
    local target_gnu=$(jq -r '.build.architecture.targets.gnu' "$BUILD_JSON")
    
    export ARCH="$arch"
    export TARGET_MUSL="$target_musl"
    export TARGET_GNU="$target_gnu"
    
    # Parse repository config
    local repo_name=$(jq -r '.build.repository.name' "$BUILD_JSON")
    local repo_version=$(jq -r '.build.repository.version' "$BUILD_JSON")
    local repo_arch=$(jq -r '.build.repository.arch' "$BUILD_JSON")
    
    export REPO_NAME="$repo_name"
    export REPO_VERSION="$repo_version"
    export REPO_ARCH="$repo_arch"
    
    # Parse security config
    local signing_key_type=$(jq -r '.build.security.signing_key_type' "$BUILD_JSON")
    local signing_key_dir=$(jq -r '.build.security.signing_key_dir' "$BUILD_JSON")
    
    export SIGNING_KEY_TYPE="$signing_key_type"
    export SIGNING_KEY_DIR="$signing_key_dir"
    
    # Parse kernel config
    local kernel_config=$(jq -r '.build.kernel.config' "$BUILD_JSON")
    local kernel_arch=$(jq -r '.build.kernel.arch' "$BUILD_JSON")
    local kernel_security_features=$(jq -r '.build.kernel.security_features | join(" ")' "$BUILD_JSON")
    
    export KERNEL_CONFIG="$kernel_config"
    export KERNEL_ARCH="$kernel_arch"
    export KERNEL_SECURITY_FEATURES="$kernel_security_features"
    
    # Parse busybox config
    local busybox_config=$(jq -r '.build.busybox.config' "$BUILD_JSON")
    local busybox_arch=$(jq -r '.build.busybox.arch' "$BUILD_JSON")
    local busybox_core_applets=$(jq -r '.build.busybox.applets.core | join(" ")' "$BUILD_JSON")
    local busybox_network_applets=$(jq -r '.build.busybox.applets.network | join(" ")' "$BUILD_JSON")
    local busybox_system_applets=$(jq -r '.build.busybox.applets.system | join(" ")' "$BUILD_JSON")
    local busybox_utility_applets=$(jq -r '.build.busybox.applets.utility | join(" ")' "$BUILD_JSON")
    
    export BUSYBOX_CONFIG="$busybox_config"
    export BUSYBOX_ARCH="$busybox_arch"
    export BUSYBOX_CORE_APPLETS="$busybox_core_applets"
    export BUSYBOX_NETWORK_APPLETS="$busybox_network_applets"
    export BUSYBOX_SYSTEM_APPLETS="$busybox_system_applets"
    export BUSYBOX_UTILITY_APPLETS="$busybox_utility_applets"
    
    log_success "Loaded build configuration"
}

# Main function
main() {
    check_jq
    check_files
    
    if [[ "${1:-}" == "--verbose" ]]; then
        parse_packages
        parse_urls
        parse_build_config
        log_success "All package and build data loaded successfully from JSON"
    else
        # Silent mode - just export variables
        parse_packages
        parse_urls
        parse_build_config
    fi
}

# Run main function
main "$@"