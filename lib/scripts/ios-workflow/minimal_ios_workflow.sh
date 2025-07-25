#!/bin/bash
# 🚀 Minimal iOS Workflow Script
# Only generates Dart-required fields, skips validation (handled by frontend)

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [MINIMAL_IOS] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Function to clean environment variables (remove emoji and non-ASCII characters)
clean_env_var() {
    local var_value="$1"
    # Remove emoji and non-ASCII characters, and trim whitespace
    echo "$var_value" | LC_ALL=C sed 's/[^[:print:][:space:]]//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r\n\t'
}

# Function to clean and escape JSON strings for Dart
clean_json_for_dart() {
    local json_string="$1"
    # Remove emoji and non-ASCII characters using macOS-compatible approach
    local cleaned=$(echo "$json_string" | LC_ALL=C sed 's/[^[:print:][:space:]]//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r\n\t')
    # Escape quotes for Dart string literals
    echo "$cleaned" | sed 's/"/\\"/g'
}

# Function to validate critical environment variables (SKIPPED - Frontend handles validation)
validate_critical_vars() {
    log_info "Skipping variable validation - Frontend UI handles validation"
    log_success "Variable validation skipped"
    return 0
}

# Function to create default assets
create_default_assets() {
    log_info "Creating default assets..."
    
    # Create assets directory
    mkdir -p assets/images
    
    # Create default logo if not exists
    if [ ! -f "assets/images/logo.png" ]; then
        log_info "Creating default logo..."
        if command -v magick >/dev/null 2>&1; then
            magick -size 512x512 xc:"#007AFF" assets/images/logo.png 2>/dev/null || \
            magick -size 512x512 xc:"#FFFFFF" assets/images/logo.png 2>/dev/null
        elif command -v convert >/dev/null 2>&1; then
            convert -size 512x512 xc:"#007AFF" assets/images/logo.png 2>/dev/null || \
            convert -size 512x512 xc:"#FFFFFF" assets/images/logo.png 2>/dev/null
        else
            # Create empty file as fallback
            touch assets/images/logo.png
        fi
    fi
    
    # Create default splash if not exists
    if [ ! -f "assets/images/splash.png" ]; then
        log_info "Creating default splash..."
        if command -v magick >/dev/null 2>&1; then
            magick -size 1125x2436 xc:"#007AFF" assets/images/splash.png 2>/dev/null || \
            magick -size 1125x2436 xc:"#FFFFFF" assets/images/splash.png 2>/dev/null
        elif command -v convert >/dev/null 2>&1; then
            convert -size 1125x2436 xc:"#007AFF" assets/images/splash.png 2>/dev/null || \
            convert -size 1125x2436 xc:"#FFFFFF" assets/images/splash.png 2>/dev/null
        else
            # Create empty file as fallback
            touch assets/images/splash.png
        fi
    fi
    
    log_success "Default assets created"
}

# Function to download assets
download_assets() {
    log_info "Downloading assets..."
    
    # Download app logo
    if [ -n "${LOGO_URL:-}" ]; then
        if curl -L -f -s --connect-timeout 30 --max-time 120 -o "assets/images/logo.png" "$LOGO_URL" 2>/dev/null; then
            log_success "App logo downloaded successfully"
        else
            log_warning "Failed to download logo, using default"
        fi
    else
        log_warning "LOGO_URL not provided, using default"
    fi
    
    # Download splash image
    if [ -n "${SPLASH_URL:-}" ]; then
        if curl -L -f -s --connect-timeout 30 --max-time 120 -o "assets/images/splash.png" "$SPLASH_URL" 2>/dev/null; then
            log_success "Splash image downloaded successfully"
        else
            log_warning "Failed to download splash image, using default"
        fi
    else
        log_warning "SPLASH_URL not provided, using default"
    fi
    
    log_success "Asset download completed"
}

# Function to configure app
configure_app() {
    log_info "Configuring app..."
    
    # Update app name in Info.plist
    if [ -n "${APP_NAME:-}" ]; then
        plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null || log_warning "Failed to update app name"
        plutil -replace CFBundleName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null || log_warning "Failed to update app name"
    fi
    
    # Update bundle identifier
    if [ -n "${BUNDLE_ID:-}" ]; then
        # Use a safer approach with plutil instead of sed
        if command -v plutil >/dev/null 2>&1; then
            # Try using plutil first (more reliable)
            plutil -replace PRODUCT_BUNDLE_IDENTIFIER -string "$BUNDLE_ID" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || {
                log_warning "plutil failed, trying sed fallback"
                sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || log_warning "Failed to update bundle ID"
            }
        else
            # Fallback to sed
            sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || log_warning "Failed to update bundle ID"
        fi
    fi
    
    log_success "App configuration completed"
}

