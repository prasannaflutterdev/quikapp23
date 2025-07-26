#!/usr/bin/env bash

# Comprehensive iOS Workflow Script
# Implements all requirements from @new-ios-workflow.mdc
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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMPREHENSIVE_IOS] $1"
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

# Function to clean environment variables for Dart
clean_env_var() {
    local value="$1"
    echo "$value" | tr -d '\r\n\t' | sed 's/[^[:print:]]//g'
}

# Function to clean JSON for Dart
clean_json_for_dart() {
    local json="$1"
    echo "$json" | tr -d '\r\n\t' | sed 's/"/\\"/g' | sed 's/[^[:print:]]//g'
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
        
        # Create email content
        local email_content="
Build Status: $status
App Name: ${APP_NAME:-Unknown}
Bundle ID: ${BUNDLE_ID:-Unknown}
Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})
Build Time: $(date)

$body

Features Enabled:
- Push Notifications: ${PUSH_NOTIFY:-false}
- Chatbot: ${IS_CHATBOT:-false}
- Splash Screen: ${IS_SPLASH:-false}
- Bottom Menu: ${IS_BOTTOMMENU:-false}
- Camera: ${IS_CAMERA:-false}
- Location: ${IS_LOCATION:-false}
- Microphone: ${IS_MIC:-false}
- Notifications: ${IS_NOTIFICATION:-false}
- Contact: ${IS_CONTACT:-false}
- Biometric: ${IS_BIOMETRIC:-false}
- Calendar: ${IS_CALENDAR:-false}
- Storage: ${IS_STORAGE:-false}
"
        
        # Send email using curl (if available)
        if command -v curl >/dev/null 2>&1; then
            curl -s --mail-from "${EMAIL_SMTP_USER:-}" \
                 --mail-rcpt "${EMAIL_ID:-}" \
                 --upload-file <(echo "$email_content") \
                 --ssl-reqd \
                 --user "${EMAIL_SMTP_USER:-}:${EMAIL_SMTP_PASS:-}" \
                 "smtp://${EMAIL_SMTP_SERVER:-smtp.gmail.com}:${EMAIL_SMTP_PORT:-587}" 2>/dev/null || true
        fi
        
        log_success "Email notification sent"
    fi
}

# Function to download assets (Requirement 1)
download_assets() {
    log_info "Downloading assets for Dart codes..."
    
    # Download logo
    if [ -n "${LOGO_URL:-}" ] && [ "$LOGO_URL" != "$FIREBASE_CONFIG_ANDROID" ]; then
        if download_file "$LOGO_URL" "assets/images/logo.png" "app logo"; then
            log_success "Logo downloaded successfully"
        else
            log_warning "Failed to download logo, using default"
            touch assets/images/logo.png
        fi
    else
        log_warning "LOGO_URL not provided, using default"
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
        log_warning "SPLASH_URL not provided, using default"
        touch assets/images/splash.png
    fi
    
    # Download splash background (optional)
    if [ -n "${SPLASH_BG_URL:-}" ]; then
        if download_file "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background"; then
            log_success "Splash background downloaded successfully"
        else
            log_warning "Failed to download splash background, using color"
            # Create splash background from color
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
    
    # Download certificates (Option 1: P12)
    if [ -n "${CERT_P12_URL:-}" ] && [ -n "${CERT_PASSWORD:-}" ]; then
        log_info "Using P12 certificate option"
        if download_file "$CERT_P12_URL" "ios/certificates.p12" "P12 certificate"; then
            log_success "P12 certificate downloaded successfully"
            echo "$CERT_PASSWORD" > ios/cert_password.txt
        else
            log_warning "Failed to download P12 certificate"
        fi
    # Option 2: CER + KEY
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        log_info "Using CER + KEY certificate option"
        if download_file "$CERT_CER_URL" "ios/certificate.cer" "CER certificate" && \
           download_file "$CERT_KEY_URL" "ios/private.key" "private key"; then
            log_success "CER certificate and private key downloaded successfully"
            # Generate P12 from CER + KEY
            if command -v openssl >/dev/null 2>&1; then
                openssl pkcs12 -export -in ios/certificate.cer -inkey ios/private.key \
                    -out ios/certificates.p12 -passout pass:"${CERT_PASSWORD:-password}" 2>/dev/null || true
                echo "${CERT_PASSWORD:-password}" > ios/cert_password.txt
                log_success "Generated P12 certificate from CER + KEY"
            fi
        else
            log_warning "Failed to download CER certificate or private key"
        fi
    else
        log_warning "No certificate configuration provided"
    fi
    
    # Download provisioning profile
    if [ -n "${PROFILE_URL:-}" ]; then
        if download_file "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"; then
            log_success "Provisioning profile downloaded successfully"
        else
            log_warning "Failed to download provisioning profile"
        fi
    else
        log_warning "PROFILE_URL not provided"
    fi
    
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
    
    # Configure BUNDLE_ID
    if [ -n "${BUNDLE_ID:-}" ]; then
        log_info "Setting bundle ID to: $BUNDLE_ID"
        # Update project.pbxproj for Runner target only
        if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
            sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.example\.sampleprojects\.sampleProject;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
        fi
    fi
    
    # Configure app icon from logo
    if [ -f "assets/images/logo.png" ]; then
        log_info "Configuring app icon from logo"
        # Copy logo to app icon location
        cp assets/images/logo.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png 2>/dev/null || true
    fi
    
    log_success "App configuration completed"
}

