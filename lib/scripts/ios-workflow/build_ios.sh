#!/bin/bash
# 🚀 Single iOS Workflow Script for Codemagic
# Handles complete iOS build process: env setup → validation → build → archive → export → upload
# Usage: ./lib/scripts/ios-workflow/build_ios.sh

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] $1"; }
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

# Step 1: Environment Setup and Validation
log_info "Step 1: Environment Setup and Validation"
log "================================================"

# Set all required variables with defaults
export WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "ios-workflow")
export APP_NAME=$(get_env_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_env_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_env_var "VERSION_CODE" "1")
export EMAIL_ID=$(get_env_var "EMAIL_ID" "admin@example.com")
export BUNDLE_ID=$(get_env_var "BUNDLE_ID" "com.example.quikapp")
export APPLE_TEAM_ID=$(get_env_var "APPLE_TEAM_ID" "")
export PROFILE_TYPE=$(get_env_var "PROFILE_TYPE" "app-store")
export PROFILE_URL=$(get_env_var "PROFILE_URL" "")
export IS_TESTFLIGHT=$(get_env_var "IS_TESTFLIGHT" "false")
export APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
export APP_STORE_CONNECT_ISSUER_ID=$(get_env_var "APP_STORE_CONNECT_ISSUER_ID" "")
export APP_STORE_CONNECT_API_KEY_URL=$(get_env_var "APP_STORE_CONNECT_API_KEY_URL" "")
export LOGO_URL=$(get_env_var "LOGO_URL" "")
export SPLASH_URL=$(get_env_var "SPLASH_URL" "")
export SPLASH_BG_COLOR=$(get_env_var "SPLASH_BG_COLOR" "#FFFFFF")
export SPLASH_TAGLINE=$(get_env_var "SPLASH_TAGLINE" "")
export SPLASH_TAGLINE_COLOR=$(get_env_var "SPLASH_TAGLINE_COLOR" "#000000")
export FIREBASE_CONFIG_IOS=$(get_env_var "FIREBASE_CONFIG_IOS" "")
export ENABLE_EMAIL_NOTIFICATIONS=$(get_env_var "ENABLE_EMAIL_NOTIFICATIONS" "false")
export EMAIL_SMTP_SERVER=$(get_env_var "EMAIL_SMTP_SERVER" "")
export EMAIL_SMTP_PORT=$(get_env_var "EMAIL_SMTP_PORT" "587")
export EMAIL_SMTP_USER=$(get_env_var "EMAIL_SMTP_USER" "")
export EMAIL_SMTP_PASS=$(get_env_var "EMAIL_SMTP_PASS" "")
export USER_NAME=$(get_env_var "USER_NAME" "Admin")
export APP_ID=$(get_env_var "APP_ID" "quikapp")
export ORG_NAME=$(get_env_var "ORG_NAME" "QuikApp")
export WEB_URL=$(get_env_var "WEB_URL" "https://quikapp.com")
export PKG_NAME=$(get_env_var "PKG_NAME" "com.example.quikapp")
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

# Step 2: Download Assets and Setup
log_info "Step 2: Download Assets and Setup"
log "================================================"

# Download provisioning profile if URL provided
if [ -n "$PROFILE_URL" ]; then
    log_info "Downloading provisioning profile..."
    if safe_download "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"; then
        log_success "Provisioning profile downloaded"
    else
        log_warning "Failed to download provisioning profile, continuing without it"
    fi
fi

# Download App Store Connect API key if URL provided
if [ -n "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    log_info "Downloading App Store Connect API key..."
    if safe_download "$APP_STORE_CONNECT_API_KEY_URL" "ios/AuthKey.p8" "App Store Connect API key"; then
        log_success "App Store Connect API key downloaded"
    else
        log_warning "Failed to download App Store Connect API key"
    fi
fi

# Download app icons and splash if URLs provided
if [ -n "$LOGO_URL" ]; then
    log_info "Downloading app logo..."
    safe_download "$LOGO_URL" "assets/images/logo.png" "app logo" || log_warning "Failed to download logo"
fi

if [ -n "$SPLASH_URL" ]; then
    log_info "Downloading splash image..."
    safe_download "$SPLASH_URL" "assets/images/splash.png" "splash image" || log_warning "Failed to download splash"
fi

# Step 3: Generate Environment Configuration
log_info "Step 3: Generate Environment Configuration"
log "================================================"

# Generate env_config.dart
log_info "Generating env_config.dart..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    bash lib/scripts/utils/gen_env_config.sh || {
        log_error "Failed to generate env_config.dart"
        exit 1
    }
else
    log_error "gen_env_config.sh not found"
    exit 1
fi

# Verify no duplicate workflowId
if grep -c "static const String workflowId" lib/config/env_config.dart | grep -q "1"; then
    log_success "env_config.dart generated successfully (no duplicates)"
else
    log_error "Duplicate workflowId found in env_config.dart"
    log "File contents:"
    cat lib/config/env_config.dart
    exit 1
fi

# Step 4: Inject iOS Permissions
log_info "Step 4: Inject iOS Permissions"
log "================================================"

