#!/usr/bin/env bash

# Test script for env_config.dart generation
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Function to safely get environment variable
safe_env_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ "$value" = "\$$var_name" ] || [ "$value" = "$var_name" ] || [ -z "$value" ] || [[ "$value" == *"\$$var_name"* ]]; then
        echo "$fallback"
    else
        echo "$value" | tr -d '\r\n\t' | sed 's/[^[:print:]]//g'
    fi
}

# Function to safely escape strings for Dart
escape_dart_string() {
    local value="$1"
    # Escape quotes for Dart string literals
    echo "$value" | sed 's/"/\\"/g'
}

# Test function
test_env_generation() {
    local test_name="$1"
    local description="$2"
    
    log_info "Testing $description..."
    
    # Create test directory
    mkdir -p test_env_config
    
    # Set test variables
    export APP_NAME="Test App"
    export BUNDLE_ID="com.test.app"
    export VERSION_NAME="1.0.0"
    export VERSION_CODE="1"
    export PUSH_NOTIFY="true"
    export IS_CHATBOT="true"
    export IS_DOMAIN_URL="true"
    export IS_SPLASH="true"
    export IS_PULLDOWN="false"
    export IS_BOTTOMMENU="false"
    export IS_LOAD_IND="true"
    export IS_CAMERA="false"
    export IS_LOCATION="false"
    export IS_MIC="true"
    export IS_NOTIFICATION="true"
    export IS_CONTACT="false"
    export IS_BIOMETRIC="false"
    export IS_CALENDAR="false"
    export IS_STORAGE="true"
    export SPLASH_BG_COLOR="#FFFFFF"
    export SPLASH_TAGLINE="Test App"
    export SPLASH_TAGLINE_COLOR="#000000"
    export SPLASH_ANIMATION="fade"
    export SPLASH_DURATION="3"
    export SPLASH_URL="https://example.com/logo.png"
    export SPLASH_BG_URL=""
    export BOTTOMMENU_ITEMS='[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://example.com/"}]'
    export BOTTOMMENU_BG_COLOR="#FFFFFF"
    export BOTTOMMENU_ACTIVE_TAB_COLOR="#007AFF"
    export BOTTOMMENU_TEXT_COLOR="#666666"
    export BOTTOMMENU_ICON_COLOR="#666666"
    export BOTTOMMENU_ICON_POSITION="above"
    export BOTTOMMENU_FONT="Roboto"
    export BOTTOMMENU_FONT_SIZE="12"
    export BOTTOMMENU_FONT_BOLD="false"
    export BOTTOMMENU_FONT_ITALIC="false"
    export FIREBASE_CONFIG_ANDROID="https://example.com/firebase-android.json"
    export FIREBASE_CONFIG_IOS="https://example.com/firebase-ios.plist"
    
    # Get safe values
    local app_name=$(escape_dart_string "${APP_NAME:-}")
    local bundle_id=$(escape_dart_string "${BUNDLE_ID:-}")
    local version_name=$(escape_dart_string "${VERSION_NAME:-}")
    local version_code="${VERSION_CODE:-0}"
    
    local push_notify="${PUSH_NOTIFY:-false}"
    local is_chatbot="${IS_CHATBOT:-false}"
    local is_domain_url="${IS_DOMAIN_URL:-false}"
    local is_splash="${IS_SPLASH:-true}"
    local is_pulldown="${IS_PULLDOWN:-false}"
    local is_bottommenu="${IS_BOTTOMMENU:-false}"
    local is_load_ind="${IS_LOAD_IND:-false}"
    
    local is_camera="${IS_CAMERA:-false}"
    local is_location="${IS_LOCATION:-false}"
    local is_mic="${IS_MIC:-false}"
    local is_notification="${IS_NOTIFICATION:-false}"
    local is_contact="${IS_CONTACT:-false}"
    local is_biometric="${IS_BIOMETRIC:-false}"
    local is_calendar="${IS_CALENDAR:-false}"
    local is_storage="${IS_STORAGE:-false}"
    
    local splash_bg_color=$(escape_dart_string "${SPLASH_BG_COLOR:-#FFFFFF}")
    local splash_tagline=$(escape_dart_string "${SPLASH_TAGLINE:-}")
    local splash_tagline_color=$(escape_dart_string "${SPLASH_TAGLINE_COLOR:-#000000}")
    local splash_animation=$(escape_dart_string "${SPLASH_ANIMATION:-fade}")
    local splash_duration="${SPLASH_DURATION:-3}"
    local splash_url=$(escape_dart_string "${SPLASH_URL:-}")
    local splash_bg=$(escape_dart_string "${SPLASH_BG_URL:-}")
    
    local bottommenu_items=$(escape_dart_string "${BOTTOMMENU_ITEMS:-[]}")
    local bottommenu_bg_color=$(escape_dart_string "${BOTTOMMENU_BG_COLOR:-#FFFFFF}")
    local bottommenu_active_tab_color=$(escape_dart_string "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#007AFF}")
    local bottommenu_text_color=$(escape_dart_string "${BOTTOMMENU_TEXT_COLOR:-#666666}")
    local bottommenu_icon_color=$(escape_dart_string "${BOTTOMMENU_ICON_COLOR:-#666666}")
    local bottommenu_icon_position=$(escape_dart_string "${BOTTOMMENU_ICON_POSITION:-above}")
    local bottommenu_font=$(escape_dart_string "${BOTTOMMENU_FONT:-Roboto}")
    local bottommenu_font_size="${BOTTOMMENU_FONT_SIZE:-12}"
    local bottommenu_font_bold="${BOTTOMMENU_FONT_BOLD:-false}"
    local bottommenu_font_italic="${BOTTOMMENU_FONT_ITALIC:-false}"
    
    # Handle Firebase config variables safely
    local firebase_config_android=""
    local firebase_config_ios=""
    
    # Check if FIREBASE_CONFIG_ANDROID is set and not empty
    if [ -n "${FIREBASE_CONFIG_ANDROID:-}" ] && [ "$FIREBASE_CONFIG_ANDROID" != "\$FIREBASE_CONFIG_ANDROID" ]; then
        firebase_config_android=$(escape_dart_string "$FIREBASE_CONFIG_ANDROID")
    fi
    
    # Check if FIREBASE_CONFIG_IOS is set and not empty
    if [ -n "${FIREBASE_CONFIG_IOS:-}" ] && [ "$FIREBASE_CONFIG_IOS" != "\$FIREBASE_CONFIG_IOS" ]; then
        firebase_config_ios=$(escape_dart_string "$FIREBASE_CONFIG_IOS")
    fi
    
    # Generate the env_config.dart file
    cat > test_env_config/env_config.dart << EOF
// Generated by Test Script
// Do not edit manually

class EnvConfig {
  // App Information
  static const String appName = "$app_name";
  static const String webUrl = "";
  static const String orgName = "";
  static const String emailId = "";
  static const String userName = "";
  static const String appId = "";
  static const String versionName = "$version_name";
  static const int versionCode = $version_code;

  // Feature Flags
  static const bool pushNotify = $push_notify;
  static const bool isChatbot = $is_chatbot;
  static const bool isDomainUrl = $is_domain_url;
  static const bool isSplash = $is_splash;
  static const bool isPulldown = $is_pulldown;
  static const bool isBottommenu = $is_bottommenu;
  static const bool isLoadIndicator = $is_load_ind;

  // Permissions
  static const bool isCamera = $is_camera;
  static const bool isLocation = $is_location;
  static const bool isMic = $is_mic;
  static const bool isNotification = $is_notification;
  static const bool isContact = $is_contact;
  static const bool isBiometric = $is_biometric;
  static const bool isCalendar = $is_calendar;
  static const bool isStorage = $is_storage;

  // UI Configuration
  static const String splashBgColor = "$splash_bg_color";
  static const String splashTagline = "$splash_tagline";
  static const String splashTaglineColor = "$splash_tagline_color";
  static const String splashAnimation = "$splash_animation";
  static const int splashDuration = $splash_duration;
  static const String splashUrl = "$splash_url";
  static const String splashBg = "$splash_bg";

  // Bottom Menu Configuration
  static const String bottommenuItems = "$bottommenu_items";
  static const String bottommenuBgColor = "$bottommenu_bg_color";
  static const String bottommenuActiveTabColor = "$bottommenu_active_tab_color";
  static const String bottommenuTextColor = "$bottommenu_text_color";
  static const String bottommenuIconColor = "$bottommenu_icon_color";
  static const String bottommenuIconPosition = "$bottommenu_icon_position";
  static const String bottommenuFont = "$bottommenu_font";
  static const double bottommenuFontSize = $bottommenu_font_size;
  static const bool bottommenuFontBold = $bottommenu_font_bold;
  static const bool bottommenuFontItalic = $bottommenu_font_italic;

  // Firebase Configuration
  static const String firebaseConfigAndroid = "$firebase_config_android";
  static const String firebaseConfigIos = "$firebase_config_ios";
}
EOF
    
    # Validate the generated file
    if dart analyze test_env_config/env_config.dart > /dev/null 2>&1; then
        log_success "$test_name: PASSED"
        return 0
    else
        log_error "$test_name: FAILED"
        dart analyze test_env_config/env_config.dart
        return 1
    fi
}