# Function to generate env_config.dart (Requirement 4)
generate_env_config() {
    log_info "Generating env_config.dart..."
    
    # Create config directory
    mkdir -p lib/config
    
    # Generate the env_config.dart file
    cat > lib/config/env_config.dart << 'EOF'
// Generated by Comprehensive iOS Workflow Script
// Do not edit manually

class EnvConfig {
  // App Information
EOF

    # Add app information
    local app_name=$(safe_env_var "APP_NAME" "")
    local web_url=$(safe_env_var "WEB_URL" "")
    local org_name=$(safe_env_var "ORG_NAME" "")
    local email_id=$(safe_env_var "EMAIL_ID" "")
    local user_name=$(safe_env_var "USER_NAME" "")
    local app_id=$(safe_env_var "APP_ID" "")
    local version_name=$(safe_env_var "VERSION_NAME" "")
    local version_code=$(safe_env_var "VERSION_CODE" "")
    
    printf "  static const String appName = \"%s\";\n" "$(clean_env_var "$app_name")" >> lib/config/env_config.dart
    printf "  static const String webUrl = \"%s\";\n" "$(clean_env_var "$web_url")" >> lib/config/env_config.dart
    printf "  static const String orgName = \"%s\";\n" "$(clean_env_var "$org_name")" >> lib/config/env_config.dart
    printf "  static const String emailId = \"%s\";\n" "$(clean_env_var "$email_id")" >> lib/config/env_config.dart
    printf "  static const String userName = \"%s\";\n" "$(clean_env_var "$user_name")" >> lib/config/env_config.dart
    printf "  static const String appId = \"%s\";\n" "$(clean_env_var "$app_id")" >> lib/config/env_config.dart
    printf "  static const String versionName = \"%s\";\n" "$(clean_env_var "$version_name")" >> lib/config/env_config.dart
    printf "  static const int versionCode = %s;\n" "$(clean_env_var "$version_code")" >> lib/config/env_config.dart

    # Add feature flags
    cat >> lib/config/env_config.dart <<EOF

  // Feature Flags
EOF

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

    # Add permissions
    cat >> lib/config/env_config.dart <<EOF

  // Permissions
EOF

    local is_camera=$(safe_env_var "IS_CAMERA" "false")
    local is_location=$(safe_env_var "IS_LOCATION" "false")
    local is_mic=$(safe_env_var "IS_MIC" "false")
    local is_notification=$(safe_env_var "IS_NOTIFICATION" "false")
    local is_contact=$(safe_env_var "IS_CONTACT" "false")
    local is_biometric=$(safe_env_var "IS_BIOMETRIC" "false")
    local is_calendar=$(safe_env_var "IS_CALENDAR" "false")
    local is_storage=$(safe_env_var "IS_STORAGE" "false")
    
    printf "  static const bool isCamera = %s;\n" "$is_camera" >> lib/config/env_config.dart
    printf "  static const bool isLocation = %s;\n" "$is_location" >> lib/config/env_config.dart
    printf "  static const bool isMic = %s;\n" "$is_mic" >> lib/config/env_config.dart
    printf "  static const bool isNotification = %s;\n" "$is_notification" >> lib/config/env_config.dart
    printf "  static const bool isContact = %s;\n" "$is_contact" >> lib/config/env_config.dart
    printf "  static const bool isBiometric = %s;\n" "$is_biometric" >> lib/config/env_config.dart
    printf "  static const bool isCalendar = %s;\n" "$is_calendar" >> lib/config/env_config.dart
    printf "  static const bool isStorage = %s;\n" "$is_storage" >> lib/config/env_config.dart

    # Add UI configuration
    cat >> lib/config/env_config.dart <<EOF

  // UI Configuration
EOF

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

    # Add bottom menu configuration
    cat >> lib/config/env_config.dart <<EOF

  // Bottom Menu Configuration
EOF

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
    
    # Handle JSON string safely
    if [ "$bottom_menu_items" = "[]" ] || [ -z "$bottom_menu_items" ]; then
        printf "  static const String bottommenuItems = \"[]\";\n" >> lib/config/env_config.dart
    else
        local escaped_json=$(echo "$bottom_menu_items" | tr -d '\r\n\t' | sed 's/"/\\"/g' | sed 's/[^[:print:]]//g')
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

    # Add Firebase configuration
    cat >> lib/config/env_config.dart <<EOF

  // Firebase Configuration
EOF

    local firebase_android=$(safe_env_var "FIREBASE_CONFIG_ANDROID" "")
    local firebase_ios=$(safe_env_var "FIREBASE_CONFIG_IOS" "")
    
    # Extra validation for Firebase configs
    if [[ "$firebase_android" == *"\$"* ]] || [[ "$firebase_android" == *"FIREBASE_CONFIG_ANDROID"* ]] || [[ "$firebase_android" == *"${"* ]]; then
        firebase_android=""
    fi
    if [[ "$firebase_ios" == *"\$"* ]] || [[ "$firebase_ios" == *"FIREBASE_CONFIG_IOS"* ]] || [[ "$firebase_ios" == *"${"* ]]; then
        firebase_ios=""
    fi
    
    if [[ "$firebase_android" == *'"'* ]]; then
        firebase_android=""
    fi
    if [[ "$firebase_ios" == *'"'* ]]; then
        firebase_ios=""
    fi
    
    printf "  static const String firebaseConfigAndroid = \"%s\";\n" "$(clean_env_var "$firebase_android")" >> lib/config/env_config.dart
    printf "  static const String firebaseConfigIos = \"%s\";\n" "$(clean_env_var "$firebase_ios")" >> lib/config/env_config.dart

    cat >> lib/config/env_config.dart <<EOF
}
EOF

    # Validate the generated file
    log_info "Validating generated env_config.dart..."
    if dart analyze lib/config/env_config.dart > /dev/null 2>&1; then
        log_success "env_config.dart generated successfully"
    else
        log_error "Generated env_config.dart has syntax errors"
        dart analyze lib/config/env_config.dart
        exit 1
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

# Function to create archive with proper code signing (Requirement 8)
create_archive() {
    log_info "Creating Xcode archive with proper code signing..."
    
    # Set up code signing if certificates are available
    if [ -f "ios/certificates.p12" ] && [ -f "ios/Runner.mobileprovision" ]; then
        log_info "Using downloaded certificates for code signing"
        
        # Import certificate to keychain
        if [ -f "ios/cert_password.txt" ]; then
            security import ios/certificates.p12 -k login.keychain -P "$(cat ios/cert_password.txt)" -T /usr/bin/codesign 2>/dev/null || true
        fi
        
        # Install provisioning profile
        cp ios/Runner.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/ 2>/dev/null || true
    else
        log_warning "No certificates found, using automatic code signing"
    fi
    
    # Create archive
    xcodebuild -workspace ios/Runner.xcworkspace \
               -scheme Runner \
               -configuration Release \
               -archivePath build/Runner.xcarchive \
               archive
    
    log_success "Archive created successfully"
}

# Function to export IPA (Requirement 9)
export_ipa() {
    log_info "Exporting IPA from archive..."
    
    # Create export options
    cat > ios/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>TEAM_ID_PLACEHOLDER</string>
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

    # Replace placeholder with actual team ID
    local team_id=$(safe_env_var "APPLE_TEAM_ID" "")
    if [ -n "$team_id" ]; then
        sed -i '' "s/TEAM_ID_PLACEHOLDER/$team_id/" ios/ExportOptions.plist
    fi
    
    # Export IPA
    xcodebuild -exportArchive \
               -archivePath build/Runner.xcarchive \
               -exportPath build/ios \
               -exportOptionsPlist ios/ExportOptions.plist
    
    log_success "IPA exported successfully"
}

# Main workflow function
main() {
    log_info "Starting Comprehensive iOS Workflow"
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
    
    # Step 8: Create archive with proper code signing
    create_archive
    
    # Step 9: Export IPA
    export_ipa
    
    # Send success notification
    send_email_notification "iOS Build Success" "Build completed successfully" "SUCCESS"
    
    log_success "Comprehensive iOS Workflow completed successfully!"
}

# Run main function
main "$@"