# Inject required permissions into Info.plist
if [ -f "lib/scripts/ios-workflow/inject_info_plist.sh" ]; then
    bash lib/scripts/ios-workflow/inject_info_plist.sh || {
        log_error "Failed to inject Info.plist permissions"
        exit 1
    }
    log_success "iOS permissions injected"
else
    log_warning "inject_info_plist.sh not found, skipping permission injection"
fi

# Step 5: Flutter Dependencies and Clean
log_info "Step 5: Flutter Dependencies and Clean"
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

# Verify speech_to_text alternative (voice_assistant) is available
if flutter pub deps | grep -q "voice_assistant"; then
    log_success "voice_assistant package is available"
else
    log_warning "voice_assistant package not found, adding it..."
    flutter pub add voice_assistant || {
        log_error "Failed to add voice_assistant package"
        exit 1
    }
fi

# Step 6: iOS Setup
log_info "Step 6: iOS Setup"
log "================================================"

# Update iOS minimum version if needed
if [ -f "ios/Podfile" ]; then
    log_info "Updating iOS Podfile..."
    sed -i '' 's/platform :ios, '"'"'[0-9.]*'"'"'/platform :ios, '"'"'12.0'"'"'/g' ios/Podfile || log_warning "Failed to update Podfile"
fi

# Install CocoaPods dependencies
log_info "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update || {
    log_error "Failed to install CocoaPods dependencies"
    exit 1
}
cd ..

log_success "iOS setup completed"

# Step 7: Flutter Build (No Code Signing)
log_info "Step 7: Flutter Build (No Code Signing)"
log "================================================"

log_info "Building Flutter app without code signing..."
flutter build ios --release --no-codesign || {
    log_error "Flutter build failed"
    exit 1
}

log_success "Flutter build completed"

# Step 8: Xcode Archive (With Code Signing)
log_info "Step 8: Xcode Archive (With Code Signing)"
log "================================================"

log_info "Creating Xcode archive with code signing..."
xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphoneos \
    -configuration Release archive \
    -archivePath build/Runner.xcarchive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Automatic" \
    CODE_SIGN_IDENTITY="iPhone Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="Runner" || {
    log_error "Xcode archive failed"
    exit 1
}

log_success "Xcode archive completed"

# Step 9: Export IPA
log_info "Step 9: Export IPA"
log "================================================"

# Create ExportOptions.plist if it doesn't exist
if [ ! -f "lib/scripts/ios-workflow/exportOptions.plist" ]; then
    log_info "Creating ExportOptions.plist..."
    cat > lib/scripts/ios-workflow/exportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
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
fi

log_info "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
    -exportPath build/export \
    -allowProvisioningUpdates || {
    log_error "IPA export failed"
    exit 1
}

# Verify IPA was created
if [ -f "build/export/Runner.ipa" ]; then
    log_success "IPA exported successfully: build/export/Runner.ipa"
    ls -la build/export/
else
    log_error "IPA file not found after export"
    exit 1
fi

# Step 10: Upload to TestFlight (Optional)
log_info "Step 10: Upload to TestFlight (Optional)"
log "================================================"

if [ "$IS_TESTFLIGHT" = "true" ] && [ -n "$APP_STORE_CONNECT_KEY_IDENTIFIER" ]; then
    log_info "Uploading to TestFlight..."
    
    # Use altool for upload
    xcrun altool --upload-app \
        --type ios \
        --file build/export/Runner.ipa \
        --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
        --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" || {
        log_error "TestFlight upload failed"
        exit 1
    }
    
    log_success "App uploaded to TestFlight successfully"
else
    log_info "Skipping TestFlight upload (IS_TESTFLIGHT=$IS_TESTFLIGHT)"
fi

# Step 11: Email Notification (Optional)
log_info "Step 11: Email Notification (Optional)"
log "================================================"

if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -n "$EMAIL_ID" ]; then
    log_info "Sending email notification..."
    
    if [ -f "lib/scripts/ios-workflow/send_email_notification.sh" ]; then
        bash lib/scripts/ios-workflow/send_email_notification.sh "$EMAIL_ID" "$WORKFLOW_ID" "success" || {
            log_warning "Email notification failed"
        }
    else
        log_warning "send_email_notification.sh not found, skipping email"
    fi
else
    log_info "Skipping email notification (ENABLE_EMAIL_NOTIFICATIONS=$ENABLE_EMAIL_NOTIFICATIONS)"
fi

# Step 12: Final Summary
log_info "Step 12: Final Summary"
log "================================================"

log_success "🎉 iOS Build Workflow Completed Successfully!"
log "📱 App: $APP_NAME v$VERSION_NAME ($VERSION_CODE)"
log "🆔 Bundle ID: $BUNDLE_ID"
log "👥 Team ID: $APPLE_TEAM_ID"
log "📦 IPA Location: build/export/Runner.ipa"
log "🚀 TestFlight: $IS_TESTFLIGHT"

# Copy IPA to output directory for Codemagic artifacts
cp build/export/Runner.ipa output/ios/ || log_warning "Failed to copy IPA to output directory"

log_success "✅ iOS workflow completed successfully!"
exit 0 