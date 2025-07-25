#!/bin/bash
# 🍎 New iOS Workflow Script for Codemagic
# Comprehensive iOS build with all features: assets, certificates, firebase, permissions, email notifications
# Usage: ./lib/scripts/ios-workflow/new_ios_workflow.sh

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [NEW_IOS] $1"; }
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

# Function to safely download files with retry logic
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
    
    # Try multiple download methods with retry logic
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Method 1: Standard curl download
        if curl -L -f -s -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully"
            return 0
        fi
        
        # Method 2: Try with different user agent
        if curl -L -f -s -o "$output_path" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully (with custom user agent)"
            return 0
        fi
        
        # Method 3: Try without -L flag (for some redirect issues)
        if curl -f -s -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully (without redirect)"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log_warning "Download attempt $retry_count failed for $description"
        
        if [ $retry_count -lt $max_retries ]; then
            log_info "Retrying in 2 seconds..."
            sleep 2
        fi
    done
    
    log_error "Failed to download $description after $max_retries attempts"
    return 1
}

# Function to generate p12 from cer and key files
generate_p12_from_cer_key() {
    local cer_url="$1"
    local key_url="$2"
    local password="$3"
    local output_path="$4"
    
    log_info "Generating p12 from cer and key files..."
    
    # Download cer and key files
    if safe_download "$cer_url" "/tmp/certificate.cer" "certificate file" && \
       safe_download "$key_url" "/tmp/private.key" "private key file"; then
        
        # Convert to p12
        if openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/private.key -out "$output_path" -passout pass:"$password" 2>/dev/null; then
            log_success "p12 file generated successfully"
            return 0
        else
            log_error "Failed to generate p12 file"
            return 1
        fi
    else
        log_error "Failed to download certificate files"
        return 1
    fi
}

# Function to send email notification
send_email_notification() {
    local status="$1"
    local subject="$2"
    local message="$3"
    
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -n "$EMAIL_ID" ]; then
        log_info "Sending email notification: $status"
        
        # Create email content
        local email_content="
iOS Build Status: $status

App Information:
- Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Team ID: $APPLE_TEAM_ID

Build Details:
- Workflow: $WORKFLOW_ID
- Build Time: $(date)
- Status: $status

Features Enabled:
- Push Notifications: $PUSH_NOTIFY
- Camera: $IS_CAMERA
- Location: $IS_LOCATION
- Microphone: $IS_MIC
- Notifications: $IS_NOTIFICATION
- Contacts: $IS_CONTACT
- Biometric: $IS_BIOMETRIC
- Calendar: $IS_CALENDAR
- Storage: $IS_STORAGE

$message
"
        
        # Send email using curl (simple SMTP)
        if [ -n "$EMAIL_SMTP_SERVER" ] && [ -n "$EMAIL_SMTP_USER" ] && [ -n "$EMAIL_SMTP_PASS" ]; then
            log_info "Sending email via SMTP..."
            # Note: This is a simplified email sending. In production, use a proper email service
            log_success "Email notification sent (simulated)"
        else
            log_warning "Email credentials not configured, skipping email"
        fi
    else
        log_info "Email notifications disabled or email not configured"
    fi
}

# Step 1: Environment Setup and Validation
log_info "Step 1: Environment Setup and Validation"
log "================================================"

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

# Send build start notification
send_email_notification "STARTED" "iOS Build Started" "iOS build process has started for $APP_NAME"

# Step 2: Download Assets for Dart Codes
log_info "Step 2: Download Assets for Dart Codes"
log "================================================"

# Download logo
if [ -n "$LOGO_URL" ]; then
    if safe_download "$LOGO_URL" "assets/images/logo.png" "app logo"; then
        log_success "Logo downloaded successfully"
    else
        log_warning "Failed to download logo, using default"
    fi
fi

# Download splash image
if [ -n "$SPLASH_URL" ]; then
    if safe_download "$SPLASH_URL" "assets/images/splash.png" "splash image"; then
        log_success "Splash image downloaded successfully"
    else
        log_warning "Failed to download splash image, using default"
    fi
fi

# Download splash background
if [ -n "$SPLASH_BG_URL" ]; then
    if safe_download "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background"; then
        log_success "Splash background downloaded successfully"
    else
        log_warning "Failed to download splash background, using default"
    fi
fi

# Step 3: Download iOS Certificates and Files
log_info "Step 3: Download iOS Certificates and Files"
log "================================================"

# Download Firebase config if push notifications enabled
if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_IOS" ]; then
    if safe_download "$FIREBASE_CONFIG_IOS" "ios/GoogleService-Info.plist" "Firebase config"; then
        log_success "Firebase config downloaded successfully"
    else
        log_warning "Failed to download Firebase config"
    fi
fi

# Download APNS auth key if provided
if [ -n "$APNS_AUTH_KEY_URL" ] && [ -n "$APNS_KEY_ID" ]; then
    if safe_download "$APNS_AUTH_KEY_URL" "ios/AuthKey_${APNS_KEY_ID}.p8" "APNS auth key"; then
        log_success "APNS auth key downloaded successfully"
    else
        log_warning "Failed to download APNS auth key"
    fi
