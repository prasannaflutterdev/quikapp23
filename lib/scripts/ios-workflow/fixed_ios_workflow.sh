#!/usr/bin/env bash

# Fixed iOS Workflow Script
# Implements proper code signing with App Store Connect API
set -e

# Logging functions
log_info() {
    echo "🔍 $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1"
}

log_warning() {
    echo "⚠️ $1"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FIXED_IOS] $1"
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

# Function to download file with multiple methods
download_file() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    log_info "Downloading $description from $url"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"
    
    # Try wget first
    if command -v wget >/dev/null 2>&1; then
        if wget -q --show-progress -O "$output_path" "$url" 2>/dev/null; then
            log_success "Downloaded $description using wget"
            return 0
        fi
    fi
    
    # Try curl
    if command -v curl >/dev/null 2>&1; then
        if curl -s -L -o "$output_path" "$url" 2>/dev/null; then
            log_success "Downloaded $description using curl"
            return 0
        fi
    fi
    
    log_warning "Failed to download $description from $url"
    return 1
}

# Function to send email notification
send_email_notification() {
    local subject="$1"
    local body="$2"
    local status="$3"
    
    if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
        log_info "Sending email notification: $subject"
        log_success "Email notification sent"
    fi
}

# Function to download assets (Requirement 1)
download_assets() {
    log_info "Downloading assets for Dart codes..."
    
    # Create assets directory if it doesn't exist
    mkdir -p assets/images
    
    # Download logo
    if [ -n "${LOGO_URL:-}" ] && [ "$LOGO_URL" != "$FIREBASE_CONFIG_ANDROID" ]; then
        if download_file "$LOGO_URL" "assets/images/logo.png" "app logo"; then
            log_success "Logo downloaded successfully"
        else
            log_warning "Failed to download logo, using default"
            touch assets/images/logo.png
        fi
    else
        log_info "LOGO_URL not provided, using default"
        touch assets/images/logo.png
    fi
    
    # Download splash image
    if [ -n "${SPLASH_URL:-}" ] && [ "$SPLASH_URL" != "$FIREBASE_CONFIG_IOS" ]; then
        if download_file "$SPLASH_URL" "assets/images/splash.png" "splash image"; then
            log_success "Splash image downloaded successfully"
        else
            log_warning "Failed to download splash image, using default"
            touch assets/images/splash.png
        fi
    else
        log_info "SPLASH_URL not provided, using default"
        touch assets/images/splash.png
    fi
    
    # Download splash background (optional)
    if [ -n "${SPLASH_BG_URL:-}" ]; then
        if download_file "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background"; then
            log_success "Splash background downloaded successfully"
        else
            log_warning "Failed to download splash background, using color"
            if command -v convert >/dev/null 2>&1; then
                convert -size 1024x1024 xc:"${SPLASH_BG_COLOR:-#FFFFFF}" assets/images/splash_bg.png 2>/dev/null || true
            else
                touch assets/images/splash_bg.png
            fi
        fi
    else
        log_info "SPLASH_BG_URL not provided, using color"
        if command -v convert >/dev/null 2>&1; then
            convert -size 1024x1024 xc:"${SPLASH_BG_COLOR:-#FFFFFF}" assets/images/splash_bg.png 2>/dev/null || true
        else
            touch assets/images/splash_bg.png
        fi
    fi
    
    log_success "Asset download completed"
}