# Function to generate env_config.dart (MINIMAL - Only Dart-required fields)
generate_env_config() {
    log_info "Generating env_config.dart with minimal required fields..."
    
    # Create config directory
    mkdir -p lib/config
    
    # Function to safely get environment variable with fallback
    safe_env_var() {
        local var_name="$1"
        local fallback="$2"
        local value="${!var_name:-}"
        
        # If the value is the same as the variable name, it means it's undefined
        if [ "$value" = "\$$var_name" ] || [ "$value" = "$var_name" ] || [ -z "$value" ]; then
            echo "$fallback"
        else
            # Clean the value to remove any problematic characters
            echo "$value" | tr -d '\r\n\t' | sed 's/[^[:print:]]//g'
        fi
    }
    
    # Generate the env_config.dart file with only Dart-required fields
    cat > lib/config/env_config.dart <<'EOF'
// Generated by Minimal iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information (Dart-required only)
EOF

    # Add only the variables that are actually used in Dart code with safe fallbacks
    local app_name=$(safe_env_var "APP_NAME" "")
    local web_url=$(safe_env_var "WEB_URL" "")
    
    printf "  static const String appName = \"%s\";\n" "$(clean_env_var "$app_name")" >> lib/config/env_config.dart
    printf "  static const String webUrl = \"%s\";\n" "$(clean_env_var "$web_url")" >> lib/config/env_config.dart

    # Add boolean variables (Dart-required only) with safe fallbacks
    cat >> lib/config/env_config.dart <<EOF

  // Feature Flags (Dart-required only)
EOF

    # Handle boolean variables safely
    local push_notify=$(safe_env_var "PUSH_NOTIFY" "false")
    local is_chatbot=$(safe_env_var "IS_CHATBOT" "false")
    local is_domain_url=$(safe_env_var "IS_DOMAIN_URL" "false")
    local is_splash=$(safe_env_var "IS_SPLASH" "true")
    local is_pulldown=$(safe_env_var "IS_PULLDOWN" "false")
    local is_bottommenu=$(safe_env_var "IS_BOTTOMMENU" "false")
    local is_load_ind=$(safe_env_var "IS_LOAD_IND" "false")
    
    printf "  static const bool pushNotify = %s;\n" "$push_notify" >> lib/config/env_config.dart
    printf "  static const bool isChatbot = %s;\n" "$is_chatbot" >> lib/config/env_config.dart
    printf "  static const bool isDomainUrl = %s;\n" "$is_domain_url" >> lib/config/env_config.dart
    printf "  static const bool isSplash = %s;\n" "$is_splash" >> lib/config/env_config.dart
    printf "  static const bool isPulldown = %s;\n" "$is_pulldown" >> lib/config/env_config.dart
    printf "  static const bool isBottommenu = %s;\n" "$is_bottommenu" >> lib/config/env_config.dart
    printf "  static const bool isLoadIndicator = %s;\n" "$is_load_ind" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF

  // Permissions (Dart-required only)
EOF

    # Handle permission variables safely
    local is_camera=$(safe_env_var "IS_CAMERA" "false")
    local is_location=$(safe_env_var "IS_LOCATION" "false")
    local is_mic=$(safe_env_var "IS_MIC" "false")
    local is_notification=$(safe_env_var "IS_NOTIFICATION" "false")
    local is_contact=$(safe_env_var "IS_CONTACT" "false")
    local is_biometric=$(safe_env_var "IS_BIOMETRIC" "false")
    local is_calendar=$(safe_env_var "IS_CALENDAR" "false")
    
    printf "  static const bool isCamera = %s;\n" "$is_camera" >> lib/config/env_config.dart
    printf "  static const bool isLocation = %s;\n" "$is_location" >> lib/config/env_config.dart
    printf "  static const bool isMic = %s;\n" "$is_mic" >> lib/config/env_config.dart
    printf "  static const bool isNotification = %s;\n" "$is_notification" >> lib/config/env_config.dart
    printf "  static const bool isContact = %s;\n" "$is_contact" >> lib/config/env_config.dart
    printf "  static const bool isBiometric = %s;\n" "$is_biometric" >> lib/config/env_config.dart
    printf "  static const bool isCalendar = %s;\n" "$is_calendar" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF

  // UI Configuration (Dart-required only)
EOF

    # Handle UI configuration variables safely
    local splash_bg_color=$(safe_env_var "SPLASH_BG_COLOR" "#FFFFFF")
    local splash_tagline=$(safe_env_var "SPLASH_TAGLINE" "")
    local splash_tagline_color=$(safe_env_var "SPLASH_TAGLINE_COLOR" "#000000")
    local splash_animation=$(safe_env_var "SPLASH_ANIMATION" "fade")
    local splash_duration=$(safe_env_var "SPLASH_DURATION" "3")
    local splash_url=$(safe_env_var "SPLASH_URL" "")
    local splash_bg=$(safe_env_var "SPLASH_BG_URL" "")
    
    printf "  static const String splashBgColor = \"%s\";\n" "$(clean_env_var "$splash_bg_color")" >> lib/config/env_config.dart
    printf "  static const String splashTagline = \"%s\";\n" "$(clean_env_var "$splash_tagline")" >> lib/config/env_config.dart
    printf "  static const String splashTaglineColor = \"%s\";\n" "$(clean_env_var "$splash_tagline_color")" >> lib/config/env_config.dart
    printf "  static const String splashAnimation = \"%s\";\n" "$(clean_env_var "$splash_animation")" >> lib/config/env_config.dart
    printf "  static const int splashDuration = %s;\n" "$(clean_env_var "$splash_duration")" >> lib/config/env_config.dart
    printf "  static const String splashUrl = \"%s\";\n" "$(clean_env_var "$splash_url")" >> lib/config/env_config.dart
    printf "  static const String splashBg = \"%s\";\n" "$(clean_env_var "$splash_bg")" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF

  // Bottom Menu Configuration (Dart-required only)
EOF

    # Handle bottom menu variables safely
    local bottom_menu_items=$(safe_env_var "BOTTOMMENU_ITEMS" "[]")
    local bottom_menu_bg_color=$(safe_env_var "BOTTOMMENU_BG_COLOR" "#FFFFFF")
    local bottom_menu_active_tab_color=$(safe_env_var "BOTTOMMENU_ACTIVE_TAB_COLOR" "#007AFF")
    local bottom_menu_text_color=$(safe_env_var "BOTTOMMENU_TEXT_COLOR" "#666666")
    local bottom_menu_icon_color=$(safe_env_var "BOTTOMMENU_ICON_COLOR" "#666666")
    local bottom_menu_icon_position=$(safe_env_var "BOTTOMMENU_ICON_POSITION" "above")
    local bottom_menu_font=$(safe_env_var "BOTTOMMENU_FONT" "Roboto")
    local bottom_menu_font_size=$(safe_env_var "BOTTOMMENU_FONT_SIZE" "12")
    local bottom_menu_font_bold=$(safe_env_var "BOTTOMMENU_FONT_BOLD" "false")
    local bottom_menu_font_italic=$(safe_env_var "BOTTOMMENU_FONT_ITALIC" "false")
    
    # Debug: Log the values to see what's being generated
    echo "🔍 Debug: bottom_menu_items = '$bottom_menu_items'"
    echo "🔍 Debug: bottom_menu_font_size = '$bottom_menu_font_size'"
    
    # Handle JSON string safely - use a simple approach to avoid syntax errors
    if [ "$bottom_menu_items" = "[]" ] || [ -z "$bottom_menu_items" ]; then
        printf "  static const String bottommenuItems = \"[]\";\n" >> lib/config/env_config.dart
    else
        # For complex JSON, use a safer approach with more robust cleaning
        local escaped_json=$(echo "$bottom_menu_items" | tr -d '\r\n\t' | sed 's/"/\\"/g' | sed 's/[^[:print:]]//g')
        # Ensure the JSON is properly terminated
        if [[ "$escaped_json" != *"]" ]]; then
            escaped_json="${escaped_json}]"
        fi
        printf "  static const String bottommenuItems = \"%s\";\n" "$escaped_json" >> lib/config/env_config.dart
    fi
    printf "  static const String bottommenuBgColor = \"%s\";\n" "$(clean_env_var "$bottom_menu_bg_color")" >> lib/config/env_config.dart
    printf "  static const String bottommenuActiveTabColor = \"%s\";\n" "$(clean_env_var "$bottom_menu_active_tab_color")" >> lib/config/env_config.dart
    printf "  static const String bottommenuTextColor = \"%s\";\n" "$(clean_env_var "$bottom_menu_text_color")" >> lib/config/env_config.dart
    printf "  static const String bottommenuIconColor = \"%s\";\n" "$(clean_env_var "$bottom_menu_icon_color")" >> lib/config/env_config.dart
    printf "  static const String bottommenuIconPosition = \"%s\";\n" "$(clean_env_var "$bottom_menu_icon_position")" >> lib/config/env_config.dart
    printf "  static const String bottommenuFont = \"%s\";\n" "$(clean_env_var "$bottom_menu_font")" >> lib/config/env_config.dart
    printf "  static const double bottommenuFontSize = %s;\n" "$(clean_env_var "$bottom_menu_font_size")" >> lib/config/env_config.dart
    printf "  static const bool bottommenuFontBold = %s;\n" "$bottom_menu_font_bold" >> lib/config/env_config.dart
    printf "  static const bool bottommenuFontItalic = %s;\n" "$bottom_menu_font_italic" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF

  // Firebase Configuration (Dart-required only)
EOF

    # Handle Firebase configs safely
    local firebase_android=$(safe_env_var "FIREBASE_CONFIG_ANDROID" "")
    local firebase_ios=$(safe_env_var "FIREBASE_CONFIG_IOS" "")
    
    printf "  static const String firebaseConfigAndroid = \"%s\";\n" "$(clean_env_var "$firebase_android")" >> lib/config/env_config.dart
    printf "  static const String firebaseConfigIos = \"%s\";\n" "$(clean_env_var "$firebase_ios")" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF
}
EOF

    # Validate the generated file
    echo "🔍 Validating generated env_config.dart..."
    if dart analyze lib/config/env_config.dart > /dev/null 2>&1; then
        echo "✅ env_config.dart generated successfully with minimal required fields"
    else
        echo "❌ Error: Generated env_config.dart has syntax errors"
        echo "🔍 Generated file content:"
        cat lib/config/env_config.dart
        echo "🔍 Dart analysis output:"
        dart analyze lib/config/env_config.dart
        
        # Try to fix common issues
        echo "🔧 Attempting to fix common syntax issues..."
        sed -i '' 's/static const String bottommenuItems = ".*"/static const String bottommenuItems = "[]"/' lib/config/env_config.dart
        sed -i '' 's/static const String firebaseConfigAndroid = ".*"/static const String firebaseConfigAndroid = ""/' lib/config/env_config.dart
        sed -i '' 's/static const String firebaseConfigIos = ".*"/static const String firebaseConfigIos = ""/' lib/config/env_config.dart
        
        # Validate again
        if dart analyze lib/config/env_config.dart > /dev/null 2>&1; then
            echo "✅ Fixed env_config.dart syntax errors"
        else
            echo "❌ Could not fix syntax errors, using fallback configuration"
            # Generate a minimal fallback file
            cat > lib/config/env_config.dart <<'EOF'
