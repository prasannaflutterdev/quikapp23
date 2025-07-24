#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD] ❌ $1"; }

log "🏗️ Starting comprehensive iOS build"

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

# Get Flutter dependencies
log_info "📦 Getting Flutter dependencies..."
flutter pub get

# Clean Xcode derived data
log_info "🧹 Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData || true

# Install CocoaPods dependencies
log_info "📚 Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

# Build Flutter app for iOS (without code signing)
log_info "🏗️ Building Flutter app for iOS..."
flutter build ios --release --no-codesign

# Create archive
log_info "📦 Creating Xcode archive..."
xcodebuild \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphoneos \
    -configuration Release archive \
    -archivePath build/Runner.xcarchive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Automatic" \
    CODE_SIGN_IDENTITY="Apple Development" \
    ENABLE_BITCODE=NO \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration

# Create export options plist
log_info "📋 Creating export options..."
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
log_info "📦 Exporting IPA..."
mkdir -p build/export
xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportOptionsPlist ios/ExportOptions.plist \
    -exportPath build/export \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration

# Verify IPA was created
if [ -f "build/export/Runner.ipa" ]; then
    log_success "IPA created successfully: build/export/Runner.ipa"
    
    # Copy to output directory
    mkdir -p output/ios
    cp build/export/Runner.ipa output/ios/Runner.ipa
    
    # Check file size
    IPA_SIZE=$(stat -f%z "output/ios/Runner.ipa" 2>/dev/null || stat -c%s "output/ios/Runner.ipa" 2>/dev/null || echo "0")
    if [ "$IPA_SIZE" -gt 1000000 ]; then
        log_success "IPA file size is valid: $IPA_SIZE bytes"
    else
        log_error "IPA file is too small: $IPA_SIZE bytes"
        exit 1
    fi
else
    log_error "IPA file not found"
    exit 1
fi

log_success "Comprehensive iOS build completed successfully"
exit 0 