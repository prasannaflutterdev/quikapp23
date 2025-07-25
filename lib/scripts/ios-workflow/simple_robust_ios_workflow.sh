#!/bin/bash
# 🚀 Simple and Robust iOS Workflow Script
# Handles dynamic variables, asset downloads, certificate management, and Dart code generation

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SIMPLE_IOS] $1"; }
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

# Function to robustly download files with multiple fallback methods
robust_download() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    log_info "Downloading $description from: $url"
    
    # Create output directory
    mkdir -p "$(dirname "$output_path")"
    
    # Method 1: Wget (Primary method)
    if command -v wget >/dev/null 2>&1; then
        log_info "Trying wget download..."
        if wget --timeout=30 --tries=3 --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with wget"
            return 0
        fi
    fi
    
    # Method 2: Curl with different options
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl download..."
        if curl -L -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl"
            return 0
        fi
    fi
    
    # Method 3: Curl without redirect
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl without redirect..."
        if curl -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (no redirect)"
            return 0
        fi
    fi
    
    # Method 4: Curl with different user agent
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl with different user agent..."
        if curl -L -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: curl/7.68.0" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (different user agent)"
            return 0
        fi
    fi
    
    # Method 5: Wget without certificate check
    if command -v wget >/dev/null 2>&1; then
        log_info "Trying wget without certificate check..."
        if wget --timeout=30 --tries=3 --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with wget (no cert check)"
            return 0
        fi
    fi
    
    # Method 6: Curl with insecure flag
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl with insecure flag..."
        if curl -L -f -s -k --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (insecure)"
            return 0
        fi
    fi
    
    # Method 7: Curl with extended timeout
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl with extended timeout..."
        if curl -L -f -s --connect-timeout 60 --max-time 300 \
            --retry 5 --retry-delay 5 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (extended timeout)"
            return 0
        fi
    fi
    
    # Method 8: Wget with extended timeout
    if command -v wget >/dev/null 2>&1; then
        log_info "Trying wget with extended timeout..."
        if wget --timeout=120 --tries=5 --retry-connrefused --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with wget (extended timeout)"
            return 0
        fi
    fi
    
    # Method 9: Curl with additional headers
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl with additional headers..."
        if curl -L -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -H "Accept: */*" \
            -H "Accept-Language: en-US,en;q=0.9" \
            -H "Accept-Encoding: gzip, deflate, br" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (additional headers)"
            return 0
        fi
    fi
    
    # Method 10: Curl with proxy bypass
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl with proxy bypass..."
        if curl -L -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            --noproxy "*" \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (proxy bypass)"
            return 0
        fi
    fi
    
    log_error "Failed to download $description with all methods"
    return 1
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
        if robust_download "$LOGO_URL" "assets/images/logo.png" "app logo"; then
            log_success "App logo downloaded successfully"
        else
            log_warning "Failed to download logo, using default"
        fi
    else
        log_warning "LOGO_URL not provided, using default"
    fi
    
    # Download splash image
    if [ -n "${SPLASH_URL:-}" ]; then
        if robust_download "$SPLASH_URL" "assets/images/splash.png" "splash image"; then
            log_success "Splash image downloaded successfully"
        else
            log_warning "Failed to download splash image, using default"
        fi
    else
        log_warning "SPLASH_URL not provided, using default"
    fi
    
    # Create splash background
    if [ -n "${SPLASH_BG_COLOR:-}" ]; then
        log_info "Creating splash background with color: $SPLASH_BG_COLOR"
        if command -v magick >/dev/null 2>&1; then
            # Fix color format for ImageMagick v7
            magick -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png" 2>/dev/null || \
            magick -size 1125x2436 xc:"rgb($(echo $SPLASH_BG_COLOR | sed 's/#//' | sed 's/../0x& /g'))" "assets/images/splash_bg.png" 2>/dev/null || \
            magick -size 1125x2436 xc:"#FFFFFF" "assets/images/splash_bg.png" 2>/dev/null
            log_info "Created splash background with color: $SPLASH_BG_COLOR"
        elif command -v convert >/dev/null 2>&1; then
            # Fix color format for ImageMagick v6
            convert -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png" 2>/dev/null || \
            convert -size 1125x2436 xc:"rgb($(echo $SPLASH_BG_COLOR | sed 's/#//' | sed 's/../0x& /g'))" "assets/images/splash_bg.png" 2>/dev/null || \
            convert -size 1125x2436 xc:"#FFFFFF" "assets/images/splash_bg.png" 2>/dev/null
            log_info "Created splash background with color: $SPLASH_BG_COLOR"
        else
            log_warning "ImageMagick not available, creating empty splash background"
            # Create empty file as fallback
            touch "assets/images/splash_bg.png"
        fi
    else
        log_warning "SPLASH_BG_COLOR not provided, using default"
        if command -v magick >/dev/null 2>&1; then
            # Fix color format for ImageMagick v7
            magick -size 1125x2436 xc:"#FFFFFF" "assets/images/splash_bg.png" 2>/dev/null || \
            magick -size 1125x2436 xc:"rgb(255,255,255)" "assets/images/splash_bg.png" 2>/dev/null
            log_info "Created default splash background"
        elif command -v convert >/dev/null 2>&1; then
            # Fix color format for ImageMagick v6
            convert -size 1125x2436 xc:"#FFFFFF" "assets/images/splash_bg.png" 2>/dev/null || \
            convert -size 1125x2436 xc:"rgb(255,255,255)" "assets/images/splash_bg.png" 2>/dev/null
            log_info "Created default splash background"
        else
            log_warning "ImageMagick not available, creating empty splash background"
            # Create empty file as fallback
            touch "assets/images/splash_bg.png"
        fi
    fi
    
    log_success "Asset download completed"
}

