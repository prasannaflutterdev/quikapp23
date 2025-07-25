#!/bin/bash
# 🍎 Dynamic iOS Workflow Script
# All variables are dynamic and sourced from Codemagic API calls

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DYNAMIC_IOS] $1"; }
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

# Function to validate required variables
validate_required_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_error "These variables must be set via Codemagic API calls"
        return 1
    fi
    
    return 0
}

# Set all dynamic variables from Codemagic API calls
log_info "Loading dynamic variables from Codemagic API..."

# Core workflow variables
WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "")
APPLE_TEAM_ID=$(get_env_var "APPLE_TEAM_ID" "")
IS_TESTFLIGHT=$(get_env_var "IS_TESTFLIGHT" "false")
APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
APP_STORE_CONNECT_ISSUER_ID=$(get_env_var "APP_STORE_CONNECT_ISSUER_ID" "")
APP_STORE_CONNECT_API_KEY_URL=$(get_env_var "APP_STORE_CONNECT_API_KEY_URL" "")

# App information variables
USER_NAME=$(get_env_var "USER_NAME" "")
APP_ID=$(get_env_var "APP_ID" "")
VERSION_NAME=$(get_env_var "VERSION_NAME" "")
VERSION_CODE=$(get_env_var "VERSION_CODE" "")
APP_NAME=$(get_env_var "APP_NAME" "")
ORG_NAME=$(get_env_var "ORG_NAME" "")
WEB_URL=$(get_env_var "WEB_URL" "")
PKG_NAME=$(get_env_var "PKG_NAME" "")
BUNDLE_ID=$(get_env_var "BUNDLE_ID" "")
EMAIL_ID=$(get_env_var "EMAIL_ID" "")

# Feature flags
PUSH_NOTIFY=$(get_env_var "PUSH_NOTIFY" "false")
IS_CHATBOT=$(get_env_var "IS_CHATBOT" "false")
IS_DOMAIN_URL=$(get_env_var "IS_DOMAIN_URL" "false")
IS_SPLASH=$(get_env_var "IS_SPLASH" "false")
IS_PULLDOWN=$(get_env_var "IS_PULLDOWN" "false")
IS_BOTTOMMENU=$(get_env_var "IS_BOTTOMMENU" "false")
IS_LOAD_IND=$(get_env_var "IS_LOAD_IND" "false")

# Permission flags
IS_CAMERA=$(get_env_var "IS_CAMERA" "false")
IS_LOCATION=$(get_env_var "IS_LOCATION" "false")
IS_MIC=$(get_env_var "IS_MIC" "false")
IS_NOTIFICATION=$(get_env_var "IS_NOTIFICATION" "false")
IS_CONTACT=$(get_env_var "IS_CONTACT" "false")
IS_BIOMETRIC=$(get_env_var "IS_BIOMETRIC" "false")
IS_CALENDAR=$(get_env_var "IS_CALENDAR" "false")
IS_STORAGE=$(get_env_var "IS_STORAGE" "false")

# Asset URLs
LOGO_URL=$(get_env_var "LOGO_URL" "")
SPLASH_URL=$(get_env_var "SPLASH_URL" "")
SPLASH_BG_URL=$(get_env_var "SPLASH_BG_URL" "")

# Splash configuration
SPLASH_BG_COLOR=$(get_env_var "SPLASH_BG_COLOR" "#cbdbf5")
SPLASH_TAGLINE=$(get_env_var "SPLASH_TAGLINE" "")
SPLASH_TAGLINE_COLOR=$(get_env_var "SPLASH_TAGLINE_COLOR" "#a30237")
SPLASH_ANIMATION=$(get_env_var "SPLASH_ANIMATION" "zoom")
SPLASH_DURATION=$(get_env_var "SPLASH_DURATION" "4")

# Bottom menu configuration
BOTTOMMENU_ITEMS=$(get_env_var "BOTTOMMENU_ITEMS" "[]")
BOTTOMMENU_BG_COLOR=$(get_env_var "BOTTOMMENU_BG_COLOR" "#FFFFFF")
BOTTOMMENU_ICON_COLOR=$(get_env_var "BOTTOMMENU_ICON_COLOR" "#6d6e8c")
BOTTOMMENU_TEXT_COLOR=$(get_env_var "BOTTOMMENU_TEXT_COLOR" "#6d6e8c")
BOTTOMMENU_FONT=$(get_env_var "BOTTOMMENU_FONT" "DM Sans")
BOTTOMMENU_FONT_SIZE=$(get_env_var "BOTTOMMENU_FONT_SIZE" "12")
BOTTOMMENU_FONT_BOLD=$(get_env_var "BOTTOMMENU_FONT_BOLD" "false")
BOTTOMMENU_FONT_ITALIC=$(get_env_var "BOTTOMMENU_FONT_ITALIC" "false")
BOTTOMMENU_ACTIVE_TAB_COLOR=$(get_env_var "BOTTOMMENU_ACTIVE_TAB_COLOR" "#a30237")
BOTTOMMENU_ICON_POSITION=$(get_env_var "BOTTOMMENU_ICON_POSITION" "above")

# Firebase and push notification configuration
FIREBASE_CONFIG_IOS=$(get_env_var "FIREBASE_CONFIG_IOS" "")
APNS_KEY_ID=$(get_env_var "APNS_KEY_ID" "")
APNS_AUTH_KEY_URL=$(get_env_var "APNS_AUTH_KEY_URL" "")

# Provisioning and certificate configuration
PROFILE_TYPE=$(get_env_var "PROFILE_TYPE" "app-store")
PROFILE_URL=$(get_env_var "PROFILE_URL" "")
CERT_PASSWORD=$(get_env_var "CERT_PASSWORD" "quikapp2025")
CERT_P12_URL=$(get_env_var "CERT_P12_URL" "")
CERT_CER_URL=$(get_env_var "CERT_CER_URL" "")
CERT_KEY_URL=$(get_env_var "CERT_KEY_URL" "")

