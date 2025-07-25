#!/bin/bash
# 🍎 Enhanced iOS Workflow Script for Codemagic
# Includes proper IPA generation, error handling, and detailed reporting

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENHANCED_IOS] $1"; }
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
mkdir -p assets/images
mkdir -p ios/certificates

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

# Ultimate download function with proven working parameters
ultimate_download() {
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
    
    # Use the exact working parameters from the debug environment
    if curl -L -f -s --connect-timeout 30 --max-time 120 -o "$output_path" "$url" 2>/dev/null; then
        log_success "$description downloaded successfully"
        return 0
    fi
    
    # Fallback: Try with different user agent
    if curl -L -f -s --connect-timeout 30 --max-time 120 -o "$output_path" \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$url" 2>/dev/null; then
        log_success "$description downloaded successfully (with custom user agent)"
        return 0
    fi
    
    # Fallback: Try without redirect
    if curl -f -s --connect-timeout 30 --max-time 120 -o "$output_path" "$url" 2>/dev/null; then
        log_success "$description downloaded successfully (without redirect)"
        return 0
    fi
    
    # Fallback: Try with wget if available
    if command -v wget >/dev/null 2>&1; then
        if wget --timeout=60 --tries=3 -O "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully (with wget)"
            return 0
        fi
    fi
    
    log_error "Failed to download $description"
    return 1
}

# Function to create default assets
create_default_assets() {
    log_info "Creating default assets..."
    
    # Create default logo if missing
    if [ ! -f "assets/images/default_logo.png" ]; then
        log_info "Creating default logo..."
        if command -v magick >/dev/null 2>&1; then
            magick -size 512x512 xc:"#007AFF" -fill white -draw "text 256,256 'Q'" assets/images/default_logo.png
            log_success "Default logo created"
        elif command -v convert >/dev/null 2>&1; then
            convert -size 512x512 xc:"#007AFF" -fill white -draw "text 256,256 'Q'" assets/images/default_logo.png
            log_success "Default logo created"
        else
            log_warning "ImageMagick not available, cannot create default logo"
        fi
    fi
    
    # Create default splash if missing
    if [ ! -f "assets/images/splash.png" ]; then
        log_info "Creating default splash..."
        if command -v magick >/dev/null 2>&1; then
            magick -size 1125x2436 xc:"#FFFFFF" -fill "#007AFF" -draw "text 562,1218 'QuikApp'" assets/images/splash.png
            log_success "Default splash created"
        elif command -v convert >/dev/null 2>&1; then
            convert -size 1125x2436 xc:"#FFFFFF" -fill "#007AFF" -draw "text 562,1218 'QuikApp'" assets/images/splash.png
            log_success "Default splash created"
        else
            log_warning "ImageMagick not available, cannot create default splash"
        fi
    fi
}

# Function to check if IPA exists and provide detailed analysis
check_ipa_generation() {
    log_info "Checking IPA file generation..."
    
    # Check for IPA in various possible locations
    local ipa_locations=(
        "build/export/Runner.ipa"
        "output/ios/Runner.ipa"
        "build/Runner.ipa"
        "*.ipa"
    )
    
    local ipa_found=false
    local found_location=""
    
    for location in "${ipa_locations[@]}"; do
        if [ -f "$location" ]; then
            ipa_found=true
            found_location="$location"
            break
        fi
    done
    
    if [ "$ipa_found" = true ]; then
        local size=$(stat -f%z "$found_location" 2>/dev/null || stat -c%s "$found_location" 2>/dev/null || echo "0")
        log_success "IPA file found: $found_location ($size bytes)"
        return 0
    else
        log_error "IPA file not found in any expected location"
        return 1
    fi
}

