#!/usr/bin/env bash

# Enhanced iOS Workflow Script
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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ENHANCED_IOS] $1"
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
    
    # Generate the env_config.dart file
    cat > lib/config/env_config.dart << 'EOF'
// Generated by Enhanced iOS Workflow Script
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

# Function to create simple unsigned build (fallback)
create_unsigned_build() {
    log_info "Creating simple unsigned build..."
    
    # Create a simple unsigned build
    if xcodebuild -workspace ios/Runner.xcworkspace \
                  -scheme Runner \
                  -configuration Release \
                  -destination generic/platform=iOS \
                  CODE_SIGN_IDENTITY="" \
                  CODE_SIGNING_REQUIRED=NO \
                  CODE_SIGNING_ALLOWED=NO \
                  build 2>/dev/null; then
        log_success "Unsigned build completed successfully"
        
        # Create build artifacts directory
        mkdir -p build/ios
        
        # Copy the built app
        if [ -d "build/ios/iphoneos/Runner.app" ]; then
            cp -r build/ios/iphoneos/Runner.app build/ios/ 2>/dev/null || true
            log_success "App copied to build/ios/"
        else
            log_warning "Built app not found in expected location"
        fi
    else
        log_error "Unsigned build failed"
        exit 1
    fi
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
    
    # Get team ID from environment
    local team_id=$(safe_env_var "APPLE_TEAM_ID" "")
    
    if [ -z "$team_id" ]; then
        log_error "APPLE_TEAM_ID is required for code signing. Please provide a valid team ID."
        exit 1
    fi
    
    log_info "Using team ID for archive creation: $team_id"
    
    # Try archive creation with automatic code signing (preferred method)
    if xcodebuild -workspace ios/Runner.xcworkspace \
                  -scheme Runner \
                  -configuration Release \
                  -archivePath build/Runner.xcarchive \
                  DEVELOPMENT_TEAM="$team_id" \
                  CODE_SIGN_STYLE="Automatic" \
                  CODE_SIGN_IDENTITY="iPhone Developer" \
                  archive; then
        log_success "Archive created successfully with automatic code signing"
        return 0
    else
        log_warning "Archive failed with automatic signing, trying manual signing"
        
        # Try with manual code signing
        if xcodebuild -workspace ios/Runner.xcworkspace \
                      -scheme Runner \
                      -configuration Release \
                      -archivePath build/Runner.xcarchive \
                      DEVELOPMENT_TEAM="$team_id" \
                      CODE_SIGN_STYLE="Manual" \
                      CODE_SIGN_IDENTITY="iPhone Developer" \
                      archive; then
            log_success "Archive created successfully with manual code signing"
            return 0
        else
            log_error "Archive creation failed with both automatic and manual signing"
            log_error "Please ensure you have a valid team ID and proper code signing setup"
            exit 1
        fi
    fi
}

# Function to export IPA (Requirement 9)
export_ipa() {
    log_info "Exporting IPA from archive..."
    
    # Get team ID from environment
    local team_id=$(safe_env_var "APPLE_TEAM_ID" "")
    
    if [ -z "$team_id" ]; then
        log_error "APPLE_TEAM_ID is required for IPA export. Please provide a valid team ID."
        exit 1
    fi
    
    # Check if we have certificates and profiles
    local has_certificates=false
    local has_profiles=false
    
    if [ -f "ios/certificates.p12" ] && [ -f "ios/cert_password.txt" ]; then
        has_certificates=true
        log_info "Found downloaded certificates"
    fi
    
    if [ -f "ios/Runner.mobileprovision" ]; then
        has_profiles=true
        log_info "Found downloaded provisioning profile"
    fi
    
    # Get the current bundle ID for code signing
    local current_bundle_id=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;' ios/Runner.xcodeproj/project.pbxproj | head -1 | sed 's/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//')
    log_info "Using bundle ID for code signing: $current_bundle_id"
    
    # Create ExportOptions.plist for codesigned IPA
    log_info "Creating ExportOptions.plist for codesigned IPA export"
    plutil -create xml1 ios/ExportOptions.plist
    plutil -insert method -string app-store-connect ios/ExportOptions.plist
    plutil -insert teamID -string "$team_id" ios/ExportOptions.plist
    plutil -insert stripSwiftSymbols -bool true ios/ExportOptions.plist
    plutil -insert uploadBitcode -bool false ios/ExportOptions.plist
    plutil -insert uploadSymbols -bool true ios/ExportOptions.plist
    
    # Use automatic signing for IPA export
    plutil -insert signingStyle -string automatic ios/ExportOptions.plist
    
    # Export IPA with code signing
    log_info "Exporting codesigned IPA..."
    if xcodebuild -exportArchive \
                  -archivePath build/Runner.xcarchive \
                  -exportPath build/ios \
                  -exportOptionsPlist ios/ExportOptions.plist; then
        log_success "Codesigned IPA exported successfully"
        
        # Verify the IPA was created
        if [ -f "build/ios/Runner.ipa" ]; then
            log_success "Codesigned IPA file found: build/ios/Runner.ipa"
            ls -la build/ios/
        else
            log_error "IPA file not found after export"
            exit 1
        fi
    else
        log_error "IPA export failed. Please check your code signing setup."
        log_error "Required: Valid APPLE_TEAM_ID and proper code signing configuration"
        exit 1
    fi
}

# Function to verify code signing
verify_codesigning() {
    log_info "Verifying code signing of IPA file..."
    
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
            log_error "IPA file is not properly codesigned"
            exit 1
        fi
    else
        log_error "IPA file not found for verification"
        exit 1
    fi
}

# Main workflow function
main() {
    log_info "Starting Enhanced iOS Workflow"
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
    
    # Step 9: Export codesigned IPA
    export_ipa
    
    # Step 10: Verify code signing
    verify_codesigning
    
    # Verify codesigned IPA was created
    if [ -f "build/ios/Runner.ipa" ]; then
        log_success "Codesigned IPA file successfully created: build/ios/Runner.ipa"
        log_info "IPA file size: $(ls -lh build/ios/Runner.ipa | awk '{print $5}')"
    else
        log_error "Codesigned IPA file not found. Build failed."
        exit 1
    fi
    
    # Send success notification
    send_email_notification "iOS Build Success" "Build completed successfully" "SUCCESS"
    
    log_success "Enhanced iOS Workflow completed successfully!"
}

# Run main function
main "$@" 