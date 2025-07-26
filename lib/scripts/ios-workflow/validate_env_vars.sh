#!/usr/bin/env bash

# Environment Variables Validation Script for iOS Workflow
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
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

# Function to validate URL
validate_url() {
    local url="$1"
    local description="$2"
    
    if [ -z "$url" ]; then
        log_error "$description: URL is empty"
        return 1
    fi
    
    if [[ "$url" == *"\$"* ]]; then
        log_error "$description: URL contains unresolved variable: $url"
        return 1
    fi
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_error "$description: URL is not a valid HTTP/HTTPS URL: $url"
        return 1
    fi
    
    log_success "$description: $url"
    return 0
}

# Function to validate required variable
validate_required() {
    local var_name="$1"
    local description="$2"
    local value=$(safe_env_var "$var_name" "")
    
    if [ -z "$value" ]; then
        log_error "$description: $var_name is required but not set"
        return 1
    fi
    
    if [[ "$value" == *"\$$var_name"* ]]; then
        log_error "$description: $var_name contains unresolved variable: $value"
        return 1
    fi
    
    log_success "$description: $value"
    return 0
}

# Function to validate optional variable
validate_optional() {
    local var_name="$1"
    local description="$2"
    local value=$(safe_env_var "$var_name" "")
    
    if [ -z "$value" ]; then
        log_warning "$description: $var_name is not set (optional)"
        return 0
    fi
    
    if [[ "$value" == *"\$$var_name"* ]]; then
        log_warning "$description: $var_name contains unresolved variable: $value (optional)"
        return 0
    fi
    
    log_success "$description: $value"
    return 0
}