# Function to provide detailed error analysis
provide_error_analysis() {
    log_info "Providing detailed error analysis..."
    log "================================================"
    
    log_error "❌ IPA Generation Failed - Detailed Analysis"
    log ""
    log "🔍 Possible Causes:"
    log "1. Flutter build failed during iOS compilation"
    log "2. Xcode archive creation failed"
    log "3. IPA export failed due to code signing issues"
    log "4. Missing or invalid provisioning profiles"
    log "5. Apple Developer account access issues"
    log "6. Bundle identifier conflicts"
    log "7. Team ID or certificate issues"
    log ""
    log "🔧 Troubleshooting Steps:"
    log "1. Check Apple Developer account access"
    log "2. Verify provisioning profiles are valid"
    log "3. Ensure bundle identifier is unique"
    log "4. Check team ID and certificates"
    log "5. Review Xcode build logs for specific errors"
    log "6. Verify iOS project configuration"
    log ""
    log "📋 Required Environment Variables:"
    log "- APPLE_TEAM_ID: Your Apple Developer Team ID"
    log "- BUNDLE_ID: Your app's bundle identifier"
    log "- APP_NAME: Your app's display name"
    log ""
    log "🚀 Next Steps:"
    log "1. Run the complete build process manually"
    log "2. Check build logs for specific error messages"
    log "3. Verify Apple Developer account settings"
    log "4. Test with a simple iOS project first"
}

