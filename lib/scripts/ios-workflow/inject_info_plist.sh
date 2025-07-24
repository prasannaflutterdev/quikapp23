#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO_PLIST] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO_PLIST] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO_PLIST] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO_PLIST] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO_PLIST] ❌ $1"; }

log "📝 Starting Info.plist injection"

INFO_PLIST_PATH="ios/Runner/Info.plist"

if [ ! -f "$INFO_PLIST_PATH" ]; then
    log_error "Info.plist not found at $INFO_PLIST_PATH"
    exit 1
fi

# Create backup
cp "$INFO_PLIST_PATH" "$INFO_PLIST_PATH.bak"
log_success "Created backup of Info.plist"

# Function to update or add key-value pair in Info.plist
update_info_plist() {
    local key="$1"
    local value="$2"
    
    log_info "Updating $key to $value"
    
    # Check if key exists
    if grep -q "<key>$key</key>" "$INFO_PLIST_PATH"; then
        # Update existing key
        sed -i.bak "s/<key>$key<\/key>.*<string>.*<\/string>/<key>$key<\/key>\n\t<string>$value<\/string>/" "$INFO_PLIST_PATH"
    else
        # Add new key before closing </dict>
        sed -i.bak "s/<\/dict>/	<key>$key<\/key>\n	<string>$value<\/string>\n<\/dict>/" "$INFO_PLIST_PATH"
    fi
}

# Update app name if provided
if [ -n "${APP_NAME:-}" ]; then
    update_info_plist "CFBundleDisplayName" "$APP_NAME"
    update_info_plist "CFBundleName" "$APP_NAME"
fi

# Update bundle identifier if provided
if [ -n "${BUNDLE_ID:-}" ]; then
    # Note: This is typically handled by Xcode build settings
    log_info "Bundle ID will be set via Xcode build settings: $BUNDLE_ID"
fi

# Update version if provided
if [ -n "${VERSION_NAME:-}" ]; then
    update_info_plist "CFBundleShortVersionString" "$VERSION_NAME"
fi

if [ -n "${VERSION_CODE:-}" ]; then
    update_info_plist "CFBundleVersion" "$VERSION_CODE"
fi

# Add custom URL schemes if provided
if [ -n "${WEB_URL:-}" ]; then
    log_info "Adding custom URL scheme for: $WEB_URL"
    # This would require more complex plist manipulation for URL schemes
    # For now, just log that it's available
fi

# Verify the plist is valid
log_info "🔍 Verifying Info.plist..."
if plutil -lint "$INFO_PLIST_PATH" > /dev/null 2>&1; then
    log_success "Info.plist is valid"
else
    log_error "Info.plist validation failed, restoring backup"
    cp "$INFO_PLIST_PATH.bak" "$INFO_PLIST_PATH"
    exit 1
fi

# Clean up backup
rm "$INFO_PLIST_PATH.bak" || true

log_success "Info.plist injection completed successfully"
exit 0 