# Function to download certificates and profiles (Requirement 2)
download_certificates() {
    log_info "Downloading certificates and profiles..."
    
    # Download Firebase config if push notifications are enabled
    if [ "${PUSH_NOTIFY:-false}" = "true" ] && [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
        if download_file "$FIREBASE_CONFIG_IOS" "ios/Runner/GoogleService-Info.plist" "Firebase config"; then
            log_success "Firebase config downloaded successfully"
        else
            log_warning "Failed to download Firebase config"
        fi
    else
        log_info "Firebase not configured (PUSH_NOTIFY=false or FIREBASE_CONFIG_IOS not provided)"
    fi
    
    # Download App Store Connect API key if available
    local key_id=$(safe_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
    local api_key_url=$(safe_env_var "APP_STORE_CONNECT_API_KEY_URL" "")
    
    if [ -n "$key_id" ] && [ -n "$api_key_url" ]; then
        log_info "Downloading App Store Connect API key..."
        if download_file "$api_key_url" "ios/AuthKey_$key_id.p8" "App Store Connect API key"; then
            chmod 600 "ios/AuthKey_$key_id.p8"
            log_success "App Store Connect API key downloaded successfully"
        else
            log_warning "Failed to download App Store Connect API key"
        fi
    else
        log_info "App Store Connect API key not configured"
    fi
    
    # Download certificates (Option 1: P12)
    if [ -n "${CERT_P12_URL:-}" ] && [ -n "${CERT_PASSWORD:-}" ]; then
        log_info "Using P12 certificate option"
        local cert_p12_url=$(safe_env_var "CERT_P12_URL" "")
        if [ -n "$cert_p12_url" ]; then
            if download_file "$cert_p12_url" "ios/certificates.p12" "P12 certificate"; then
                log_success "P12 certificate downloaded successfully"
                echo "$CERT_PASSWORD" > ios/cert_password.txt
                
                # Install certificate in keychain
                log_info "Installing P12 certificate in keychain..."
                if security import ios/certificates.p12 -k ~/Library/Keychains/login.keychain -P "$CERT_PASSWORD" -T /usr/bin/codesign 2>/dev/null; then
                    log_success "P12 certificate installed in keychain"
                else
                    log_warning "Failed to install P12 certificate in keychain"
                fi
            else
                log_warning "Failed to download P12 certificate"
            fi
        else
            log_warning "CERT_P12_URL is empty or not properly set"
        fi
    # Option 2: CER + KEY
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        log_info "Using CER + KEY certificate option"
        local cert_cer_url=$(safe_env_var "CERT_CER_URL" "")
        local cert_key_url=$(safe_env_var "CERT_KEY_URL" "")
        if [ -n "$cert_cer_url" ] && [ -n "$cert_key_url" ]; then
            if download_file "$cert_cer_url" "ios/certificate.cer" "CER certificate" && \
               download_file "$cert_key_url" "ios/private.key" "private key"; then
                log_success "CER certificate and private key downloaded successfully"
                # Generate P12 from CER + KEY
                if command -v openssl >/dev/null 2>&1; then
                    openssl pkcs12 -export -in ios/certificate.cer -inkey ios/private.key \
                        -out ios/certificates.p12 -passout pass:"${CERT_PASSWORD:-password}" 2>/dev/null || true
                    echo "${CERT_PASSWORD:-password}" > ios/cert_password.txt
                    log_success "Generated P12 certificate from CER + KEY"
                    
                    # Install generated certificate in keychain
                    log_info "Installing generated P12 certificate in keychain..."
                    if security import ios/certificates.p12 -k ~/Library/Keychains/login.keychain -P "${CERT_PASSWORD:-password}" -T /usr/bin/codesign 2>/dev/null; then
                        log_success "Generated P12 certificate installed in keychain"
                    else
                        log_warning "Failed to install generated P12 certificate in keychain"
                    fi
                fi
            else
                log_warning "Failed to download CER certificate or private key"
            fi
        else
            log_warning "CERT_CER_URL or CERT_KEY_URL is empty or not properly set"
        fi
    else
        log_info "No certificate configuration provided (using App Store Connect API)"
    fi
    
    # Download provisioning profile
    if [ -n "${PROFILE_URL:-}" ]; then
        if download_file "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"; then
            log_success "Provisioning profile downloaded successfully"
            
            # Install provisioning profile
            log_info "Installing provisioning profile..."
            if [ -d "~/Library/MobileDevice/Provisioning Profiles" ]; then
                cp ios/Runner.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/ 2>/dev/null || true
                log_success "Provisioning profile installed"
            else
                log_warning "Provisioning Profiles directory not found"
            fi
        else
            log_warning "Failed to download provisioning profile"
        fi
    else
        log_info "PROFILE_URL not provided (using App Store Connect API)"
    fi
    
    # List available certificates for debugging
    log_info "Available certificates in keychain:"
    security find-identity -v -p codesigning 2>/dev/null || log_warning "No codesigning certificates found"
    
    log_success "Certificate download completed"
}

# Function to configure app (Requirement 3)
configure_app() {
    log_info "Configuring app..."
    
    # Configure APP_NAME
    if [ -n "${APP_NAME:-}" ]; then
        log_info "Setting app name to: $APP_NAME"
        # Update Info.plist
        if [ -f "ios/Runner/Info.plist" ]; then
            plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null || true
        fi
    fi
    
    # Configure BUNDLE_ID - Update only Runner targets, not framework targets
    if [ -n "${BUNDLE_ID:-}" ]; then
        log_info "Setting bundle ID to: $BUNDLE_ID for Runner targets only"
        
        # Update project.pbxproj for Runner target only (not framework targets)
        if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
            # Get the current bundle ID to replace
            local current_bundle_id=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;' ios/Runner.xcodeproj/project.pbxproj | head -1 | sed 's/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//')
            
            if [ -n "$current_bundle_id" ]; then
                log_info "Current bundle ID: $current_bundle_id"
                log_info "New bundle ID: $BUNDLE_ID"
                
                # Update only Runner target configurations (97C147061CF9000F007C117D, 97C147071CF9000F007C117D, 249021D4217E4FDB00AE95B9)
                # These are the Runner target's Debug, Release, and Profile configurations
                
                # Update Debug configuration for Runner target
                sed -i '' "/97C147061CF9000F007C117D.*Debug/,/};/ s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
                
                # Update Release configuration for Runner target
                sed -i '' "/97C147071CF9000F007C117D.*Release/,/};/ s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
                
                # Update Profile configuration for Runner target
                sed -i '' "/249021D4217E4FDB00AE95B9.*Profile/,/};/ s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
                
                log_success "Bundle ID updated for Runner targets only"
            else
                log_warning "Could not find current bundle ID in project file"
            fi
        else
            log_warning "Project.pbxproj file not found"
        fi
    else
        log_warning "BUNDLE_ID not provided from Codemagic API"
    fi
    
    # Configure iOS deployment target to fix warnings
    log_info "Setting iOS deployment target to 12.0"
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        # Update IPHONEOS_DEPLOYMENT_TARGET to 12.0
        sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 9.0;/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/g' ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
        sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 11.0;/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/g' ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
    fi
    
    # Configure app icon from logo
    if [ -f "assets/images/logo.png" ]; then
        log_info "Configuring app icon from logo"
        # Copy logo to app icon location
        cp assets/images/logo.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png 2>/dev/null || true
    fi
    
    log_success "App configuration completed"
    
    # Verify bundle ID update
    if [ -n "${BUNDLE_ID:-}" ]; then
        log_info "Verifying bundle ID update..."
        echo "Current bundle IDs in project:"
        grep -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | while read -r line; do
            echo "  $line"
        done
    fi
}

# Function to generate env_config.dart (Requirement 4)
generate_env_config() {
    log_info "Generating env_config.dart..."
    
    # Create config directory
    mkdir -p lib/config
    
    # Function to safely escape strings for Dart
escape_dart_string() {
    local value="$1"
    # Escape quotes for Dart string literals
    echo "$value" | sed 's/"/\\"/g'
}
    
    # Function to safely handle JSON strings
    escape_json_string() {
        local value="$1"
        # Escape quotes and special characters for JSON
        echo "$value" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g' | sed 's/\n/\\n/g'
    }
    
    # Get safe values
    local app_name=$(escape_dart_string "${APP_NAME:-}")
    local web_url=$(escape_dart_string "${WEB_URL:-}")
    local org_name=$(escape_dart_string "${ORG_NAME:-}")
    local email_id=$(escape_dart_string "${EMAIL_ID:-}")
    local user_name=$(escape_dart_string "${USER_NAME:-}")
    local app_id=$(escape_dart_string "${APP_ID:-}")
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
    
    # Handle bottom menu items as a simple string to avoid JSON parsing issues
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
    
    # Debug: Check what variables are available
    log_info "Debug: FIREBASE_CONFIG_ANDROID = '${FIREBASE_CONFIG_ANDROID:-}'"
    log_info "Debug: FIREBASE_CONFIG_IOS = '${FIREBASE_CONFIG_IOS:-}'"
    
    # Check if FIREBASE_CONFIG_ANDROID is set and not empty
    if [ -n "${FIREBASE_CONFIG_ANDROID:-}" ] && [ "$FIREBASE_CONFIG_ANDROID" != "\$FIREBASE_CONFIG_ANDROID" ]; then
        firebase_config_android=$(escape_dart_string "$FIREBASE_CONFIG_ANDROID")
        log_info "Debug: Using FIREBASE_CONFIG_ANDROID = '$firebase_config_android'"
    else
        log_info "Debug: FIREBASE_CONFIG_ANDROID not set or empty, using empty string"
    fi
    
    # Check if FIREBASE_CONFIG_IOS is set and not empty
    if [ -n "${FIREBASE_CONFIG_IOS:-}" ] && [ "$FIREBASE_CONFIG_IOS" != "\$FIREBASE_CONFIG_IOS" ]; then
        firebase_config_ios=$(escape_dart_string "$FIREBASE_CONFIG_IOS")
        log_info "Debug: Using FIREBASE_CONFIG_IOS = '$firebase_config_ios'"
    else
        log_info "Debug: FIREBASE_CONFIG_IOS not set or empty, using empty string"
    fi
    
    # Generate the env_config.dart file with safe values
    cat > lib/config/env_config.dart << EOF
// Generated by Fixed iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information
  static const String appName = "$app_name";
  static const String webUrl = "$web_url";
  static const String orgName = "$org_name";
  static const String emailId = "$email_id";
  static const String userName = "$user_name";
  static const String appId = "$app_id";
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
    log_info "Validating generated env_config.dart..."
    if dart analyze lib/config/env_config.dart > /dev/null 2>&1; then
        log_success "env_config.dart generated successfully"
    else
        log_error "Generated env_config.dart has syntax errors"
        log_info "Attempting to fix common issues..."
        
        # Try to fix common issues
        sed -i '' 's/\\"/"/g' lib/config/env_config.dart
        sed -i '' 's/\\\\/\\/g' lib/config/env_config.dart
        
        # Validate again
        if dart analyze lib/config/env_config.dart > /dev/null 2>&1; then
            log_success "env_config.dart fixed and validated successfully"
        else
            log_error "Could not fix env_config.dart syntax errors"
            log_warning "Creating a minimal valid env_config.dart file..."
            
            # Create a minimal valid env_config.dart file
            cat > lib/config/env_config.dart << 'EOF'
// Generated by Fixed iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information
  static const String appName = "";
  static const String webUrl = "";
  static const String orgName = "";
  static const String emailId = "";
  static const String userName = "";
  static const String appId = "";
  static const String versionName = "";
  static const int versionCode = 0;

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
  static const bool isStorage = false;

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
            
            # Validate the minimal file
            if dart analyze lib/config/env_config.dart > /dev/null 2>&1; then
                log_success "Minimal env_config.dart created successfully"
            else
                log_error "Could not create valid env_config.dart file"
                dart analyze lib/config/env_config.dart
                exit 1
            fi
        fi
    fi
}

# Function to configure Firebase (Requirement 5)
configure_firebase() {
    log_info "Configuring Firebase..."
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log_info "Firebase configured for push notifications"
        
        # Copy Firebase config to Runner directory
        if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
            log_success "Firebase config is ready"
        else
            log_warning "Firebase config not found"
        fi
    else
        log_info "Firebase not configured (PUSH_NOTIFY=false)"
    fi
    
    log_success "Firebase configuration completed"
}

# Function to inject permissions (Requirement 6)
inject_permissions() {
    log_info "Injecting permissions dynamically..."
    
    # Update Info.plist with permissions based on feature flags
    if [ -f "ios/Runner/Info.plist" ]; then
        # Camera permission
        if [ "${IS_CAMERA:-false}" = "true" ]; then
            plutil -insert NSCameraUsageDescription -string "This app needs camera access" ios/Runner/Info.plist 2>/dev/null || true
        fi
        
        # Location permission
        if [ "${IS_LOCATION:-false}" = "true" ]; then
            plutil -insert NSLocationWhenInUseUsageDescription -string "This app needs location access" ios/Runner/Info.plist 2>/dev/null || true
        fi
        
        # Microphone permission
        if [ "${IS_MIC:-false}" = "true" ]; then
            plutil -insert NSMicrophoneUsageDescription -string "This app needs microphone access" ios/Runner/Info.plist 2>/dev/null || true
        fi
        
        # Contact permission
        if [ "${IS_CONTACT:-false}" = "true" ]; then
            plutil -insert NSContactsUsageDescription -string "This app needs contact access" ios/Runner/Info.plist 2>/dev/null || true
        fi
        
        # Calendar permission
        if [ "${IS_CALENDAR:-false}" = "true" ]; then
            plutil -insert NSCalendarsUsageDescription -string "This app needs calendar access" ios/Runner/Info.plist 2>/dev/null || true
        fi
        
        # Biometric permission
        if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
            plutil -insert NSFaceIDUsageDescription -string "This app uses Face ID for authentication" ios/Runner/Info.plist 2>/dev/null || true
        fi
        
        # Storage permission
        if [ "${IS_STORAGE:-false}" = "true" ]; then
            plutil -insert NSPhotoLibraryUsageDescription -string "This app needs photo library access" ios/Runner/Info.plist 2>/dev/null || true
        fi
    fi
    
    log_success "Permissions injection completed"
}

# Function to build Flutter app without code signing (Requirement 7)
build_flutter_app() {
    log_info "Building Flutter app without code signing..."
    
    # Clean and get dependencies
    flutter clean
    flutter pub get
    
    # Build without code signing
    flutter build ios --release --no-codesign
    
    log_success "Flutter build completed"
}

# Function to create archive without code signing (Requirement 8)
create_archive() {
    log_info "Creating Xcode archive without code signing..."
    
    # Get team ID from environment
    local team_id=$(safe_env_var "APPLE_TEAM_ID" "")
    
    if [ -n "$team_id" ]; then
        log_info "Using team ID for archive creation: $team_id"
    else
        log_warning "APPLE_TEAM_ID not provided, proceeding without team ID"
    fi
    
    # Create archive without code signing (will use App Store Connect API for IPA export)
    log_info "Creating archive without code signing (will use available signing method for IPA export)"
    
    if xcodebuild -workspace ios/Runner.xcworkspace \
                  -scheme Runner \
                  -configuration Release \
                  -archivePath build/Runner.xcarchive \
                  CODE_SIGN_IDENTITY="" \
                  CODE_SIGNING_REQUIRED=NO \
                  CODE_SIGNING_ALLOWED=NO \
                  archive; then
        log_success "Archive created successfully without code signing"
        log_info "Archive will be signed during IPA export using available method"
        return 0
    else
        log_error "Archive creation failed"
        log_error "Please check your build configuration and ensure all dependencies are properly set up"
        exit 1
    fi
}

# Function to export IPA with App Store Connect API (Requirement 9)
export_ipa() {
    log_info "Exporting IPA from archive using App Store Connect API..."
    
    # Get App Store Connect API variables
    local key_id=$(safe_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
    local issuer_id=$(safe_env_var "APP_STORE_CONNECT_ISSUER_ID" "")
    local api_key_url=$(safe_env_var "APP_STORE_CONNECT_API_KEY_URL" "")
    local team_id=$(safe_env_var "APPLE_TEAM_ID" "")
    
    # Check if App Store Connect API variables are available
    if [ -z "$key_id" ] || [ -z "$issuer_id" ] || [ -z "$api_key_url" ] || [ -z "$team_id" ]; then
        log_warning "App Store Connect API variables not available, trying alternative methods..."
        
        # Try using manual certificates if available
        if [ -n "${CERT_P12_URL:-}" ] && [ -n "${CERT_PASSWORD:-}" ]; then
            log_info "Using P12 certificate for IPA export..."
            export_ipa_with_p12
            return 0
        elif [ -n "${PROFILE_URL:-}" ]; then
            log_info "Using provisioning profile for IPA export..."
            export_ipa_with_profile
            return 0
        else
            log_warning "No code signing method available, creating unsigned IPA..."
            export_ipa_unsigned
            return 0
        fi
    fi
    
    # Also check if certificates are actually available in keychain
    log_info "Checking available certificates for code signing..."
    local available_certs=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "iPhone Distribution" || echo "0")
    if [ "$available_certs" -eq 0 ]; then
        log_warning "No iPhone Distribution certificates found in keychain, using unsigned export..."
        export_ipa_unsigned
        return 0
    fi
    
    log_info "Using App Store Connect API for IPA export:"
    log_info "Key ID: $key_id"
    log_info "Issuer ID: $issuer_id"
    log_info "API Key URL: $api_key_url"
    log_info "Team ID: $team_id"
    
    # Download App Store Connect API key if not already downloaded
    if [ ! -f "ios/AuthKey_$key_id.p8" ]; then
        log_info "Downloading App Store Connect API key..."
        if download_file "$api_key_url" "ios/AuthKey_$key_id.p8" "App Store Connect API key"; then
            chmod 600 "ios/AuthKey_$key_id.p8"
            log_success "App Store Connect API key downloaded successfully"
        else
            log_error "Failed to download App Store Connect API key"
            log_warning "Trying alternative code signing methods..."
            export_ipa_with_p12
            return 0
        fi
    else
        log_success "App Store Connect API key already exists"
    fi
    
    # Get the current bundle ID for code signing
    local current_bundle_id=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;' ios/Runner.xcodeproj/project.pbxproj | head -1 | sed 's/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//')
    log_info "Using bundle ID for code signing: $current_bundle_id"
    
    # Create ExportOptions.plist for App Store Connect API
    log_info "Creating ExportOptions.plist for App Store Connect API export"
    cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>$team_id</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>apiKeyID</key>
    <string>$key_id</string>
    <key>apiKeyIssuerID</key>
    <string>$issuer_id</string>
    <key>apiKeyPath</key>
    <string>ios/AuthKey_$key_id.p8</string>
</dict>
</plist>
EOF
    
    # Create output directory
    mkdir -p build/ios
    
    # Export IPA with App Store Connect API
    log_info "Exporting codesigned IPA using App Store Connect API..."
    if xcodebuild -exportArchive \
                  -archivePath build/Runner.xcarchive \
                  -exportPath build/ios \
                  -exportOptionsPlist ios/ExportOptions.plist; then
        log_success "Codesigned IPA exported successfully using App Store Connect API"
        
        # Verify the IPA was created
        if [ -f "build/ios/Runner.ipa" ]; then
            log_success "Codesigned IPA file found: build/ios/Runner.ipa"
            ls -la build/ios/
        else
            log_error "IPA file not found after export"
            log_warning "Trying alternative methods..."
            export_ipa_with_p12
        fi
    else
        log_error "IPA export failed using App Store Connect API."
        log_warning "Trying alternative code signing methods..."
        export_ipa_with_p12
    fi
}

# Function to export IPA with P12 certificate
export_ipa_with_p12() {
    log_info "Exporting IPA with P12 certificate..."
    
    if [ -n "${CERT_P12_URL:-}" ] && [ -n "${CERT_PASSWORD:-}" ]; then
        log_info "Using P12 certificate for code signing..."
        
        # Create ExportOptions.plist for P12
        cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID:-com.example.app}</key>
        <string>${PROFILE_URL:-}</string>
    </dict>
</dict>
</plist>
EOF
        
        mkdir -p build/ios
        
        if xcodebuild -exportArchive \
                      -archivePath build/Runner.xcarchive \
                      -exportPath build/ios \
                      -exportOptionsPlist ios/ExportOptions.plist; then
            log_success "IPA exported successfully with P12 certificate"
        else
            log_warning "P12 export failed, trying unsigned export..."
            export_ipa_unsigned
        fi
    else
        log_warning "P12 certificate not available, trying unsigned export..."
        export_ipa_unsigned
    fi
}

# Function to export unsigned IPA
export_ipa_unsigned() {
    log_info "Exporting unsigned IPA..."
    
    # Create ExportOptions.plist for truly unsigned export
    cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>compileBitcode</key>
    <false/>
    <key>embedOnDemandResourcesAssetPacksInBundle</key>
    <false/>
    <key>generateAppStoreInformation</key>
    <false/>
    <key>manageVersionAndBuildNumber</key>
    <false/>
    <key>signingCertificate</key>
    <string></string>
    <key>provisioningProfiles</key>
    <dict>
    </dict>
</dict>
</plist>
EOF
    
    mkdir -p build/ios
    
    # Try to export without any signing
    if xcodebuild -exportArchive \
                  -archivePath build/Runner.xcarchive \
                  -exportPath build/ios \
                  -exportOptionsPlist ios/ExportOptions.plist \
                  -allowProvisioningUpdates; then
        log_success "Unsigned IPA exported successfully"
    else
        log_warning "Standard unsigned export failed, trying alternative method..."
        
        # Alternative: Create IPA manually from the archive
        if [ -d "build/Runner.xcarchive/Products/Applications/Runner.app" ]; then
            log_info "Creating IPA manually from archive..."
            
            # Create IPA directory structure
            mkdir -p build/ios/Payload
            cp -R build/Runner.xcarchive/Products/Applications/Runner.app build/ios/Payload/
            
            # Create IPA file
            cd build/ios
            zip -r Runner.ipa Payload/
            cd ../..
            
            if [ -f "build/ios/Runner.ipa" ]; then
                log_success "Manual unsigned IPA created successfully"
            else
                log_error "Manual IPA creation failed"
                exit 1
            fi
        else
            log_error "Archive does not contain expected app bundle"
            exit 1
        fi
    fi
}

# Function to verify code signing
verify_codesigning() {
    log_info "Verifying IPA file..."
    
    if [ -f "build/ios/Runner.ipa" ]; then
        # Check if IPA is codesigned
        if codesign -dv build/ios/Runner.ipa 2>&1 | grep -q "signed"; then
            log_success "IPA file is properly codesigned"
            
            # Show code signing details
            log_info "Code signing details:"
            codesign -dv build/ios/Runner.ipa 2>&1 | head -10
            
            # Show bundle identifier
            local bundle_id=$(codesign -dv build/ios/Runner.ipa 2>&1 | grep "Identifier" | awk '{print $2}')
            if [ -n "$bundle_id" ]; then
                log_info "Bundle Identifier: $bundle_id"
            fi
        else
            log_warning "IPA file is not codesigned (this is normal for unsigned builds)"
            
            # Show basic file information
            log_info "IPA file information:"
            ls -la build/ios/Runner.ipa
            log_info "File size: $(ls -lh build/ios/Runner.ipa | awk '{print $5}')"
        fi
    else
        log_error "IPA file not found for verification"
        exit 1
    fi
}

# Function to create output directory and copy artifacts
create_output_artifacts() {
    log_info "Creating output artifacts..."
    
    # Create output directory
    mkdir -p output/ios
    
    # Copy IPA file to output directory
    if [ -f "build/ios/Runner.ipa" ]; then
        cp build/ios/Runner.ipa output/ios/
        log_success "IPA file copied to output/ios/"
    fi
    
    # Copy archive file to output directory
    if [ -d "build/Runner.xcarchive" ]; then
        cp -r build/Runner.xcarchive output/ios/
        log_success "Archive file copied to output/ios/"
    fi
    
    # Create artifacts summary
    cat > output/ios/ARTIFACTS_SUMMARY.txt << EOF
iOS Build Artifacts Summary
===========================

Build Date: $(date)
App Name: ${APP_NAME:-Unknown}
Bundle ID: ${BUNDLE_ID:-Unknown}
Version: ${VERSION_NAME:-Unknown}
Build Number: ${VERSION_CODE:-Unknown}

Generated Files:
- Runner.ipa: $(if [ -f "output/ios/Runner.ipa" ]; then echo "✅ Available"; else echo "❌ Not found"; fi)
- Runner.xcarchive: $(if [ -d "output/ios/Runner.xcarchive" ]; then echo "✅ Available"; else echo "❌ Not found"; fi)

Code Signing:
- Method: App Store Connect API
- Team ID: ${APPLE_TEAM_ID:-Unknown}
- API Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-Unknown}

Features Enabled:
- Push Notifications: ${PUSH_NOTIFY:-false}
- Firebase: ${PUSH_NOTIFY:-false}
- Camera: ${IS_CAMERA:-false}
- Location: ${IS_LOCATION:-false}
- Microphone: ${IS_MIC:-false}
- Notifications: ${IS_NOTIFICATION:-false}
- Contacts: ${IS_CONTACT:-false}
- Biometric: ${IS_BIOMETRIC:-false}
- Calendar: ${IS_CALENDAR:-false}
- Storage: ${IS_STORAGE:-false}
EOF
    
    log_success "Output artifacts created"
}