# Set all required variables with defaults
export WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "ios-workflow")
export USER_NAME=$(get_env_var "USER_NAME" "Admin")
export APP_ID=$(get_env_var "APP_ID" "quikapp")
export VERSION_NAME=$(get_env_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_env_var "VERSION_CODE" "1")
export APP_NAME=$(get_env_var "APP_NAME" "QuikApp")
export ORG_NAME=$(get_env_var "ORG_NAME" "QuikApp")
export WEB_URL=$(get_env_var "WEB_URL" "https://quikapp.com")
export PKG_NAME=$(get_env_var "PKG_NAME" "com.example.quikapp")
export BUNDLE_ID=$(get_env_var "BUNDLE_ID" "com.example.quikapp")
export EMAIL_ID=$(get_env_var "EMAIL_ID" "admin@example.com")
export PUSH_NOTIFY=$(get_env_var "PUSH_NOTIFY" "false")
export IS_CHATBOT=$(get_env_var "IS_CHATBOT" "false")
export IS_DOMAIN_URL=$(get_env_var "IS_DOMAIN_URL" "false")
export IS_SPLASH=$(get_env_var "IS_SPLASH" "true")
export IS_PULLDOWN=$(get_env_var "IS_PULLDOWN" "false")
export IS_BOTTOMMENU=$(get_env_var "IS_BOTTOMMENU" "false")
export IS_LOAD_IND=$(get_env_var "IS_LOAD_IND" "false")
export IS_CAMERA=$(get_env_var "IS_CAMERA" "false")
export IS_LOCATION=$(get_env_var "IS_LOCATION" "false")
export IS_MIC=$(get_env_var "IS_MIC" "false")
export IS_NOTIFICATION=$(get_env_var "IS_NOTIFICATION" "false")
export IS_CONTACT=$(get_env_var "IS_CONTACT" "false")
export IS_BIOMETRIC=$(get_env_var "IS_BIOMETRIC" "false")
export IS_CALENDAR=$(get_env_var "IS_CALENDAR" "false")
export IS_STORAGE=$(get_env_var "IS_STORAGE" "false")
export APPLE_TEAM_ID=$(get_env_var "APPLE_TEAM_ID" "")
export PROFILE_TYPE=$(get_env_var "PROFILE_TYPE" "app-store")
export PROFILE_URL=$(get_env_var "PROFILE_URL" "")
export CERT_PASSWORD=$(get_env_var "CERT_PASSWORD" "")
export CERT_P12_URL=$(get_env_var "CERT_P12_URL" "")
export CERT_CER_URL=$(get_env_var "CERT_CER_URL" "")
export CERT_KEY_URL=$(get_env_var "CERT_KEY_URL" "")
export FIREBASE_CONFIG_IOS=$(get_env_var "FIREBASE_CONFIG_IOS" "")
export APNS_KEY_ID=$(get_env_var "APNS_KEY_ID" "")
export APNS_AUTH_KEY_URL=$(get_env_var "APNS_AUTH_KEY_URL" "")
export ENABLE_EMAIL_NOTIFICATIONS=$(get_env_var "ENABLE_EMAIL_NOTIFICATIONS" "false")
export EMAIL_SMTP_SERVER=$(get_env_var "EMAIL_SMTP_SERVER" "")
export EMAIL_SMTP_PORT=$(get_env_var "EMAIL_SMTP_PORT" "587")
export EMAIL_SMTP_USER=$(get_env_var "EMAIL_SMTP_USER" "")
export EMAIL_SMTP_PASS=$(get_env_var "EMAIL_SMTP_PASS" "")
export LOGO_URL=$(get_env_var "LOGO_URL" "")
export SPLASH_URL=$(get_env_var "SPLASH_URL" "")
export SPLASH_BG_URL=$(get_env_var "SPLASH_BG_URL" "")
export SPLASH_BG_COLOR=$(get_env_var "SPLASH_BG_COLOR" "#FFFFFF")
export SPLASH_TAGLINE=$(get_env_var "SPLASH_TAGLINE" "")
export SPLASH_TAGLINE_COLOR=$(get_env_var "SPLASH_TAGLINE_COLOR" "#000000")
export SPLASH_ANIMATION=$(get_env_var "SPLASH_ANIMATION" "fade")
export SPLASH_DURATION=$(get_env_var "SPLASH_DURATION" "3")
export BOTTOMMENU_ITEMS=$(get_env_var "BOTTOMMENU_ITEMS" "")
export BOTTOMMENU_BG_COLOR=$(get_env_var "BOTTOMMENU_BG_COLOR" "#FFFFFF")
export BOTTOMMENU_ICON_COLOR=$(get_env_var "BOTTOMMENU_ICON_COLOR" "#000000")
export BOTTOMMENU_TEXT_COLOR=$(get_env_var "BOTTOMMENU_TEXT_COLOR" "#000000")
export BOTTOMMENU_FONT=$(get_env_var "BOTTOMMENU_FONT" "System")
export BOTTOMMENU_FONT_SIZE=$(get_env_var "BOTTOMMENU_FONT_SIZE" "12")
export BOTTOMMENU_FONT_BOLD=$(get_env_var "BOTTOMMENU_FONT_BOLD" "false")
export BOTTOMMENU_FONT_ITALIC=$(get_env_var "BOTTOMMENU_FONT_ITALIC" "false")
export BOTTOMMENU_ACTIVE_TAB_COLOR=$(get_env_var "BOTTOMMENU_ACTIVE_TAB_COLOR" "#007AFF")
export BOTTOMMENU_ICON_POSITION=$(get_env_var "BOTTOMMENU_ICON_POSITION" "above")

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

# Step 1: Create Default Assets
log_info "Step 1: Create Default Assets"
log "================================================"
create_default_assets

# Step 2: Download Assets for Dart Codes
log_info "Step 2: Download Assets for Dart Codes"
log "================================================"

# Download logo
if [ -n "$LOGO_URL" ]; then
    if ultimate_download "$LOGO_URL" "assets/images/logo.png" "app logo"; then
        log_success "Logo downloaded successfully"
    else
        log_warning "Failed to download logo, using default"
        if [ -f "assets/images/default_logo.png" ]; then
            cp "assets/images/default_logo.png" "assets/images/logo.png"
            log_info "Using default logo"
        fi
    fi
else
    log_warning "LOGO_URL not provided, using default"
    if [ -f "assets/images/default_logo.png" ]; then
        cp "assets/images/default_logo.png" "assets/images/logo.png"
        log_info "Using default logo"
    fi
fi