// Generated by Minimal iOS Workflow Script (Fallback)
// Do not edit manually

class EnvConfig {
  // App Information
  static const String appName = "";
  static const String webUrl = "";

  // Feature Flags
  static const bool pushNotify = false;
  static const bool isChatbot = false;
  static const bool isDomainUrl = false;
  static const bool isSplash = true;
  static const bool isPulldown = false;
  static const bool isBottommenu = false;
  static const bool isLoadIndicator = false;

  // Permissions
  static const bool isCamera = false;
  static const bool isLocation = false;
  static const bool isMic = false;
  static const bool isNotification = false;
  static const bool isContact = false;
  static const bool isBiometric = false;
  static const bool isCalendar = false;

  // UI Configuration
  static const String splashBgColor = "#FFFFFF";
  static const String splashTagline = "";
  static const String splashTaglineColor = "#000000";
  static const String splashAnimation = "fade";
  static const int splashDuration = 3;
  static const String splashUrl = "";
  static const String splashBg = "";

  // Bottom Menu Configuration
  static const String bottommenuItems = "[]";
  static const String bottommenuBgColor = "#FFFFFF";
  static const String bottommenuActiveTabColor = "#007AFF";
  static const String bottommenuTextColor = "#666666";
  static const String bottommenuIconColor = "#666666";
  static const String bottommenuIconPosition = "above";
  static const String bottommenuFont = "Roboto";
  static const double bottommenuFontSize = 12;
  static const bool bottommenuFontBold = false;
  static const bool bottommenuFontItalic = false;