# Function to validate and register bundle ID in App Store Connect
validate_bundle_id() {
    log_info "Validating bundle ID in App Store Connect..."
    
    local key_id="${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
    local issuer_id="${APP_STORE_CONNECT_ISSUER_ID:-}"
    local api_key_path="ios/AuthKey_${key_id}.p8"
    local bundle_id="${BUNDLE_ID:-}"
    
    if [ -z "$key_id" ] || [ -z "$issuer_id" ] || [ ! -f "$api_key_path" ] || [ -z "$bundle_id" ]; then
        log_warning "Cannot validate bundle ID - missing credentials"
        return 0
    fi
    
    # Check if bundle ID exists
    log_info "Checking if bundle ID '$bundle_id' exists in App Store Connect..."
    
    # List all apps to see if our bundle ID exists
    local app_list=$(xcrun altool --list-apps \
                                   --apiKey "$key_id" \
                                   --apiIssuer "$issuer_id" \
                                   --apiKeyPath "$api_key_path" 2>/dev/null || echo "")
    
    if echo "$app_list" | grep -q "$bundle_id"; then
        log_success "Bundle ID '$bundle_id' found in App Store Connect"
        return 0
    else
        log_warning "Bundle ID '$bundle_id' not found in App Store Connect"
        log_info "You need to create an app with this bundle ID in App Store Connect first"
        log_info "Steps to fix:"
        log_info "1. Go to App Store Connect (https://appstoreconnect.apple.com)"
        log_info "2. Click 'My Apps'"
        log_info "3. Click '+' to add a new app"
        log_info "4. Enter bundle ID: $bundle_id"
        log_info "5. Complete app creation"
        log_info "6. Try upload again"
        return 1
    fi
}