# Download splash image
if [ -n "$SPLASH_URL" ]; then
    if ultimate_download "$SPLASH_URL" "assets/images/splash.png" "splash image"; then
        log_success "Splash image downloaded successfully"
    else
        log_warning "Failed to download splash image, using default"
        if [ -f "assets/images/splash.png" ]; then
            log_info "Using existing splash image"
        elif [ -f "assets/images/default_logo.png" ]; then
            cp "assets/images/default_logo.png" "assets/images/splash.png"
            log_info "Using default logo as splash"
        fi
    fi
else
    log_warning "SPLASH_URL not provided, using default"
    if [ -f "assets/images/splash.png" ]; then
        log_info "Using existing splash image"
    elif [ -f "assets/images/default_logo.png" ]; then
        cp "assets/images/default_logo.png" "assets/images/splash.png"
        log_info "Using default logo as splash"
    fi
fi

# Download splash background
if [ -n "$SPLASH_BG_URL" ]; then
    if ultimate_download "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background"; then
        log_success "Splash background downloaded successfully"
    else
        log_warning "Failed to download splash background, using default"
        if command -v magick >/dev/null 2>&1; then
            magick -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
            log_info "Created default splash background with color: $SPLASH_BG_COLOR"
        elif command -v convert >/dev/null 2>&1; then
            convert -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
            log_info "Created default splash background with color: $SPLASH_BG_COLOR"
        fi
    fi
else
    log_warning "SPLASH_BG_URL not provided, using default"
    if command -v magick >/dev/null 2>&1; then
        magick -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
        log_info "Created default splash background with color: $SPLASH_BG_COLOR"
    elif command -v convert >/dev/null 2>&1; then
        convert -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
        log_info "Created default splash background with color: $SPLASH_BG_COLOR"
    fi
fi

# Step 3: Download iOS Certificates and Files
log_info "Step 3: Download iOS Certificates and Files"
log "================================================"

# Download Firebase config if push notifications enabled
if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_IOS" ]; then
    if ultimate_download "$FIREBASE_CONFIG_IOS" "ios/GoogleService-Info.plist" "Firebase config"; then
        log_success "Firebase config downloaded successfully"
    else
        log_warning "Failed to download Firebase config"
        log_info "Firebase setup will be skipped due to missing config"
    fi
fi

# Download APNS auth key if provided
if [ -n "$APNS_AUTH_KEY_URL" ] && [ -n "$APNS_KEY_ID" ]; then
    if ultimate_download "$APNS_AUTH_KEY_URL" "ios/AuthKey_${APNS_KEY_ID}.p8" "APNS auth key"; then
        log_success "APNS auth key downloaded successfully"
    else
        log_warning "Failed to download APNS auth key"
        log_info "APNS setup will be skipped due to missing auth key"
    fi
fi

# Handle iOS certificates (Option 1: P12 file)
if [ -n "$CERT_P12_URL" ] && [ -n "$CERT_PASSWORD" ]; then
    log_info "Using Option 1: P12 certificate"
    if ultimate_download "$CERT_P12_URL" "ios/certificates/Certificates.p12" "P12 certificate"; then
        log_success "P12 certificate downloaded successfully"
    else
        log_warning "Failed to download P12 certificate"
        log_info "Will use automatic code signing instead"
    fi
# Handle iOS certificates (Option 2: CER and KEY files)
elif [ -n "$CERT_CER_URL" ] && [ -n "$CERT_KEY_URL" ] && [ -n "$CERT_PASSWORD" ]; then
    log_info "Using Option 2: CER and KEY files"
    # Download cer and key files
    if ultimate_download "$CERT_CER_URL" "/tmp/certificate.cer" "certificate file" && \
       ultimate_download "$CERT_KEY_URL" "/tmp/private.key" "private key file"; then
        
        # Convert to p12
        if openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/private.key -out "ios/certificates/Certificates.p12" -passout pass:"$CERT_PASSWORD" 2>/dev/null; then
            log_success "p12 file generated successfully"
        else
            log_warning "Failed to generate p12 file"
            log_info "Will use automatic code signing instead"
        fi
    else
        log_warning "Failed to download certificate files"
        log_info "Will use automatic code signing instead"
    fi
