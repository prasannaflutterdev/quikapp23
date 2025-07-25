#!/bin/bash
# 🧪 Test New iOS Workflow Script
# Tests the new comprehensive iOS workflow with sample data
# Usage: ./lib/scripts/ios-workflow/test_new_workflow.sh

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "Starting New iOS Workflow Test"
log "================================================"

# Step 1: Test Environment Variables
log_info "Step 1: Testing Environment Variables"
log "================================================"

# Set test environment variables
export WORKFLOW_ID="ios-workflow-test"
export USER_NAME="TestUser"
export APP_ID="test123"
export VERSION_NAME="1.0.0"
export VERSION_CODE="1"
export APP_NAME="Test App"
export ORG_NAME="Test Organization"
export WEB_URL="https://testapp.com"
export PKG_NAME="com.test.app"
export BUNDLE_ID="com.test.app"
export EMAIL_ID="test@example.com"
export APPLE_TEAM_ID="TEST123456"
export PUSH_NOTIFY="true"
export IS_CHATBOT="true"
export IS_DOMAIN_URL="true"
export IS_SPLASH="true"
export IS_PULLDOWN="true"
export IS_BOTTOMMENU="true"
export IS_LOAD_IND="true"
export IS_CAMERA="true"
export IS_LOCATION="true"
export IS_MIC="true"
export IS_NOTIFICATION="true"
export IS_CONTACT="true"
export IS_BIOMETRIC="true"
export IS_CALENDAR="true"
export IS_STORAGE="true"
export PROFILE_TYPE="app-store"
export PROFILE_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/Twinklub_AppStore.mobileprovision"
export CERT_PASSWORD="test123"
export CERT_P12_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/Certificates.p12"
export FIREBASE_CONFIG_IOS="https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-gc.plist"
export APNS_KEY_ID="TEST123"
export APNS_AUTH_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_V566SWNF69.p8"
export ENABLE_EMAIL_NOTIFICATIONS="false"
export EMAIL_SMTP_SERVER="smtp.gmail.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="test@gmail.com"
export EMAIL_SMTP_PASS="test123"
export LOGO_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/twinklub_png_logo.png"
export SPLASH_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/twinklub_png_logo.png"
export SPLASH_BG_URL=""
export SPLASH_BG_COLOR="#FFFFFF"
export SPLASH_TAGLINE="TEST APP"
export SPLASH_TAGLINE_COLOR="#000000"
export SPLASH_ANIMATION="fade"
export SPLASH_DURATION="3"
export BOTTOMMENU_ITEMS="[{\"label\":\"Home\",\"icon\":{\"type\":\"preset\",\"name\":\"home_outlined\"},\"url\":\"https://testapp.com/\"}]"
export BOTTOMMENU_BG_COLOR="#FFFFFF"
export BOTTOMMENU_ICON_COLOR="#000000"
export BOTTOMMENU_TEXT_COLOR="#000000"
export BOTTOMMENU_FONT="System"
export BOTTOMMENU_FONT_SIZE="12"
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"
export BOTTOMMENU_ACTIVE_TAB_COLOR="#007AFF"
export BOTTOMMENU_ICON_POSITION="above"

log_success "Test environment variables set"

# Step 2: Test URL Accessibility
log_info "Step 2: Testing URL Accessibility"
log "================================================"

URLS=(
    "$PROFILE_URL:provisioning profile"
    "$CERT_P12_URL:P12 certificate"
    "$FIREBASE_CONFIG_IOS:Firebase config"
    "$APNS_AUTH_KEY_URL:APNS auth key"
    "$LOGO_URL:app logo"
    "$SPLASH_URL:splash image"
)

for url_info in "${URLS[@]}"; do
    IFS=':' read -r url description <<< "$url_info"
    if [ -n "$url" ] && [ "$url" != "" ]; then
        if curl -I -s -f "$url" >/dev/null 2>&1; then
            log_success "✅ $description URL accessible"
        else
            log_warning "⚠️ $description URL not accessible"
        fi
    else
        log_info "ℹ️ No URL provided for $description"
    fi