# Main validation function
main() {
    echo "🔍 iOS Workflow Environment Variables Validation"
    echo "================================================"
    
    local has_errors=false
    
    # Required App Store Connect API variables
    echo ""
    echo "📋 App Store Connect API Variables (Required):"
    echo "-----------------------------------------------"
    
    if ! validate_required "APP_STORE_CONNECT_KEY_IDENTIFIER" "API Key ID"; then
        has_errors=true
    fi
    
    if ! validate_required "APP_STORE_CONNECT_ISSUER_ID" "Issuer ID"; then
        has_errors=true
    fi
    
    if ! validate_url "$(safe_env_var 'APP_STORE_CONNECT_API_KEY_URL' '')" "API Key URL"; then
        has_errors=true
    fi
    
    if ! validate_required "APPLE_TEAM_ID" "Apple Team ID"; then
        has_errors=true
    fi
    
    # Required App Configuration variables
    echo ""
    echo "📱 App Configuration Variables (Required):"
    echo "-------------------------------------------"
    
    if ! validate_required "BUNDLE_ID" "Bundle ID"; then
        has_errors=true
    fi
    
    if ! validate_required "APP_NAME" "App Name"; then
        has_errors=true
    fi
    
    if ! validate_required "VERSION_NAME" "Version Name"; then
        has_errors=true
    fi
    
    if ! validate_required "VERSION_CODE" "Version Code"; then
        has_errors=true
    fi
    
    # Optional variables
    echo ""
    echo "🔧 Optional Configuration Variables:"
    echo "------------------------------------"
    
    validate_optional "FIREBASE_CONFIG_IOS" "Firebase Config iOS"
    validate_optional "CERT_P12_URL" "P12 Certificate URL"
    validate_optional "CERT_PASSWORD" "Certificate Password"
    validate_optional "PROFILE_URL" "Provisioning Profile URL"
    
    # Feature flags
    echo ""
    echo "🎛️ Feature Flags:"
    echo "-----------------"
    
    validate_optional "PUSH_NOTIFY" "Push Notifications"
    validate_optional "IS_CHATBOT" "Chatbot Feature"
    validate_optional "IS_DOMAIN_URL" "Domain URL"
    validate_optional "IS_SPLASH" "Splash Screen"
    validate_optional "IS_PULLDOWN" "Pull Down Refresh"
    validate_optional "IS_BOTTOMMENU" "Bottom Menu"
    validate_optional "IS_LOAD_IND" "Loading Indicators"
    
    # Permissions
    echo ""
    echo "🔐 Permissions:"
    echo "---------------"
    
    validate_optional "IS_CAMERA" "Camera Permission"
    validate_optional "IS_LOCATION" "Location Permission"
    validate_optional "IS_MIC" "Microphone Permission"
    validate_optional "IS_NOTIFICATION" "Notification Permission"
    validate_optional "IS_CONTACT" "Contact Permission"
    validate_optional "IS_BIOMETRIC" "Biometric Permission"
    validate_optional "IS_CALENDAR" "Calendar Permission"
    validate_optional "IS_STORAGE" "Storage Permission"
    
    # UI Configuration
    echo ""
    echo "🎨 UI Configuration:"
    echo "-------------------"
    
    validate_url "$(safe_env_var 'LOGO_URL' '')" "Logo URL"
    validate_url "$(safe_env_var 'SPLASH_URL' '')" "Splash URL"
    validate_url "$(safe_env_var 'SPLASH_BG_URL' '')" "Splash Background URL"
    validate_optional "SPLASH_BG_COLOR" "Splash Background Color"
    validate_optional "SPLASH_TAGLINE" "Splash Tagline"
    validate_optional "SPLASH_TAGLINE_COLOR" "Splash Tagline Color"
    validate_optional "SPLASH_ANIMATION" "Splash Animation"
    validate_optional "SPLASH_DURATION" "Splash Duration"
    
    # Bottom Menu Configuration
    echo ""
    echo "📱 Bottom Menu Configuration:"
    echo "-----------------------------"
    
    validate_optional "BOTTOMMENU_ITEMS" "Bottom Menu Items"
    validate_optional "BOTTOMMENU_BG_COLOR" "Bottom Menu Background Color"
    validate_optional "BOTTOMMENU_ICON_COLOR" "Bottom Menu Icon Color"
    validate_optional "BOTTOMMENU_TEXT_COLOR" "Bottom Menu Text Color"
    validate_optional "BOTTOMMENU_FONT" "Bottom Menu Font"
    validate_optional "BOTTOMMENU_FONT_SIZE" "Bottom Menu Font Size"
    validate_optional "BOTTOMMENU_FONT_BOLD" "Bottom Menu Font Bold"
    validate_optional "BOTTOMMENU_FONT_ITALIC" "Bottom Menu Font Italic"
    validate_optional "BOTTOMMENU_ACTIVE_TAB_COLOR" "Bottom Menu Active Tab Color"
    validate_optional "BOTTOMMENU_ICON_POSITION" "Bottom Menu Icon Position"
    
    # Email Configuration
    echo ""
    echo "📧 Email Configuration:"
    echo "----------------------"
    
    validate_optional "ENABLE_EMAIL_NOTIFICATIONS" "Enable Email Notifications"
    validate_optional "EMAIL_SMTP_SERVER" "SMTP Server"
    validate_optional "EMAIL_SMTP_PORT" "SMTP Port"
    validate_optional "EMAIL_SMTP_USER" "SMTP User"
    validate_optional "EMAIL_SMTP_PASS" "SMTP Password"
    
    # Summary
    echo ""
    echo "📊 Validation Summary:"
    echo "====================="
    
    if [ "$has_errors" = true ]; then
        log_error "❌ Validation failed! Please fix the errors above before running the iOS workflow."
        echo ""
        echo "💡 Common fixes:"
        echo "   - Ensure all required environment variables are set in Codemagic"
        echo "   - Check that URLs are valid and accessible"
        echo "   - Verify that variable names are correct"
        echo "   - Make sure App Store Connect API credentials are valid"
        exit 1
    else
        log_success "✅ All required environment variables are properly configured!"
        echo ""
        echo "🚀 Ready to run iOS workflow!"
        echo "   - All mandatory variables are set"
        echo "   - URLs are properly formatted"
        echo "   - App Store Connect API is configured"
        echo "   - App configuration is complete"
    fi
}

# Run main function
main "$@" 