else
    log_info "No certificate configuration found, using automatic code signing"
fi

# Download provisioning profile
if [ -n "$PROFILE_URL" ]; then
    if ultimate_download "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"; then
        log_success "Provisioning profile downloaded successfully"
    else
        log_warning "Failed to download provisioning profile"
        log_info "Will use automatic provisioning profile management"
    fi
else
    log_info "No provisioning profile URL provided, using automatic management"
fi

# Step 4: Configure App Name and Bundle ID
log_info "Step 4: Configure App Name and Bundle ID"
log "================================================"

# Update app name in Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    log_info "Updating app name in Info.plist..."
    plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist || log_warning "Failed to update app name"
    plutil -replace CFBundleName -string "$APP_NAME" ios/Runner/Info.plist || log_warning "Failed to update app name"
fi

# Update bundle identifier in project.pbxproj
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    log_info "Updating bundle identifier in project.pbxproj..."
    sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj || log_warning "Failed to update bundle identifier"
fi

log_success "App name and bundle ID configured"

# Step 5: Generate env_config.dart with cat EOF
log_info "Step 5: Generate env_config.dart with cat EOF"
log "================================================"

log_info "Generating env_config.dart..."

# Escape special characters in strings for Dart
escape_dart_string() {
    local str="$1"
    # Replace single quotes with escaped single quotes
    str="${str//\'/\\\'}"
    # Replace newlines with \n
    str="${str//$'\n'/\\n}"
    # Replace carriage returns with \r
    str="${str//$'\r'/\\r}"
    # Replace tabs with \t
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Escape the complex strings
ESCAPED_BOTTOMMENU_ITEMS=$(escape_dart_string "$BOTTOMMENU_ITEMS")
ESCAPED_SPLASH_TAGLINE=$(escape_dart_string "$SPLASH_TAGLINE")

cat > lib/config/env_config.dart <<EOF
// Generated by Enhanced iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information
  static const String appName = '${APP_NAME//\'/\\\'}';
  static const String versionName = '${VERSION_NAME//\'/\\\'}';
  static const String versionCode = '${VERSION_CODE//\'/\\\'}';
  static const String bundleId = '${BUNDLE_ID//\'/\\\'}';
  static const String packageName = '${PKG_NAME//\'/\\\'}';
  static const String organizationName = '${ORG_NAME//\'/\\\'}';
  static const String webUrl = '${WEB_URL//\'/\\\'}';
  static const String userName = '${USER_NAME//\'/\\\'}';
  static const String appId = '${APP_ID//\'/\\\'}';
  static const String workflowId = '${WORKFLOW_ID//\'/\\\'}';

  // Feature Flags
  static const bool isPushNotify = $PUSH_NOTIFY;
  static const bool isChatbot = $IS_CHATBOT;
  static const bool isDomainUrl = $IS_DOMAIN_URL;
  static const bool isSplash = $IS_SPLASH;
  static const bool isPulldown = $IS_PULLDOWN;
  static const bool isBottomMenu = $IS_BOTTOMMENU;
  static const bool isLoadInd = $IS_LOAD_IND;

  // Permissions
  static const bool isCamera = $IS_CAMERA;
  static const bool isLocation = $IS_LOCATION;
  static const bool isMic = $IS_MIC;
  static const bool isNotification = $IS_NOTIFICATION;
  static const bool isContact = $IS_CONTACT;
  static const bool isBiometric = $IS_BIOMETRIC;
  static const bool isCalendar = $IS_CALENDAR;
  static const bool isStorage = $IS_STORAGE;

  // UI Configuration
  static const String splashBgColor = '${SPLASH_BG_COLOR//\'/\\\'}';
  static const String splashTagline = '$ESCAPED_SPLASH_TAGLINE';
  static const String splashTaglineColor = '${SPLASH_TAGLINE_COLOR//\'/\\\'}';
  static const String splashAnimation = '${SPLASH_ANIMATION//\'/\\\'}';
  static const String splashDuration = '${SPLASH_DURATION//\'/\\\'}';

  // Bottom Menu Configuration
  static const String bottomMenuItems = '$ESCAPED_BOTTOMMENU_ITEMS';
  static const String bottomMenuBgColor = '${BOTTOMMENU_BG_COLOR//\'/\\\'}';
  static const String bottomMenuIconColor = '${BOTTOMMENU_ICON_COLOR//\'/\\\'}';
  static const String bottomMenuTextColor = '${BOTTOMMENU_TEXT_COLOR//\'/\\\'}';
  static const String bottomMenuFont = '${BOTTOMMENU_FONT//\'/\\\'}';
  static const String bottomMenuFontSize = '${BOTTOMMENU_FONT_SIZE//\'/\\\'}';
  static const bool bottomMenuFontBold = $BOTTOMMENU_FONT_BOLD;
  static const bool bottomMenuFontItalic = $BOTTOMMENU_FONT_ITALIC;
  static const String bottomMenuActiveTabColor = '${BOTTOMMENU_ACTIVE_TAB_COLOR//\'/\\\'}';
  static const String bottomMenuIconPosition = '${BOTTOMMENU_ICON_POSITION//\'/\\\'}';
}
EOF

