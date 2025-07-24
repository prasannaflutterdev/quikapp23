#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IPA_EXPORT] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IPA_EXPORT] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IPA_EXPORT] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IPA_EXPORT] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IPA_EXPORT] ❌ $1"; }

# Parse command line arguments
OUTPUT_DIR="${1:-output/ios}"
IPA_NAME="${2:-Runner.ipa}"

log "📦 Starting improved IPA export to $OUTPUT_DIR/$IPA_NAME"

# Validate required environment variables
if [ -z "${BUNDLE_ID:-}" ]; then
    log_error "BUNDLE_ID is required but not set"
    exit 1
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    log_error "APPLE_TEAM_ID is required but not set"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to find archive files
find_archive() {
    local archive_path=""
    
    # Look for .xcarchive files in common locations
    for path in "build/Runner.xcarchive" "ios/build/Runner.xcarchive" "*.xcarchive"; do
        if [ -d "$path" ]; then
            archive_path="$path"
            break
        fi
    done
    
    echo "$archive_path"
}

# Function to export IPA from archive
export_ipa_from_archive() {
    local archive_path="$1"
    local export_path="$2"
    
    log_info "📦 Exporting IPA from archive: $archive_path"
    
    # Create export options plist
    cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF
    
    # Export IPA
    xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportOptionsPlist ios/ExportOptions.plist \
        -exportPath "$export_path" \
        -allowProvisioningUpdates \
        -allowProvisioningDeviceRegistration
    
    # Check if IPA was created
    if [ -f "$export_path/Runner.ipa" ]; then
        log_success "IPA exported successfully: $export_path/Runner.ipa"
        return 0
    else
        log_error "IPA export failed"
        return 1
    fi
}

# Function to create IPA from app bundle
create_ipa_from_app() {
    local app_path="$1"
    local output_path="$2"
    
    log_info "📦 Creating IPA from app bundle: $app_path"
    
    # Create Payload directory
    mkdir -p "$output_path/Payload"
    
    # Copy app to Payload
    cp -R "$app_path" "$output_path/Payload/"
    
    # Create IPA
    cd "$output_path"
    zip -r "$IPA_NAME" Payload/
    cd - > /dev/null
    
    if [ -f "$output_path/$IPA_NAME" ]; then
        log_success "IPA created from app bundle: $output_path/$IPA_NAME"
        return 0
    else
        log_error "Failed to create IPA from app bundle"
        return 1
    fi
}

# Main export logic with fallbacks
log_info "🔍 Looking for archive files..."

ARCHIVE_PATH=$(find_archive)

if [ -n "$ARCHIVE_PATH" ]; then
    log_info "Found archive: $ARCHIVE_PATH"
    
    # Try to export from archive
    if export_ipa_from_archive "$ARCHIVE_PATH" "build/export"; then
        # Copy to output directory
        cp "build/export/Runner.ipa" "$OUTPUT_DIR/$IPA_NAME"
        log_success "IPA exported successfully to $OUTPUT_DIR/$IPA_NAME"
        exit 0
    else
        log_warning "Archive export failed, trying fallback methods..."
    fi
else
    log_warning "No archive found, trying fallback methods..."
fi

# Fallback: Look for app bundles
log_info "🔍 Looking for app bundles..."

APP_BUNDLE_PATH=""
for path in "ios/build/ios/iphoneos/Runner.app" "build/ios/iphoneos/Runner.app" "*.app"; do
    if [ -d "$path" ]; then
        APP_BUNDLE_PATH="$path"
        break
    fi
done

if [ -n "$APP_BUNDLE_PATH" ]; then
    log_info "Found app bundle: $APP_BUNDLE_PATH"
    
    if create_ipa_from_app "$APP_BUNDLE_PATH" "$OUTPUT_DIR"; then
        log_success "IPA created from app bundle"
        exit 0
    else
        log_error "Failed to create IPA from app bundle"
        exit 1
    fi
else
    log_error "No app bundle found"
    exit 1
fi 