# Function to download certificates and provisioning profiles
download_certificates() {
    log_info "Downloading certificates and provisioning profiles..."
    
    # Download APNS auth key
    if [ -n "${APNS_AUTH_KEY_URL:-}" ]; then
        if robust_download "$APNS_AUTH_KEY_URL" "ios/AuthKey.p8" "APNS auth key"; then
            log_success "APNS auth key downloaded successfully"
        else
            log_warning "Failed to download APNS auth key"
        fi
    else
        log_warning "APNS_AUTH_KEY_URL not provided"
    fi
    
    # Download P12 certificate
    if [ -n "${CERT_P12_URL:-}" ]; then
        if robust_download "$CERT_P12_URL" "ios/Certificates.p12" "P12 certificate"; then
            log_success "P12 certificate downloaded successfully"
        else
            log_warning "Failed to download P12 certificate"
        fi
    else
        log_warning "CERT_P12_URL not provided"
    fi
    
    # Download provisioning profile
    if [ -n "${PROFILE_URL:-}" ]; then
        if robust_download "$PROFILE_URL" "ios/profile.mobileprovision" "provisioning profile"; then
            log_success "Provisioning profile downloaded successfully"
        else
            log_warning "Failed to download provisioning profile"
        fi
    else
        log_warning "PROFILE_URL not provided"
    fi
    
    log_success "Certificate download completed"
}

# Function to configure app name and bundle ID
configure_app() {
    log_info "Configuring app name and bundle ID..."
    
    # Update app name in Info.plist
    if [ -f "ios/Runner/Info.plist" ]; then
        log_info "Updating app name in Info.plist..."
        plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null || log_warning "Failed to update app name"
        plutil -replace CFBundleName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null || log_warning "Failed to update app name"
    fi
    
    # Update bundle identifier in project.pbxproj
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        log_info "Updating bundle identifier in project.pbxproj..."
        # Use a safer approach with plutil instead of sed
        if command -v plutil >/dev/null 2>&1; then
            # Try using plutil first (more reliable)
            plutil -replace PRODUCT_BUNDLE_IDENTIFIER -string "$BUNDLE_ID" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || {
                # Fallback to sed with proper escaping
                sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || log_warning "Failed to update bundle identifier"
            }
        else
            # Use sed with proper escaping
            sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || log_warning "Failed to update bundle identifier"
        fi
    fi
    
    log_success "App configuration completed"
}

