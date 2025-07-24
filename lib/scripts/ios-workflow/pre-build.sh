#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PRE_BUILD] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PRE_BUILD] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PRE_BUILD] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PRE_BUILD] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PRE_BUILD] ❌ $1"; }

log "🚀 Starting iOS pre-build setup"

# Validate required environment variables
if [ -z "${BUNDLE_ID:-}" ]; then
    log_error "BUNDLE_ID is required but not set"
    exit 1
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    log_error "APPLE_TEAM_ID is required but not set"
    exit 1
fi

log_success "Environment variables validated"

# Clean previous builds
log_info "🧹 Cleaning previous builds..."
flutter clean
rm -rf ios/build/ 2>/dev/null || true
rm -rf build/ 2>/dev/null || true

# Get Flutter dependencies (CRITICAL for speech_to_text resolution)
log_info "📦 Getting Flutter dependencies..."
flutter pub get

# Force regenerate iOS project to fix speech_to_text resolution
log_info "🔧 Regenerating iOS project to fix package resolution..."
flutter clean
flutter pub get
flutter pub deps

# Clean Xcode derived data
log_info "🧹 Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData || true

# Ensure iOS minimum version is consistent
log_info "🔧 Ensuring iOS minimum version consistency..."
if [ -f "ios/Podfile" ]; then
    # Update Podfile to use iOS 13.0
    sed -i.bak "s/platform :ios, '[0-9.]\\+'/platform :ios, '13.0'/" ios/Podfile
    log_info "Updated Podfile to iOS 13.0"
fi

if [ -f "ios/Flutter/AppFrameworkInfo.plist" ]; then
    # Update AppFrameworkInfo.plist to use iOS 13.0
    sed -i.bak "s/<key>MinimumOSVersion<\\/key>\\s*<string>[0-9.]+<\\/string>/<key>MinimumOSVersion<\/key>\n  <string>13.0<\/string>/" ios/Flutter/AppFrameworkInfo.plist
    log_info "Updated AppFrameworkInfo.plist to iOS 13.0"
fi

# Install CocoaPods dependencies
log_info "📚 Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

# Verify speech_to_text package is properly resolved
log_info "🔍 Verifying speech_to_text package resolution..."
if flutter pub deps | grep -q "speech_to_text"; then
    log_success "speech_to_text package is properly resolved"
else
    log_warning "speech_to_text package not found in dependencies, attempting to fix..."
    flutter pub add speech_to_text
    flutter pub get
fi

# Run iOS permissions script if it exists
if [ -f "lib/scripts/ios-workflow/ios_permissions.sh" ]; then
    log_info "🔐 Configuring iOS permissions..."
    chmod +x lib/scripts/ios-workflow/ios_permissions.sh
    ./lib/scripts/ios-workflow/ios_permissions.sh || log_warning "iOS permissions configuration failed (continuing...)"
fi

# Run branding assets script if it exists
if [ -f "lib/scripts/ios-workflow/branding_assets.sh" ]; then
    log_info "🎨 Downloading branding assets..."
    chmod +x lib/scripts/ios-workflow/branding_assets.sh
    ./lib/scripts/ios-workflow/branding_assets.sh || log_warning "Branding assets download failed (continuing...)"
fi

# Run Info.plist injection script if it exists
if [ -f "lib/scripts/ios-workflow/inject_info_plist.sh" ]; then
    log_info "📝 Injecting Info.plist values..."
    chmod +x lib/scripts/ios-workflow/inject_info_plist.sh
    ./lib/scripts/ios-workflow/inject_info_plist.sh || log_warning "Info.plist injection failed (continuing...)"
fi

# Run CwlCatchException fix if it exists
if [ -f "lib/scripts/ios-workflow/fix_cwl_catch_exception.sh" ]; then
    log_info "🔧 Applying CwlCatchException fix..."
    chmod +x lib/scripts/ios-workflow/fix_cwl_catch_exception.sh
    ./lib/scripts/ios-workflow/fix_cwl_catch_exception.sh || log_warning "CwlCatchException fix failed (continuing...)"
fi

log_success "iOS pre-build setup completed successfully"
exit 0 