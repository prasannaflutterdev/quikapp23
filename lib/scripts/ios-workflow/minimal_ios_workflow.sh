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
    
    # Generate the env_config.dart file with only Dart-required fields
    cat > lib/config/env_config.dart <<'EOF'
// Generated by Minimal iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information (Dart-required only)
EOF

    # Add only the variables that are actually used in Dart code
    printf "  static const String appName = \"%s\";\n" "$(clean_env_var "${APP_NAME:-}")" >> lib/config/env_config.dart
    printf "  static const String webUrl = \"%s\";\n" "$(clean_env_var "${WEB_URL:-}")" >> lib/config/env_config.dart

    # Add boolean variables (Dart-required only)
    cat >> lib/config/env_config.dart <<EOF

  // Feature Flags (Dart-required only)
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-true};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottommenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadIndicator = ${IS_LOAD_IND:-false};

  // Permissions (Dart-required only)
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};

  // UI Configuration (Dart-required only)
EOF

    # Add UI configuration (Dart-required only)
    printf "  static const String splashBgColor = \"%s\";\n" "$(clean_env_var "${SPLASH_BG_COLOR:-#FFFFFF}")" >> lib/config/env_config.dart
    printf "  static const String splashTagline = \"%s\";\n" "$(clean_env_var "${SPLASH_TAGLINE:-}")" >> lib/config/env_config.dart
    printf "  static const String splashTaglineColor = \"%s\";\n" "$(clean_env_var "${SPLASH_TAGLINE_COLOR:-#000000}")" >> lib/config/env_config.dart
    printf "  static const String splashAnimation = \"%s\";\n" "$(clean_env_var "${SPLASH_ANIMATION:-fade}")" >> lib/config/env_config.dart
    printf "  static const int splashDuration = %s;\n" "$(clean_env_var "${SPLASH_DURATION:-3}")" >> lib/config/env_config.dart
    printf "  static const String splashUrl = \"%s\";\n" "$(clean_env_var "${SPLASH_URL:-}")" >> lib/config/env_config.dart
    printf "  static const String splashBg = \"%s\";\n" "$(clean_env_var "${SPLASH_BG_URL:-}")" >> lib/config/env_config.dart

    # Add bottom menu configuration (Dart-required only)
    cat >> lib/config/env_config.dart <<EOF

  // Bottom Menu Configuration (Dart-required only)
EOF

    # Handle JSON string specially to prevent Dart syntax errors
    local bottom_menu_items="${BOTTOMMENU_ITEMS:-[]}"
    # Clean and escape the JSON string properly for Dart
    local cleaned_json=$(clean_json_for_dart "$bottom_menu_items")
    printf "  static const String bottommenuItems = \"%s\";\n" "$cleaned_json" >> lib/config/env_config.dart
    printf "  static const String bottommenuBgColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_BG_COLOR:-#FFFFFF}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuActiveTabColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#007AFF}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuTextColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_TEXT_COLOR:-#666666}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuIconColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ICON_COLOR:-#666666}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuIconPosition = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ICON_POSITION:-above}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuFont = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_FONT:-Roboto}")" >> lib/config/env_config.dart
    printf "  static const double bottommenuFontSize = %s;\n" "$(clean_env_var "${BOTTOMMENU_FONT_SIZE:-12}")" >> lib/config/env_config.dart
    printf "  static const bool bottommenuFontBold = %s;\n" "${BOTTOMMENU_FONT_BOLD:-false}" >> lib/config/env_config.dart
    printf "  static const bool bottommenuFontItalic = %s;\n" "${BOTTOMMENU_FONT_ITALIC:-false}" >> lib/config/env_config.dart

    # Add Firebase configuration (Dart-required only)
    cat >> lib/config/env_config.dart <<EOF

  // Firebase Configuration (Dart-required only)
EOF
    printf "  static const String firebaseConfigAndroid = \"%s\";\n" "$(clean_env_var "${FIREBASE_CONFIG_ANDROID:-}")" >> lib/config/env_config.dart
    printf "  static const String firebaseConfigIos = \"%s\";\n" "$(clean_env_var "${FIREBASE_CONFIG_IOS:-}")" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF
}
EOF

    echo "✅ env_config.dart generated successfully with minimal required fields"
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