log_success "env_config.dart generated successfully"

# Step 6: Configure Firebase for iOS
log_info "Step 6: Configure Firebase for iOS"
log "================================================"

if [ "$PUSH_NOTIFY" = "true" ]; then
    log_info "Configuring Firebase for push notifications..."
    
    # Copy Firebase config to Runner directory
    if [ -f "ios/GoogleService-Info.plist" ]; then
        cp ios/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
        log_success "Firebase config copied to Runner directory"
    else
        log_warning "Firebase config not found"
    fi
    
    # Add Firebase to Podfile if not already present
    if [ -f "ios/Podfile" ]; then
        if ! grep -q "Firebase" ios/Podfile; then
            log_info "Adding Firebase to Podfile..."
            echo "pod 'Firebase/Messaging'" >> ios/Podfile
            echo "pod 'Firebase/Analytics'" >> ios/Podfile
            log_success "Firebase pods added to Podfile"
        else
            log_info "Firebase already present in Podfile"
        fi
    fi
else
    log_info "Push notifications disabled, skipping Firebase configuration"
fi

# Step 7: Inject Permissions Dynamically
log_info "Step 7: Inject Permissions Dynamically"
log "================================================"

# Create Info.plist additions
log_info "Injecting permissions into Info.plist..."
cat > ios/Runner/Info.plist.additions <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
EOF