  // Firebase Configuration
  static const String firebaseConfigAndroid = "";
  static const String firebaseConfigIos = "";
}
EOF
            echo "✅ Generated fallback env_config.dart"
        fi
    fi
}

# Function to configure Firebase
configure_firebase() {
    log_info "Configuring Firebase..."
    
    # Download Firebase config files if PUSH_NOTIFY is true
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
            if curl -L -f -s --connect-timeout 30 --max-time 120 -o "ios/Runner/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS" 2>/dev/null; then
                log_success "Firebase iOS config downloaded successfully"
            else
                log_warning "Failed to download Firebase iOS config"
            fi
        else
            log_warning "FIREBASE_CONFIG_IOS not provided"
        fi
    else
        log_info "Firebase not configured (PUSH_NOTIFY=false)"
    fi
    
    log_success "Firebase configuration completed"
}

# Function to inject permissions
inject_permissions() {
    log_info "Injecting permissions..."
    
    # Update Info.plist with permissions based on environment variables
    local info_plist="ios/Runner/Info.plist"
    
    # Camera permission
    if [ "${IS_CAMERA:-false}" = "true" ]; then
        plutil -insert NSCameraUsageDescription -string "This app needs camera access" "$info_plist" 2>/dev/null || log_warning "Failed to add camera permission"
    fi
    
    # Location permission
    if [ "${IS_LOCATION:-false}" = "true" ]; then
        plutil -insert NSLocationWhenInUseUsageDescription -string "This app needs location access" "$info_plist" 2>/dev/null || log_warning "Failed to add location permission"
    fi
    
    # Microphone permission
    if [ "${IS_MIC:-false}" = "true" ]; then
        plutil -insert NSMicrophoneUsageDescription -string "This app needs microphone access" "$info_plist" 2>/dev/null || log_warning "Failed to add microphone permission"
    fi
    
    # Contact permission
    if [ "${IS_CONTACT:-false}" = "true" ]; then
        plutil -insert NSContactsUsageDescription -string "This app needs contact access" "$info_plist" 2>/dev/null || log_warning "Failed to add contact permission"
    fi
    
    # Calendar permission
    if [ "${IS_CALENDAR:-false}" = "true" ]; then
        plutil -insert NSCalendarsUsageDescription -string "This app needs calendar access" "$info_plist" 2>/dev/null || log_warning "Failed to add calendar permission"
    fi
    
    log_success "Permissions injection completed"
}