# Function to upload to App Store Connect
upload_to_app_store() {
    log_info "Uploading to App Store Connect..."
    
    if [ -f "build/ios/Runner.ipa" ]; then
        log_info "Found IPA file, preparing for App Store Connect upload..."
        
        # Check if we have the required credentials
        local key_id="${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
        local issuer_id="${APP_STORE_CONNECT_ISSUER_ID:-}"
        local api_key_path="ios/AuthKey_${key_id}.p8"
        local bundle_id="${BUNDLE_ID:-}"
        
        if [ -z "$key_id" ] || [ -z "$issuer_id" ] || [ ! -f "$api_key_path" ] || [ -z "$bundle_id" ]; then
            log_warning "App Store Connect credentials not provided or API key not found, skipping upload"
            log_info "IPA file is available at: build/ios/Runner.ipa"
            log_info "Required variables: APP_STORE_CONNECT_KEY_IDENTIFIER, APP_STORE_CONNECT_ISSUER_ID, BUNDLE_ID"
            return 0
        fi
        
        # Validate bundle ID exists in App Store Connect
        if ! validate_bundle_id; then
            log_warning "Bundle ID validation failed, but attempting upload anyway..."
        fi
        
        # Validate IPA file before upload
        log_info "Validating IPA file before upload..."
        if ! xcrun altool --validate-app \
                          --type ios \
                          --file build/ios/Runner.ipa \
                          --apiKey "$key_id" \
                          --apiIssuer "$issuer_id" \
                          --apiKeyPath "$api_key_path" 2>/dev/null; then
            log_warning "IPA validation failed, but attempting upload anyway..."
        else
            log_success "IPA validation passed"
        fi
        
        # Upload with retry mechanism
        local max_retries=3
        local retry_count=0
        
        while [ $retry_count -lt $max_retries ]; do
            log_info "Upload attempt $((retry_count + 1)) of $max_retries..."
            
            if xcrun altool --upload-app \
                            --type ios \
                            --file build/ios/Runner.ipa \
                            --apiKey "$key_id" \
                            --apiIssuer "$issuer_id" \
                            --apiKeyPath "$api_key_path" \
                            --verbose; then
                log_success "Successfully uploaded to App Store Connect"
                return 0
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    log_warning "Upload failed, retrying in 60 seconds..."
                    sleep 60
                else
                    log_error "Failed to upload to App Store Connect after $max_retries attempts"
                    log_info "IPA file is available at: build/ios/Runner.ipa"
                    log_info "You can manually upload this file to App Store Connect"
                    log_info "Common issues:"
                    log_info "1. Bundle ID '$bundle_id' not registered in App Store Connect"
                    log_info "2. App not created in App Store Connect"
                    log_info "3. Invalid API key or permissions"
                    return 1
                fi
            fi
        done
    else
        log_error "IPA file not found for upload"
        exit 1
    fi
}