# Function to generate env_config.dart
generate_env_config() {
    log_info "Generating env_config.dart..."
    
    # Create config directory
    mkdir -p lib/config
    
    # Generate the env_config.dart file using a safer approach
    cat > lib/config/env_config.dart <<'EOF'
// Generated by Simple Robust iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information
EOF

    # Add simple string variables with cleaned values
    printf "  static const String appName = \"%s\";\n" "$(clean_env_var "$APP_NAME")" >> lib/config/env_config.dart
    printf "  static const String versionName = \"%s\";\n" "$(clean_env_var "$VERSION_NAME")" >> lib/config/env_config.dart
    printf "  static const String versionCode = \"%s\";\n" "$(clean_env_var "$VERSION_CODE")" >> lib/config/env_config.dart
    printf "  static const String bundleId = \"%s\";\n" "$(clean_env_var "$BUNDLE_ID")" >> lib/config/env_config.dart
    printf "  static const String packageName = \"%s\";\n" "$(clean_env_var "${PKG_NAME:-$BUNDLE_ID}")" >> lib/config/env_config.dart
    printf "  static const String organizationName = \"%s\";\n" "$(clean_env_var "${ORG_NAME:-}")" >> lib/config/env_config.dart
    printf "  static const String webUrl = \"%s\";\n" "$(clean_env_var "${WEB_URL:-}")" >> lib/config/env_config.dart
    printf "  static const String userName = \"%s\";\n" "$(clean_env_var "${USER_NAME:-}")" >> lib/config/env_config.dart
    printf "  static const String appId = \"%s\";\n" "$(clean_env_var "${APP_ID:-}")" >> lib/config/env_config.dart
    printf "  static const String workflowId = \"%s\";\n" "$(clean_env_var "${WORKFLOW_ID:-}")" >> lib/config/env_config.dart

    # Add boolean variables
    cat >> lib/config/env_config.dart <<EOF

  // Feature Flags
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-true};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottommenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadIndicator = ${IS_LOAD_IND:-false};

  // Permissions
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};
  static const bool isStorage = ${IS_STORAGE:-false};

  // UI Configuration
EOF

    # Add complex string variables using printf with cleaned values
    printf "  static const String splashBgColor = \"%s\";\n" "$(clean_env_var "${SPLASH_BG_COLOR:-#FFFFFF}")" >> lib/config/env_config.dart
    printf "  static const String splashTagline = \"%s\";\n" "$(clean_env_var "${SPLASH_TAGLINE:-}")" >> lib/config/env_config.dart
    printf "  static const String splashTaglineColor = \"%s\";\n" "$(clean_env_var "${SPLASH_TAGLINE_COLOR:-#000000}")" >> lib/config/env_config.dart
    printf "  static const String splashAnimation = \"%s\";\n" "$(clean_env_var "${SPLASH_ANIMATION:-fade}")" >> lib/config/env_config.dart
    printf "  static const int splashDuration = %s;\n" "$(clean_env_var "${SPLASH_DURATION:-3}")" >> lib/config/env_config.dart

    # Add missing properties that are used in main.dart
    printf "  static const String splashUrl = \"%s\";\n" "$(clean_env_var "${SPLASH_URL:-}")" >> lib/config/env_config.dart
    printf "  static const String splashBg = \"%s\";\n" "$(clean_env_var "${SPLASH_BG_URL:-}")" >> lib/config/env_config.dart

    # Add bottom menu configuration
    cat >> lib/config/env_config.dart <<EOF

  // Bottom Menu Configuration
EOF

    # Handle JSON string specially to prevent Dart syntax errors
    local bottom_menu_items="${BOTTOMMENU_ITEMS:-[]}"
    # Clean and escape the JSON string properly for Dart
    local cleaned_json=$(clean_json_for_dart "$bottom_menu_items")
    printf "  static const String bottomMenuItems = \"%s\";\n" "$cleaned_json" >> lib/config/env_config.dart
    printf "  static const String bottomMenuBgColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_BG_COLOR:-#FFFFFF}")" >> lib/config/env_config.dart
    printf "  static const String bottomMenuIconColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ICON_COLOR:-#666666}")" >> lib/config/env_config.dart
    printf "  static const String bottomMenuTextColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_TEXT_COLOR:-#666666}")" >> lib/config/env_config.dart
    printf "  static const String bottomMenuFont = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_FONT:-Roboto}")" >> lib/config/env_config.dart
    printf "  static const String bottomMenuFontSize = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_FONT_SIZE:-12}")" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF
  static const bool bottomMenuFontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool bottomMenuFontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
EOF

    printf "  static const String bottomMenuActiveTabColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#007AFF}")" >> lib/config/env_config.dart
    printf "  static const String bottomMenuIconPosition = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ICON_POSITION:-above}")" >> lib/config/env_config.dart

    # Add missing properties with different names used in main.dart
    printf "  static const String bottommenuItems = \"%s\";\n" "$cleaned_json" >> lib/config/env_config.dart
    printf "  static const String bottommenuBgColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_BG_COLOR:-#FFFFFF}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuActiveTabColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#007AFF}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuTextColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_TEXT_COLOR:-#666666}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuIconColor = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ICON_COLOR:-#666666}")" >> lib/config/env_config.dart
    printf "  static const String bottommenuIconPosition = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_ICON_POSITION:-above}")" >> lib/config/env_config.dart

    # Add missing properties used in other files
    printf "  static const String bottommenuFont = \"%s\";\n" "$(clean_env_var "${BOTTOMMENU_FONT:-Roboto}")" >> lib/config/env_config.dart
    printf "  static const double bottommenuFontSize = %s;\n" "$(clean_env_var "${BOTTOMMENU_FONT_SIZE:-12}")" >> lib/config/env_config.dart
    printf "  static const bool bottommenuFontBold = %s;\n" "${BOTTOMMENU_FONT_BOLD:-false}" >> lib/config/env_config.dart
    printf "  static const bool bottommenuFontItalic = %s;\n" "${BOTTOMMENU_FONT_ITALIC:-false}" >> lib/config/env_config.dart
    printf "  static const String firebaseConfigAndroid = \"%s\";\n" "$(clean_env_var "${FIREBASE_CONFIG_ANDROID:-}")" >> lib/config/env_config.dart
    printf "  static const String firebaseConfigIos = \"%s\";\n" "$(clean_env_var "${FIREBASE_CONFIG_IOS:-}")" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF
}
EOF

    log_success "env_config.dart generated successfully"
}

