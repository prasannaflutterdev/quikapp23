#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ARCHIVE_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ARCHIVE_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ARCHIVE_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ARCHIVE_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ARCHIVE_FIX] ❌ $1"; }

# Parse command line arguments
ARCHIVE_PATH="${1:-}"
OUTPUT_DIR="${2:-output/ios}"
IPA_NAME="${3:-Runner.ipa}"

log "🔧 Starting archive structure fix"

if [ -z "$ARCHIVE_PATH" ]; then
    log_error "Archive path is required"
    echo "Usage: $0 <archive_path> [output_dir] [ipa_name]"
    exit 1
fi

if [ ! -d "$ARCHIVE_PATH" ]; then
    log_error "Archive path does not exist: $ARCHIVE_PATH"
    exit 1
fi

log_info "Processing archive: $ARCHIVE_PATH"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to find app bundle in archive
find_app_bundle() {
    local archive_path="$1"
    local app_path=""
    
    # Look for .app in common locations within archive
    for path in "$archive_path/Products/Applications/Runner.app" "$archive_path/Products/Applications/*.app" "$archive_path/dSYMs/Runner.app.dSYM/Contents/Resources/DWARF/Runner.app"; do
        if [ -d "$path" ]; then
            app_path="$path"
            break
        fi
    done
    
    echo "$app_path"
}

# Function to create IPA from app bundle
create_ipa_from_app() {
    local app_path="$1"
    local output_path="$2"
    local ipa_name="$3"
    
    log_info "📦 Creating IPA from app bundle: $app_path"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    # Create Payload directory
    mkdir -p "$temp_dir/Payload"
    
    # Copy app to Payload
    cp -R "$app_path" "$temp_dir/Payload/"
    
    # Create IPA
    cd "$temp_dir"
    zip -r "$ipa_name" Payload/
    cd - > /dev/null
    
    # Move IPA to output directory
    mv "$temp_dir/$ipa_name" "$output_path/$ipa_name"
    
    # Clean up
    rm -rf "$temp_dir"
    
    if [ -f "$output_path/$ipa_name" ]; then
        log_success "IPA created successfully: $output_path/$ipa_name"
        return 0
    else
        log_error "Failed to create IPA"
        return 1
    fi
}

# Function to fix archive structure
fix_archive_structure() {
    local archive_path="$1"
    
    log_info "🔧 Fixing archive structure..."
    
    # Check if Products directory exists
    if [ ! -d "$archive_path/Products" ]; then
        log_warning "Products directory not found, creating..."
        mkdir -p "$archive_path/Products/Applications"
    fi
    
    # Check if Applications directory exists
    if [ ! -d "$archive_path/Products/Applications" ]; then
        log_warning "Applications directory not found, creating..."
        mkdir -p "$archive_path/Products/Applications"
    fi
    
    # Look for app bundle in archive
    local app_bundle=$(find_app_bundle "$archive_path")
    
    if [ -n "$app_bundle" ]; then
        log_info "Found app bundle: $app_bundle"
        
        # Check if app bundle is in the correct location
        local expected_path="$archive_path/Products/Applications/Runner.app"
        if [ "$app_bundle" != "$expected_path" ]; then
            log_info "Moving app bundle to correct location..."
            mkdir -p "$(dirname "$expected_path")"
            cp -R "$app_bundle" "$expected_path"
        fi
        
        return 0
    else
        log_error "No app bundle found in archive"
        return 1
    fi
}

# Main execution
log_info "🔍 Analyzing archive structure..."

# Try to fix archive structure
if fix_archive_structure "$ARCHIVE_PATH"; then
    # Find app bundle after fixing
    APP_BUNDLE=$(find_app_bundle "$ARCHIVE_PATH")
    
    if [ -n "$APP_BUNDLE" ]; then
        # Create IPA from app bundle
        if create_ipa_from_app "$APP_BUNDLE" "$OUTPUT_DIR" "$IPA_NAME"; then
            log_success "Archive structure fix completed successfully"
            exit 0
        else
            log_error "Failed to create IPA from app bundle"
            exit 1
        fi
    else
        log_error "App bundle not found after structure fix"
        exit 1
    fi
else
    log_error "Failed to fix archive structure"
    exit 1
fi 