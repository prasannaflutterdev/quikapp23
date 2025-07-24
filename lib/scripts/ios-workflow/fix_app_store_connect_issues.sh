#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_STORE] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_STORE] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_STORE] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_STORE] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_STORE] ❌ $1"; }

# Parse command line arguments
BUNDLE_ID="${1:-}"
APP_BUNDLE_PATH="${2:-}"

log "🔧 Starting App Store Connect issues fix"

if [ -z "$BUNDLE_ID" ]; then
    log_error "Bundle ID is required"
    echo "Usage: $0 <bundle_id> [app_bundle_path]"
    exit 1
fi

# Function to fix Info.plist issues
fix_info_plist() {
    local app_bundle="$1"
    local info_plist="$app_bundle/Info.plist"
    
    log_info "🔧 Fixing Info.plist issues..."
    
    if [ ! -f "$info_plist" ]; then
        log_error "Info.plist not found: $info_plist"
        return 1
    fi
    
    # Create backup
    cp "$info_plist" "$info_plist.bak"
    
    # Fix common App Store Connect issues
    
    # 1. Ensure CFBundleIdentifier is set correctly
    if ! plutil -extract CFBundleIdentifier raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding CFBundleIdentifier..."
        plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$info_plist"
    fi
    
    # 2. Ensure CFBundleDisplayName is set
    if ! plutil -extract CFBundleDisplayName raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding CFBundleDisplayName..."
        plutil -insert CFBundleDisplayName -string "Runner" "$info_plist"
    fi
    
    # 3. Ensure CFBundleName is set
    if ! plutil -extract CFBundleName raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding CFBundleName..."
        plutil -insert CFBundleName -string "Runner" "$info_plist"
    fi
    
    # 4. Ensure CFBundlePackageType is set
    if ! plutil -extract CFBundlePackageType raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding CFBundlePackageType..."
        plutil -insert CFBundlePackageType -string "APPL" "$info_plist"
    fi
    
    # 5. Ensure CFBundleSignature is set
    if ! plutil -extract CFBundleSignature raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding CFBundleSignature..."
        plutil -insert CFBundleSignature -string "????" "$info_plist"
    fi
    
    # 6. Ensure LSRequiresIPhoneOS is set
    if ! plutil -extract LSRequiresIPhoneOS raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding LSRequiresIPhoneOS..."
        plutil -insert LSRequiresIPhoneOS -bool true "$info_plist"
    fi
    
    # 7. Ensure UISupportedInterfaceOrientations is set
    if ! plutil -extract UISupportedInterfaceOrientations raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding UISupportedInterfaceOrientations..."
        plutil -insert UISupportedInterfaceOrientations -array "$info_plist"
        plutil -insert UISupportedInterfaceOrientations.0 -string "UIInterfaceOrientationPortrait" "$info_plist"
    fi
    
    # 8. Ensure minimum deployment target is set
    if ! plutil -extract MinimumOSVersion raw "$info_plist" > /dev/null 2>&1; then
        log_info "Adding MinimumOSVersion..."
        plutil -insert MinimumOSVersion -string "13.0" "$info_plist"
    fi
    
    # Verify the plist is valid
    if plutil -lint "$info_plist" > /dev/null 2>&1; then
        log_success "Info.plist fixes applied successfully"
        rm "$info_plist.bak"
        return 0
    else
        log_error "Info.plist validation failed, restoring backup"
        cp "$info_plist.bak" "$info_plist"
        return 1
    fi
}

# Function to fix code signing issues
fix_code_signing() {
    local app_bundle="$1"
    
    log_info "🔧 Fixing code signing issues..."
    
    # Check if app is properly signed
    if ! codesign -dv "$app_bundle" > /dev/null 2>&1; then
        log_warning "App is not properly signed, attempting to fix..."
        
        # Remove existing signatures
        codesign --remove-signature "$app_bundle" 2>/dev/null || true
        
        # Re-sign with ad-hoc signature
        codesign --force --sign - --timestamp=none "$app_bundle" 2>/dev/null || log_warning "Failed to re-sign app"
    else
        log_success "App is properly signed"
    fi
    
    # Check frameworks
    local frameworks_dir="$app_bundle/Frameworks"
    if [ -d "$frameworks_dir" ]; then
        for framework in "$frameworks_dir"/*.framework; do
            if [ -d "$framework" ]; then
                local framework_name=$(basename "$framework" .framework)
                local framework_executable="$framework/$framework_name"
                
                if [ -f "$framework_executable" ]; then
                    if ! codesign -dv "$framework_executable" > /dev/null 2>&1; then
                        log_info "Re-signing framework: $framework_name"
                        codesign --force --sign - --timestamp=none "$framework_executable" 2>/dev/null || log_warning "Failed to re-sign framework: $framework_name"
                    fi
                fi
            fi
        done
    fi
}

# Function to fix bundle structure issues
fix_bundle_structure() {
    local app_bundle="$1"
    
    log_info "🔧 Fixing bundle structure issues..."
    
    # Ensure executable exists and has proper permissions
    local executable_name=$(plutil -extract CFBundleExecutable raw "$app_bundle/Info.plist" 2>/dev/null || echo "Runner")
    local executable_path="$app_bundle/$executable_name"
    
    if [ ! -f "$executable_path" ]; then
        log_error "Bundle executable not found: $executable_path"
        return 1
    fi
    
    # Ensure executable has proper permissions
    chmod +x "$executable_path"
    
    # Check for required directories
    local required_dirs=("Frameworks" "Resources")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$app_bundle/$dir" ]; then
            log_info "Creating required directory: $dir"
            mkdir -p "$app_bundle/$dir"
        fi
    done
    
    log_success "Bundle structure fixes applied"
    return 0
}

# Main execution
if [ -n "$APP_BUNDLE_PATH" ]; then
    log_info "Processing app bundle: $APP_BUNDLE_PATH"
    
    if [ ! -d "$APP_BUNDLE_PATH" ]; then
        log_error "App bundle not found: $APP_BUNDLE_PATH"
        exit 1
    fi
    
    # Apply fixes
    if fix_info_plist "$APP_BUNDLE_PATH"; then
        if fix_code_signing "$APP_BUNDLE_PATH"; then
            if fix_bundle_structure "$APP_BUNDLE_PATH"; then
                log_success "App Store Connect issues fix completed successfully"
                exit 0
            else
                log_error "Bundle structure fix failed"
                exit 1
            fi
        else
            log_error "Code signing fix failed"
            exit 1
        fi
    else
        log_error "Info.plist fix failed"
        exit 1
    fi
else
    log_info "No app bundle path provided, skipping bundle-specific fixes"
    log_success "App Store Connect issues fix completed (info only)"
    exit 0
fi 