#!/bin/bash
# 🚀 Simplified iOS Build Script for Codemagic
# Streamlined version focusing on core functionality
# Usage: ./lib/scripts/ios-workflow/build_ios_simple.sh

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_SIMPLE] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Create output directories
mkdir -p output/ios
mkdir -p build/ios/logs

# Function to safely get environment variable with fallback
get_env_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        log "✅ Found $var_name: $value"
        printf "%s" "$value"
    else
        log "⚠️ $var_name not set, using fallback: $fallback"
        printf "%s" "$fallback"
    fi
}

# Function to safely download files
safe_download() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    if [ -z "$url" ]; then
        log_warning "No URL provided for $description, skipping"
        return 0
    fi
    
    log_info "Downloading $description from: $url"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"
    
    # Use curl with proper error handling
    if curl -L -f -s -o "$output_path" "$url" 2>/dev/null; then
        log_success "$description downloaded successfully"
        return 0
    else
        log_warning "Failed to download $description, continuing without it"
        return 1
    fi
}

# Step 1: Environment Setup
log_info "Step 1: Environment Setup"
log "================================================"

# Set essential variables
export WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "ios-workflow")
export APP_NAME=$(get_env_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_env_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_env_var "VERSION_CODE" "1")
export BUNDLE_ID=$(get_env_var "BUNDLE_ID" "com.example.quikapp")
export APPLE_TEAM_ID=$(get_env_var "APPLE_TEAM_ID" "")
export PROFILE_URL=$(get_env_var "PROFILE_URL" "")
export IS_TESTFLIGHT=$(get_env_var "IS_TESTFLIGHT" "false")
export APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
export APP_STORE_CONNECT_ISSUER_ID=$(get_env_var "APP_STORE_CONNECT_ISSUER_ID" "")
export APP_STORE_CONNECT_API_KEY_URL=$(get_env_var "APP_STORE_CONNECT_API_KEY_URL" "")

# Validate critical variables
log_info "Validating critical environment variables..."
if [ -z "$BUNDLE_ID" ]; then
    log_error "BUNDLE_ID is required but not set"
    exit 1
fi

if [ -z "$APPLE_TEAM_ID" ]; then
    log_error "APPLE_TEAM_ID is required but not set"
    exit 1
fi

log_success "Environment variables validated"

# Step 2: Download Assets
log_info "Step 2: Download Assets"
log "================================================"

# Download provisioning profile if URL provided
if [ -n "$PROFILE_URL" ]; then
    safe_download "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"
fi

# Download App Store Connect API key if URL provided
if [ -n "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    safe_download "$APP_STORE_CONNECT_API_KEY_URL" "ios/AuthKey.p8" "App Store Connect API key"
fi

# Step 3: Generate Environment Configuration
log_info "Step 3: Generate Environment Configuration"
log "================================================"

# Generate env_config.dart
log_info "Generating env_config.dart..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    bash lib/scripts/utils/gen_env_config.sh || {
        log_error "Failed to generate env_config.dart"
        exit 1
    }
    log_success "env_config.dart generated successfully"
else
    log_error "gen_env_config.sh not found"
    exit 1
fi

# Step 4: Flutter Setup
log_info "Step 4: Flutter Setup"
log "================================================"

# Clean and get dependencies
log_info "Cleaning previous builds..."
flutter clean || log_warning "Flutter clean failed, continuing anyway"

log_info "Getting Flutter dependencies..."
flutter pub get || {
    log_error "Failed to get Flutter dependencies"
    exit 1
}

# Step 5: iOS Setup
log_info "Step 5: iOS Setup"
log "================================================"

# Update iOS minimum version if needed
if [ -f "ios/Podfile" ]; then
    log_info "Updating iOS Podfile..."
    sed -i '' 's/platform :ios, '"'"'[0-9.]*'"'"'/platform :ios, '"'"'12.0'"'"'/g' ios/Podfile || log_warning "Failed to update Podfile"
fi

# Install CocoaPods dependencies
log_info "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update || {
    log_error "Failed to install CocoaPods dependencies"
    exit 1
}
cd ..

log_success "iOS setup completed"

# Step 6: Flutter Build
log_info "Step 6: Flutter Build"
log "================================================"

log_info "Building Flutter app without code signing..."
flutter build ios --release --no-codesign || {
    log_error "Flutter build failed"
    exit 1
}

log_success "Flutter build completed"

# Step 7: Xcode Archive
log_info "Step 7: Xcode Archive"
log "================================================"

log_info "Creating Xcode archive with code signing..."
xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphoneos \
    -configuration Release archive \
    -archivePath build/Runner.xcarchive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Automatic" \
    CODE_SIGN_IDENTITY="iPhone Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="Runner" || {
    log_error "Xcode archive failed"
    exit 1
}

log_success "Xcode archive completed"

# Step 8: Export IPA
log_info "Step 8: Export IPA"
log "================================================"

# Create ExportOptions.plist
log_info "Creating ExportOptions.plist..."
cat > lib/scripts/ios-workflow/exportOptions.plist <<EOF
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

log_info "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
    -exportPath build/export \
    -allowProvisioningUpdates || {
    log_error "IPA export failed"
    exit 1
}

# Verify IPA was created
if [ -f "build/export/Runner.ipa" ]; then
    log_success "IPA exported successfully: build/export/Runner.ipa"
    ls -la build/export/
else
    log_error "IPA file not found after export"
    exit 1
fi

# Step 9: Upload to TestFlight (Optional)
log_info "Step 9: Upload to TestFlight (Optional)"
log "================================================"

if [ "$IS_TESTFLIGHT" = "true" ] && [ -n "$APP_STORE_CONNECT_KEY_IDENTIFIER" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    log_info "Uploading to TestFlight..."
    
    # Use altool for upload
    xcrun altool --upload-app \
        --type ios \
        --file build/export/Runner.ipa \
        --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
        --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" || {
        log_error "TestFlight upload failed"
        exit 1
    }
    
    log_success "App uploaded to TestFlight successfully"
else
    log_info "Skipping TestFlight upload (IS_TESTFLIGHT=$IS_TESTFLIGHT)"
fi

# Step 10: Final Summary
log_info "Step 10: Final Summary"
log "================================================"

log_success "🎉 Simplified iOS Build Completed Successfully!"
log "📱 App: $APP_NAME v$VERSION_NAME ($VERSION_CODE)"
log "🆔 Bundle ID: $BUNDLE_ID"
log "👥 Team ID: $APPLE_TEAM_ID"
log "📦 IPA Location: build/export/Runner.ipa"
log "🚀 TestFlight: $IS_TESTFLIGHT"

# Copy IPA to output directory for Codemagic artifacts
cp build/export/Runner.ipa output/ios/ || log_warning "Failed to copy IPA to output directory"

log_success "✅ Simplified iOS workflow completed successfully!"
exit 0 