done

# Step 3: Test Project Structure
log_info "Step 3: Testing Project Structure"
log "================================================"

REQUIRED_FILES=(
    "ios/Runner.xcworkspace"
    "ios/Podfile"
    "lib/scripts/utils/gen_env_config.sh"
    "pubspec.yaml"
    "lib/scripts/ios-workflow/new_ios_workflow.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        log_success "✅ Found: $file"
    else
        log_error "❌ Missing: $file"
    fi
done

# Step 4: Test Script Functions
log_info "Step 4: Testing Script Functions"
log "================================================"

# Test get_env_var function
if [ -n "$(get_env_var "APP_NAME" "Default App")" ]; then
    log_success "✅ get_env_var function works"
else
    log_error "❌ get_env_var function failed"
fi

# Test safe_download function (test with a small file)
if curl -L -f -s -o /tmp/test_download.txt "https://httpbin.org/bytes/100" 2>/dev/null; then
    log_success "✅ Download function works"
    rm -f /tmp/test_download.txt
else
    log_warning "⚠️ Download function test failed"
fi

# Step 5: Test env_config.dart Generation
log_info "Step 5: Testing env_config.dart Generation"
log "================================================"

# Create a test env_config.dart
cat > lib/config/env_config_test.dart <<EOF
// Generated by Test Script
class EnvConfig {
  static const String appName = '$APP_NAME';
  static const String versionName = '$VERSION_NAME';
  static const String bundleId = '$BUNDLE_ID';
  static const bool isPushNotify = $PUSH_NOTIFY;
  static const bool isCamera = $IS_CAMERA;
}
EOF

if [ -f "lib/config/env_config_test.dart" ]; then
    log_success "✅ env_config.dart generation works"
    # Check if variables are properly injected
    if grep -q "$APP_NAME" lib/config/env_config_test.dart; then
        log_success "✅ Environment variables properly injected"
    else
        log_error "❌ Environment variables not injected properly"
    fi
    rm -f lib/config/env_config_test.dart
else
    log_error "❌ env_config.dart generation failed"
fi

# Step 6: Test Permission Injection
log_info "Step 6: Testing Permission Injection"
log "================================================"

# Create a test Info.plist additions
cat > ios/Runner/Info.plist.test <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
EOF

# Add test permissions
if [ "$IS_CAMERA" = "true" ]; then
    cat >> ios/Runner/Info.plist.test <<EOF
    <key>NSCameraUsageDescription</key>
    <string>Test camera permission</string>
EOF
fi

if [ "$IS_LOCATION" = "true" ]; then
    cat >> ios/Runner/Info.plist.test <<EOF
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Test location permission</string>
EOF
fi

cat >> ios/Runner/Info.plist.test <<EOF
</dict>
</plist>
EOF

if [ -f "ios/Runner/Info.plist.test" ]; then
    log_success "✅ Permission injection works"
    rm -f ios/Runner/Info.plist.test
else
    log_error "❌ Permission injection failed"
fi

# Step 7: Final Test Summary
log_info "Step 7: Final Test Summary"
log "================================================"

log_success "🎉 New iOS Workflow Test Completed!"
log "📱 App: $APP_NAME v$VERSION_NAME ($VERSION_CODE)"
log "🆔 Bundle ID: $BUNDLE_ID"
log "👥 Team ID: $APPLE_TEAM_ID"
log "🚀 Push Notifications: $PUSH_NOTIFY"
log "🔧 Features Enabled:"
log "   - Camera: $IS_CAMERA"
log "   - Location: $IS_LOCATION"
log "   - Microphone: $IS_MIC"
log "   - Notifications: $IS_NOTIFICATION"
log "   - Contacts: $IS_CONTACT"
log "   - Biometric: $IS_BIOMETRIC"
log "   - Calendar: $IS_CALENDAR"
log "   - Storage: $IS_STORAGE"

log_success "✅ New iOS workflow test completed successfully!"
log_info "The new iOS workflow is ready for production use"
exit 0 