# Add camera permission
if [ "$IS_CAMERA" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos and videos.</string>
EOF
fi

# Add location permission
if [ "$IS_LOCATION" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to provide location-based services.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs location access to provide location-based services.</string>
EOF
fi

# Add microphone permission
if [ "$IS_MIC" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for voice features.</string>
EOF
fi

# Add notification permission
if [ "$IS_NOTIFICATION" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSUserNotificationUsageDescription</key>
    <string>This app needs notification access to send you important updates.</string>
EOF
fi

# Add contacts permission
if [ "$IS_CONTACT" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSContactsUsageDescription</key>
    <string>This app needs contacts access to help you connect with friends.</string>
EOF
fi

# Add biometric permission
if [ "$IS_BIOMETRIC" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSFaceIDUsageDescription</key>
    <string>This app uses Face ID for secure authentication.</string>
EOF
fi

# Add calendar permission
if [ "$IS_CALENDAR" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSCalendarsUsageDescription</key>
    <string>This app needs calendar access to help you manage your schedule.</string>
EOF
fi

# Add photo library permission
if [ "$IS_STORAGE" = "true" ]; then
    cat >> ios/Runner/Info.plist.additions <<EOF
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to save and share images.</string>
EOF
fi

cat >> ios/Runner/Info.plist.additions <<EOF
</dict>
</plist>
EOF

log_success "Permissions injected into Info.plist"

# Step 8: Flutter Build without Code Signing
log_info "Step 8: Flutter Build without Code Signing"
log "================================================"

# Clean previous builds
log_info "Cleaning previous builds..."
flutter clean || log_warning "Flutter clean failed, continuing anyway"

# Get dependencies
log_info "Getting Flutter dependencies..."
if ! flutter pub get; then
    log_error "Failed to get Flutter dependencies"
    exit 1
fi

# Build without code signing
log_info "Building Flutter app without code signing..."
if ! flutter build ios --release --no-codesign; then
    log_error "Flutter build failed"
    exit 1
fi

log_success "Flutter build completed successfully"

# Step 9: Install CocoaPods Dependencies
log_info "Step 9: Install CocoaPods Dependencies"
log "================================================"

cd ios
log_info "Installing CocoaPods dependencies..."
if ! pod install --repo-update; then
    log_warning "CocoaPods install failed, trying without --repo-update..."
    if ! pod install; then
        log_error "CocoaPods install failed completely"
        cd ..
        exit 1
    fi
fi
cd ..

log_success "CocoaPods dependencies installed successfully"

# Step 10: Create Xcode Archive
log_info "Step 10: Create Xcode Archive"
log "================================================"

log_info "Creating Xcode archive with code signing..."
if ! xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphoneos \
    -configuration Release archive \
    -archivePath build/Runner.xcarchive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Automatic"; then
    log_error "Xcode archive failed"
    exit 1
fi

log_success "Xcode archive completed successfully"

# Step 11: Create Export Options
log_info "Step 11: Create Export Options"
log "================================================"

log_info "Creating ExportOptions.plist..."
cat > lib/scripts/ios-workflow/exportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$PROFILE_TYPE</string>
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

log_success "ExportOptions.plist created"

# Step 12: Export IPA
log_info "Step 12: Export IPA"
log "================================================"

log_info "Exporting IPA..."
if ! xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
    -exportPath build/export \
    -allowProvisioningUpdates; then
    log_error "IPA export failed"
    exit 1
fi

log_success "IPA export completed successfully"

# Step 13: Verify and Copy IPA
log_info "Step 13: Verify and Copy IPA"
log "================================================"

if [ -f "build/export/Runner.ipa" ]; then
    log_success "IPA file created successfully: build/export/Runner.ipa"
    ls -la build/export/
    
    # Copy to output directory for Codemagic artifacts
    log_info "Copying IPA to output directory..."
    if cp build/export/Runner.ipa output/ios/; then
        log_success "IPA copied to output directory successfully"
    else
        log_warning "Failed to copy IPA to output directory"
    fi
else
    log_error "IPA file not found after export"
    provide_error_analysis
    exit 1
fi

# Step 14: Final Verification
log_info "Step 14: Final Verification"
log "================================================"

if check_ipa_generation; then
    log_success "🎉 Enhanced iOS Workflow Completed Successfully!"
    log "📱 App: $APP_NAME v$VERSION_NAME ($VERSION_CODE)"
    log "🆔 Bundle ID: $BUNDLE_ID"
    log "👥 Team ID: $APPLE_TEAM_ID"
    log "📦 IPA Location: build/export/Runner.ipa"
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
    
    log_success "✅ Enhanced iOS workflow completed successfully!"
    log_info "Build process finished - check artifacts for IPA file"
    exit 0
else
    log_error "❌ IPA file verification failed"
    provide_error_analysis
    exit 1
fi 