# Main test function
main() {
    echo "🧪 Environment Config Generation Tests"
    echo "====================================="
    
    local test_results=()
    
    # Test 1: Basic variable generation
    test_env_generation "Basic Variables" "Basic environment variable generation"
    test_results+=($?)
    
    # Test 2: Empty variables
    export FIREBASE_CONFIG_ANDROID=""
    export FIREBASE_CONFIG_IOS=""
    test_env_generation "Empty Variables" "Empty Firebase config variables"
    test_results+=($?)
    
    # Test 3: Missing variables
    unset FIREBASE_CONFIG_ANDROID
    unset FIREBASE_CONFIG_IOS
    test_env_generation "Missing Variables" "Missing Firebase config variables"
    test_results+=($?)
    
    # Summary
    echo ""
    echo "📊 Test Results Summary:"
    echo "========================"
    
    local passed=0
    local failed=0
    
    for result in "${test_results[@]}"; do
        if [ "$result" -eq 0 ]; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo "✅ Passed: $passed"
    echo "❌ Failed: $failed"
    echo "📋 Total: ${#test_results[@]}"
    
    if [ "$failed" -eq 0 ]; then
        log_success "🎉 All env_config.dart generation tests passed!"
    else
        log_error "❌ Some tests failed. Please check the issues above."
    fi
    
    # Cleanup
    rm -rf test_env_config
    
    exit $failed
}

# Run main function
main "$@" 