# Email configuration
ENABLE_EMAIL_NOTIFICATIONS=$(get_env_var "ENABLE_EMAIL_NOTIFICATIONS" "false")
EMAIL_SMTP_SERVER=$(get_env_var "EMAIL_SMTP_SERVER" "smtp.gmail.com")
EMAIL_SMTP_PORT=$(get_env_var "EMAIL_SMTP_PORT" "587")
EMAIL_SMTP_USER=$(get_env_var "EMAIL_SMTP_USER" "")
EMAIL_SMTP_PASS=$(get_env_var "EMAIL_SMTP_PASS" "")

# Validate critical required variables
log_info "Validating critical required variables..."

required_vars=(
    "WORKFLOW_ID"
    "APPLE_TEAM_ID"
    "USER_NAME"
    "APP_ID"
    "VERSION_NAME"
    "VERSION_CODE"
    "APP_NAME"
    "ORG_NAME"
    "WEB_URL"
    "PKG_NAME"
    "BUNDLE_ID"
    "EMAIL_ID"
)

if ! validate_required_vars "${required_vars[@]}"; then
    log_error "Critical variables missing. Please ensure all required variables are set via Codemagic API calls."
    exit 1
fi

log_success "All critical variables validated successfully"

# Log all dynamic variables for debugging
log_info "Dynamic Variables Summary:"
log "================================================"
log "Workflow: $WORKFLOW_ID"
log "Team ID: $APPLE_TEAM_ID"
log "TestFlight: $IS_TESTFLIGHT"
log "App Store Connect Key ID: $APP_STORE_CONNECT_KEY_IDENTIFIER"
log "App Store Connect Issuer ID: $APP_STORE_CONNECT_ISSUER_ID"
log "App Store Connect API Key URL: $APP_STORE_CONNECT_API_KEY_URL"
log "User: $USER_NAME"
log "App ID: $APP_ID"
log "Version: $VERSION_NAME ($VERSION_CODE)"
log "App Name: $APP_NAME"
log "Organization: $ORG_NAME"
log "Web URL: $WEB_URL"
log "Package: $PKG_NAME"
log "Bundle ID: $BUNDLE_ID"
log "Email: $EMAIL_ID"
log "Push Notify: $PUSH_NOTIFY"
log "Chatbot: $IS_CHATBOT"
log "Domain URL: $IS_DOMAIN_URL"
log "Splash: $IS_SPLASH"
log "Pull Down: $IS_PULLDOWN"
log "Bottom Menu: $IS_BOTTOMMENU"
log "Load Indicator: $IS_LOAD_IND"
log "Camera: $IS_CAMERA"
log "Location: $IS_LOCATION"
log "Microphone: $IS_MIC"
log "Notification: $IS_NOTIFICATION"
log "Contact: $IS_CONTACT"
log "Biometric: $IS_BIOMETRIC"
log "Calendar: $IS_CALENDAR"
log "Storage: $IS_STORAGE"
log "Logo URL: $LOGO_URL"
log "Splash URL: $SPLASH_URL"
log "Splash BG URL: $SPLASH_BG_URL"
log "Splash BG Color: $SPLASH_BG_COLOR"
log "Splash Tagline: $SPLASH_TAGLINE"
log "Splash Tagline Color: $SPLASH_TAGLINE_COLOR"
log "Splash Animation: $SPLASH_ANIMATION"
log "Splash Duration: $SPLASH_DURATION"
log "Bottom Menu Items: $BOTTOMMENU_ITEMS"
log "Bottom Menu BG Color: $BOTTOMMENU_BG_COLOR"
log "Bottom Menu Icon Color: $BOTTOMMENU_ICON_COLOR"
log "Bottom Menu Text Color: $BOTTOMMENU_TEXT_COLOR"
log "Bottom Menu Font: $BOTTOMMENU_FONT"
log "Bottom Menu Font Size: $BOTTOMMENU_FONT_SIZE"
log "Bottom Menu Font Bold: $BOTTOMMENU_FONT_BOLD"
log "Bottom Menu Font Italic: $BOTTOMMENU_FONT_ITALIC"
log "Bottom Menu Active Tab Color: $BOTTOMMENU_ACTIVE_TAB_COLOR"
log "Bottom Menu Icon Position: $BOTTOMMENU_ICON_POSITION"
log "Firebase Config iOS: $FIREBASE_CONFIG_IOS"
log "APNS Key ID: $APNS_KEY_ID"
log "APNS Auth Key URL: $APNS_AUTH_KEY_URL"
log "Profile Type: $PROFILE_TYPE"
log "Profile URL: $PROFILE_URL"
log "Cert Password: $CERT_PASSWORD"
log "Cert P12 URL: $CERT_P12_URL"
log "Cert CER URL: $CERT_CER_URL"
log "Cert KEY URL: $CERT_KEY_URL"
log "Enable Email Notifications: $ENABLE_EMAIL_NOTIFICATIONS"
log "Email SMTP Server: $EMAIL_SMTP_SERVER"
log "Email SMTP Port: $EMAIL_SMTP_PORT"
log "Email SMTP User: $EMAIL_SMTP_USER"
log "Email SMTP Pass: [HIDDEN]"

# Continue with the rest of the workflow...
log_success "All dynamic variables loaded successfully from Codemagic API calls"

# Now proceed with the actual workflow steps
log_info "Starting dynamic iOS workflow with all variables sourced from Codemagic API..."

# Import the certificate generation functions from the enhanced workflow
source lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh

log_success "Dynamic iOS workflow completed successfully"
exit 0 