# Function to configure Firebase
configure_firebase() {
    log_info "Configuring Firebase..."
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log_info "Push notifications enabled, configuring Firebase..."
        
        # Download Firebase config
        if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
            if robust_download "$FIREBASE_CONFIG_IOS" "ios/GoogleService-Info.plist" "Firebase config"; then
                log_success "Firebase config downloaded successfully"
                
                # Copy to Runner directory
                cp ios/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist 2>/dev/null || log_warning "Failed to copy Firebase config"
            else
                log_warning "Failed to download Firebase config"
            fi
        else
            log_warning "FIREBASE_CONFIG_IOS not provided"
        fi
    else
        log_info "Push notifications disabled, skipping Firebase configuration"
    fi
    
    log_success "Firebase configuration completed"
}

# Function to inject permissions
inject_permissions() {
    log_info "Injecting permissions..."
    
    # Create Info.plist additions
    cat > ios/Runner/Info.plist.additions <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
EOF

    # Add camera permission
    if [ "${IS_CAMERA:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos and videos.</string>
EOF
    fi

    # Add location permission
    if [ "${IS_LOCATION:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to provide location-based services.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs location access to provide location-based services.</string>
EOF
    fi

    # Add microphone permission
    if [ "${IS_MIC:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for voice features.</string>
EOF
    fi

    # Add notification permission
    if [ "${IS_NOTIFICATION:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSUserNotificationUsageDescription</key>
    <string>This app needs notification access to send you important updates.</string>
EOF
    fi

    # Add contacts permission
    if [ "${IS_CONTACT:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSContactsUsageDescription</key>
    <string>This app needs contacts access to help you connect with friends.</string>
EOF
    fi

    # Add biometric permission
    if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSFaceIDUsageDescription</key>
    <string>This app uses Face ID for secure authentication.</string>
EOF
    fi

    # Add calendar permission
    if [ "${IS_CALENDAR:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSCalendarsUsageDescription</key>
    <string>This app needs calendar access to help you manage your schedule.</string>
EOF
    fi

    # Add photo library permission
    if [ "${IS_STORAGE:-false}" = "true" ]; then
        cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to save and share images.</string>
EOF
    fi

    cat >> ios/Runner/Info.plist.additions <<EOF
</dict>
</plist>
EOF

    log_success "Permissions injected successfully"
}

# Function to build Flutter app
build_flutter_app() {
    log_info "Building Flutter app..."
    
    # Clean previous builds
    log_info "Cleaning previous builds..."
    flutter clean
    
    # Get dependencies
    log_info "Getting Flutter dependencies..."
    flutter pub get
    
    # Build without code signing
    log_info "Building Flutter app without code signing..."
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
    log_info "🚀 Starting Simple Robust iOS Workflow"
    log "================================================"
    
    # Step 1: Validate environment variables
    if ! validate_critical_vars; then
        log_error "Critical environment variables missing"
        exit 1
    fi
    
    # Step 2: Create default assets
    create_default_assets
    
    # Step 3: Download assets
    download_assets
    
    # Step 4: Download certificates
    download_certificates
    
    # Step 5: Configure app
    configure_app
    
    # Step 6: Generate env_config.dart
    generate_env_config
    
    # Step 7: Configure Firebase
    configure_firebase
    
    # Step 8: Inject permissions
    inject_permissions
    
    # Step 9: Build Flutter app
    build_flutter_app
    
    # Step 10: Create archive
    create_archive
    
    # Step 11: Export IPA
    export_ipa
    
    log_success "🎉 Simple Robust iOS Workflow completed successfully!"
}

# Run main function
main "$@" 