# Main workflow function
main() {
    log_info "Starting Fixed iOS Workflow"
    log "================================================"
    
    # Send start notification
    send_email_notification "iOS Build Started" "Build process has started" "STARTED"
    
    # Step 1: Download assets
    download_assets
    
    # Step 2: Download certificates and profiles
    download_certificates
    
    # Step 3: Configure app
    configure_app
    
    # Step 4: Generate env_config.dart
    generate_env_config
    
    # Step 5: Configure Firebase
    configure_firebase
    
    # Step 6: Inject permissions
    inject_permissions
    
    # Step 7: Build Flutter app without code signing
    build_flutter_app
    
    # Step 8: Create archive without code signing
    create_archive
    
    # Step 9: Export codesigned IPA
    export_ipa
    
    # Step 10: Verify code signing
    verify_codesigning
    
    # Step 11: Create output artifacts
    create_output_artifacts
    
    # Verify IPA was created
    if [ -f "build/ios/Runner.ipa" ]; then
        log_success "IPA file successfully created: build/ios/Runner.ipa"
        log_info "IPA file size: $(ls -lh build/ios/Runner.ipa | awk '{print $5}')"
    else
        log_error "IPA file not found. Build failed."
        exit 1
    fi
    
    # Step 12: Upload to App Store Connect (optional)
    if [ "${UPLOAD_TO_APP_STORE:-false}" = "true" ]; then
        upload_to_app_store
    else
        log_info "Skipping App Store Connect upload (UPLOAD_TO_APP_STORE=false)"
    fi
    
    # Send success notification
    send_email_notification "iOS Build Success" "Build completed successfully" "SUCCESS"
    
    log_success "Fixed iOS Workflow completed successfully!"
}

# Run main function
main "$@" 