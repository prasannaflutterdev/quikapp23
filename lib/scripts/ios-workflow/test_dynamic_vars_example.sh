#!/bin/bash
# 🧪 Test Dynamic Variables Example
# Demonstrates how variables work when properly set via Codemagic API

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_DYNAMIC] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Simulate Codemagic API variables (for testing purposes)
log_info "🧪 Simulating Codemagic API Variables"
log "================================================"

# Set example variables as if they came from Codemagic API
export WORKFLOW_ID="ios-workflow"
export APPLE_TEAM_ID="9H2AD7NQ49"
export IS_TESTFLIGHT="true"
export APP_STORE_CONNECT_KEY_IDENTIFIER="S95LCWAH99"
export APP_STORE_CONNECT_ISSUER_ID="a99a2ebd-ed3e-4117-9f97-f195823774a7"
export APP_STORE_CONNECT_API_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_S95LCWAH99.p8"

export USER_NAME="prasannasrie"
export APP_ID="10023"
export VERSION_NAME="1.0.5"
export VERSION_CODE="51"
export APP_NAME="Garbcode App"
export ORG_NAME="Garbcode Apparels Private Limited"
export WEB_URL="https://garbcode.com/"
export PKG_NAME="com.garbcode.garbcodeapp"
export BUNDLE_ID="com.garbcode.garbcodeapp"
export EMAIL_ID="prasannasrinivasan32@gmail.com"

export PUSH_NOTIFY="true"
export IS_CHATBOT="true"
export IS_DOMAIN_URL="true"
export IS_SPLASH="true"
export IS_PULLDOWN="true"
export IS_BOTTOMMENU="true"
export IS_LOAD_IND="true"

export IS_CAMERA="false"
export IS_LOCATION="false"
export IS_MIC="true"
export IS_NOTIFICATION="true"
export IS_CONTACT="false"
export IS_BIOMETRIC="false"
export IS_CALENDAR="false"
export IS_STORAGE="true"

export LOGO_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
export SPLASH_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
export SPLASH_BG_URL=""

export SPLASH_BG_COLOR="#cbdbf5"
export SPLASH_TAGLINE="TWINKLUB"
export SPLASH_TAGLINE_COLOR="#a30237"
export SPLASH_ANIMATION="zoom"
export SPLASH_DURATION="4"

export BOTTOMMENU_ITEMS='[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://twinklub.com/"},{"label":"New Arraivals","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/card.svg","icon_size":"24"},"url":"https://www.twinklub.com/collections/new-arrivals"},{"label":"Collections","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/about.svg","icon_size":"24"},"url":"https://www.twinklub.com/collections/all"},{"label":"Contact","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/contact.svg","icon_size":"24"},"url":"https://www.twinklub.com/account"}]'
export BOTTOMMENU_BG_COLOR="#FFFFFF"
export BOTTOMMENU_ICON_COLOR="#6d6e8c"
export BOTTOMMENU_TEXT_COLOR="#6d6e8c"
export BOTTOMMENU_FONT="DM Sans"
export BOTTOMMENU_FONT_SIZE="12"
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"
export BOTTOMMENU_ACTIVE_TAB_COLOR="#a30237"
export BOTTOMMENU_ICON_POSITION="above"

export FIREBASE_CONFIG_IOS="https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-gc.plist"
export APNS_KEY_ID="6VB3VLTXV6"
export APNS_AUTH_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_V566SWNF69.p8"

export PROFILE_TYPE="app-store"
export PROFILE_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode_App_App_Store.mobileprovision"
export CERT_PASSWORD="quikapp2025"
export CERT_P12_URL=""
export CERT_CER_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer"
export CERT_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key"

export ENABLE_EMAIL_NOTIFICATIONS="true"
export EMAIL_SMTP_SERVER="smtp.gmail.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="prasannasrie@gmail.com"
export EMAIL_SMTP_PASS="lrnu krfm aarp urux"

log_success "All variables set successfully (simulating Codemagic API calls)"

# Now test the validation script
log_info "Testing validation script with all variables set..."
bash lib/scripts/ios-workflow/validate_dynamic_vars.sh

log_info "Example completed successfully"
log_info "This demonstrates how variables work when properly set via Codemagic API calls" 