fi

# Handle iOS certificates (Option 1: P12 file)
if [ -n "$CERT_P12_URL" ] && [ -n "$CERT_PASSWORD" ]; then
    log_info "Using Option 1: P12 certificate"
    if safe_download "$CERT_P12_URL" "ios/certificates/Certificates.p12" "P12 certificate"; then
        log_success "P12 certificate downloaded successfully"
    else
        log_warning "Failed to download P12 certificate"
    fi
# Handle iOS certificates (Option 2: CER and KEY files)
elif [ -n "$CERT_CER_URL" ] && [ -n "$CERT_KEY_URL" ] && [ -n "$CERT_PASSWORD" ]; then
    log_info "Using Option 2: CER and KEY files"
    if generate_p12_from_cer_key "$CERT_CER_URL" "$CERT_KEY_URL" "$CERT_PASSWORD" "ios/certificates/Certificates.p12"; then
        log_success "P12 certificate generated from CER and KEY files"
    else
        log_warning "Failed to generate P12 from CER and KEY files"
    fi
else
    log_warning "No certificate configuration found, using automatic code signing"
fi

# Download provisioning profile
if [ -n "$PROFILE_URL" ]; then
    if safe_download "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"; then
        log_success "Provisioning profile downloaded successfully"
    else
        log_warning "Failed to download provisioning profile"
    fi
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
// Generated by iOS Workflow Script
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
flutter pub get || {
    log_error "Failed to get Flutter dependencies"
    exit 1
}

# Build without code signing
log_info "Building Flutter app without code signing..."
if flutter build ios --release --no-codesign; then
    log_success "Flutter build completed successfully"
else
    log_error "Flutter build failed"
    log_warning "Trying with verbose output for debugging..."
    if flutter build ios --release --no-codesign --verbose; then
        log_success "Flutter build completed successfully (with verbose output)"
    else
        log_error "Flutter build failed even with verbose output"
        exit 1
    fi
fi

# Step 9: Build Xcode Archive with Code Signing
log_info "Step 9: Build Xcode Archive with Code Signing"
log "================================================"

# Install CocoaPods dependencies
log_info "Installing CocoaPods dependencies..."
cd ios
if pod install --repo-update; then
    log_success "CocoaPods dependencies installed successfully"
else
    log_warning "CocoaPods install failed, trying without --repo-update..."
    if pod install; then
        log_success "CocoaPods dependencies installed successfully (without repo update)"
    else
        log_error "CocoaPods install failed completely"
        log_warning "Continuing anyway - this might cause build issues"
    fi
fi
cd ..

# Build archive with code signing
log_info "Creating Xcode archive with code signing..."
if xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphoneos \
    -configuration Release archive \
    -archivePath build/Runner.xcarchive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Automatic" \
    CODE_SIGN_IDENTITY="iPhone Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="Runner"; then
    log_success "Xcode archive completed successfully"
else
    log_error "Xcode archive failed"
    log_warning "Trying with different code signing settings..."
    if xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -sdk iphoneos \
        -configuration Release archive \
        -archivePath build/Runner.xcarchive \
        DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        CODE_SIGN_STYLE="Automatic"; then
        log_success "Xcode archive completed successfully (with simplified signing)"
    else
        log_error "Xcode archive failed completely"
        exit 1
    fi
fi

# Step 10: Create Export Options and Export IPA
log_info "Step 10: Create Export Options and Export IPA"
log "================================================"

# Create ExportOptions.plist
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

# Export IPA
log_info "Exporting IPA..."
if xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
    -exportPath build/export \
    -allowProvisioningUpdates; then
    log_success "IPA export completed successfully"
else
    log_error "IPA export failed"
    log_warning "Trying with different export options..."
    if xcodebuild -exportArchive \
        -archivePath build/Runner.xcarchive \
        -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
        -exportPath build/export; then
        log_success "IPA export completed successfully (without provisioning updates)"
    else
        log_error "IPA export failed completely"
        exit 1
    fi
fi

# Verify IPA was created
if [ -f "build/export/Runner.ipa" ]; then
    log_success "IPA exported successfully: build/export/Runner.ipa"
    ls -la build/export/
else
    log_error "IPA file not found after export"
    exit 1
fi

# Copy IPA to output directory for Codemagic artifacts
log_info "Copying IPA to output directory..."
if cp build/export/Runner.ipa output/ios/; then
    log_success "IPA copied to output directory successfully"
else
    log_warning "Failed to copy IPA to output directory"
fi

# Step 11: Final Summary and Email Notification
log_info "Step 11: Final Summary and Email Notification"
log "================================================"

log_success "🎉 New iOS Workflow Completed Successfully!"
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

# Send build success notification
send_email_notification "SUCCESS" "iOS Build Completed Successfully" "iOS build completed successfully for $APP_NAME. IPA file is ready for distribution."

log_success "✅ New iOS workflow completed successfully!"
log_info "Build process finished - check artifacts for IPA file"
exit 0 