# Function to build Flutter app
build_flutter_app() {
    log_info "Building Flutter app..."
    
    # Clean and get dependencies
    flutter clean
    flutter pub get
    
    # Build without code signing
    flutter build ios --release --no-codesign
    
    log_success "Flutter build completed"
}

# Function to create archive
create_archive() {
    log_info "Creating Xcode archive..."
    
    # Create archive
    xcodebuild -workspace ios/Runner.xcworkspace \
               -scheme Runner \
               -configuration Release \
               -archivePath build/Runner.xcarchive \
               archive
    
    log_success "Archive created successfully"
}

# Function to export IPA
export_ipa() {
    log_info "Exporting IPA..."
    
    # Create export options
    cat > ios/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
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
               -archivePath build/Runner.xcarchive \
               -exportPath build/ios \
               -exportOptionsPlist ios/ExportOptions.plist
    
    log_success "IPA exported successfully"
}

# Main workflow function
main() {
    log_info "🚀 Starting Minimal iOS Workflow"
    log "================================================"
    
    # Step 1: Skip validation (handled by frontend)
    validate_critical_vars
    
    # Step 2: Create default assets
    create_default_assets
    
    # Step 3: Download assets
    download_assets
    
    # Step 4: Configure app
    configure_app
    
    # Step 5: Generate env_config.dart (minimal)
    generate_env_config
    
    # Step 6: Configure Firebase
    configure_firebase
    
    # Step 7: Inject permissions
    inject_permissions
    
    # Step 8: Build Flutter app
    build_flutter_app
    
    # Step 9: Create archive
    create_archive
    
    # Step 10: Export IPA
    export_ipa
    
    log_success "🎉 Minimal iOS Workflow completed successfully!"
}

# Run main function
main "$@" 