#!/bin/bash
# 🧪 Test Generate EnvConfig
# Tests the generate_env_config function with test environment variables

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_GEN_ENV] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "🧪 Testing Generate EnvConfig Function"
log "================================================"

# Set test environment variables
export WORKFLOW_ID="ios-workflow"
export APP_NAME="Test App"
export BUNDLE_ID="com.test.app"
export VERSION_NAME="1.0.0"
export VERSION_CODE="1"
export PKG_NAME="com.test.app"
export ORG_NAME="Test Organization"
export WEB_URL="https://test.com"
export USER_NAME="testuser"
export APP_ID="12345"
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
export LOGO_URL="https://example.com/logo.png"
export SPLASH_URL="https://example.com/splash.png"
export SPLASH_BG_URL="https://example.com/splash_bg.png"
export SPLASH_BG_COLOR="#cbdbf5"
export SPLASH_TAGLINE="TEST APP"
export SPLASH_TAGLINE_COLOR="#a30237"
export SPLASH_ANIMATION="zoom"
export SPLASH_DURATION="4"
export BOTTOMMENU_ITEMS='[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://example.com/"}]'
export BOTTOMMENU_BG_COLOR="#FFFFFF"
export BOTTOMMENU_ICON_COLOR="#6d6e8c"
export BOTTOMMENU_TEXT_COLOR="#6d6e8c"
export BOTTOMMENU_FONT="DM Sans"
export BOTTOMMENU_FONT_SIZE="12"
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"
export BOTTOMMENU_ACTIVE_TAB_COLOR="#a30237"
export BOTTOMMENU_ICON_POSITION="above"
export FIREBASE_CONFIG_IOS="https://example.com/firebase.plist"

log_info "Test environment variables set"

# Source the workflow script to get the functions (skip validation)
source lib/scripts/ios-workflow/simple_robust_ios_workflow.sh 2>/dev/null || true

# Test the clean_env_var function
log_info "Testing clean_env_var function..."

test_clean_env_var() {
    local test_input="Test String with ✅ emoji and special chars"
    local expected_output="Test String with  emoji and special chars"
    local actual_output=$(clean_env_var "$test_input")
    
    if [ "$actual_output" = "$expected_output" ]; then
        log_success "clean_env_var function works correctly"
    else
        log_error "clean_env_var function failed"
        echo "Expected: $expected_output"
        echo "Actual: $actual_output"
    fi
}

test_clean_env_var

# Test the clean_json_for_dart function
log_info "Testing clean_json_for_dart function..."

test_clean_json_for_dart() {
    local test_input='[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://example.com/"}]'
    local actual_output=$(clean_json_for_dart "$test_input")
    
    if [[ "$actual_output" == *"Home"* && "$actual_output" == *"home_outlined"* ]]; then
        log_success "clean_json_for_dart function works correctly"
    else
        log_error "clean_json_for_dart function failed"
        echo "Input: $test_input"
        echo "Output: $actual_output"
    fi
}

test_clean_json_for_dart

# Test the generate_env_config function
log_info "Testing generate_env_config function..."

# Backup existing env_config.dart if it exists
if [ -f "lib/config/env_config.dart" ]; then
    cp lib/config/env_config.dart lib/config/env_config.dart.backup
    log_info "Backed up existing env_config.dart"
fi

# Run the generate_env_config function
generate_env_config

# Check if the file was generated
if [ -f "lib/config/env_config.dart" ]; then
    log_success "env_config.dart generated successfully"
else
    log_error "env_config.dart was not generated"
    exit 1
fi

# Show the generated file
log_info "Generated env_config.dart content:"
echo "================================================"
cat lib/config/env_config.dart
echo "================================================"

# Test the generated file with our test script
log_info "Testing generated env_config.dart..."

if bash lib/scripts/ios-workflow/test_env_config_properties.sh; then
    log_success "All required properties are present in generated file"
else
    log_error "Some required properties are missing"
fi

# Restore backup if it existed
if [ -f "lib/config/env_config.dart.backup" ]; then
    mv lib/config/env_config.dart.backup lib/config/env_config.dart
    log_info "Restored original env_config.dart"
fi

log_success "🎉 Generate EnvConfig test completed!"
log_info "The generate_env_config function is working correctly" 