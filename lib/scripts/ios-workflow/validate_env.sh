#!/bin/bash
# 🔍 iOS Environment Validation Script
# Validates environment variables and URLs before iOS build
# Usage: ./lib/scripts/ios-workflow/validate_env.sh

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Function to safely get environment variable
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

# Function to test URL accessibility
test_url() {
    local url="$1"
    local description="$2"
    
    if [ -z "$url" ]; then
        log_warning "No URL provided for $description"
        return 0
    fi
    
    log_info "Testing URL for $description: $url"
    
    # Test URL with curl
    if curl -I -s -f "$url" >/dev/null 2>&1; then
        log_success "✅ URL accessible: $description"
        return 0
    else
        log_error "❌ URL not accessible: $description ($url)"
        return 1
    fi
}

log_info "Starting iOS Environment Validation"
log "================================================"

# Step 1: Validate Critical Environment Variables
log_info "Step 1: Validating Critical Environment Variables"
log "================================================"

# Set and validate critical variables
export BUNDLE_ID=$(get_env_var "BUNDLE_ID" "com.example.quikapp")
export APPLE_TEAM_ID=$(get_env_var "APPLE_TEAM_ID" "")
export WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "ios-workflow")
export APP_NAME=$(get_env_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_env_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_env_var "VERSION_CODE" "1")

# Validate required variables
MISSING_VARS=()

if [ -z "$BUNDLE_ID" ]; then
    MISSING_VARS+=("BUNDLE_ID")
fi

if [ -z "$APPLE_TEAM_ID" ]; then
    MISSING_VARS+=("APPLE_TEAM_ID")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_error "Missing required environment variables: ${MISSING_VARS[*]}"
    log_error "Please set these variables in your Codemagic environment"
    exit 1
fi

log_success "Critical environment variables validated"

# Step 2: Validate Optional Environment Variables
log_info "Step 2: Validating Optional Environment Variables"
log "================================================"

export PROFILE_URL=$(get_env_var "PROFILE_URL" "")
export IS_TESTFLIGHT=$(get_env_var "IS_TESTFLIGHT" "false")
export APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
export APP_STORE_CONNECT_ISSUER_ID=$(get_env_var "APP_STORE_CONNECT_ISSUER_ID" "")
export APP_STORE_CONNECT_API_KEY_URL=$(get_env_var "APP_STORE_CONNECT_API_KEY_URL" "")
export LOGO_URL=$(get_env_var "LOGO_URL" "")
export SPLASH_URL=$(get_env_var "SPLASH_URL" "")

log_success "Optional environment variables validated"

# Step 3: Test URL Accessibility
log_info "Step 3: Testing URL Accessibility"
log "================================================"

URL_TESTS=0
URL_FAILURES=0

# Test provisioning profile URL
if [ -n "$PROFILE_URL" ]; then
    URL_TESTS=$((URL_TESTS + 1))
    if test_url "$PROFILE_URL" "provisioning profile"; then
        log_success "Provisioning profile URL is accessible"
    else
        URL_FAILURES=$((URL_FAILURES + 1))
        log_warning "Provisioning profile URL failed - build may continue without it"
    fi
else
    log_info "No provisioning profile URL provided - skipping"
fi

# Test App Store Connect API key URL
if [ -n "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    URL_TESTS=$((URL_TESTS + 1))
    if test_url "$APP_STORE_CONNECT_API_KEY_URL" "App Store Connect API key"; then
        log_success "App Store Connect API key URL is accessible"
    else
        URL_FAILURES=$((URL_FAILURES + 1))
        log_warning "App Store Connect API key URL failed - TestFlight upload may fail"
    fi
else
    log_info "No App Store Connect API key URL provided - skipping"
fi

# Test logo URL
if [ -n "$LOGO_URL" ]; then
    URL_TESTS=$((URL_TESTS + 1))
    if test_url "$LOGO_URL" "app logo"; then
        log_success "Logo URL is accessible"
    else
        URL_FAILURES=$((URL_FAILURES + 1))
        log_warning "Logo URL failed - using default logo"
    fi
else
    log_info "No logo URL provided - skipping"
fi

# Test splash URL
if [ -n "$SPLASH_URL" ]; then
    URL_TESTS=$((URL_TESTS + 1))
    if test_url "$SPLASH_URL" "splash image"; then
        log_success "Splash URL is accessible"
    else
        URL_FAILURES=$((URL_FAILURES + 1))
        log_warning "Splash URL failed - using default splash"
    fi
else
    log_info "No splash URL provided - skipping"
fi

# Step 4: Validate TestFlight Configuration
log_info "Step 4: Validating TestFlight Configuration"
log "================================================"

if [ "$IS_TESTFLIGHT" = "true" ]; then
    log_info "TestFlight upload is enabled"
    
    if [ -z "$APP_STORE_CONNECT_KEY_IDENTIFIER" ] || [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
        log_error "TestFlight upload enabled but missing required App Store Connect credentials"
        log_error "Required variables: APP_STORE_CONNECT_KEY_IDENTIFIER, APP_STORE_CONNECT_ISSUER_ID"
        exit 1
    fi
    
    if [ -z "$APP_STORE_CONNECT_API_KEY_URL" ]; then
        log_warning "TestFlight upload enabled but APP_STORE_CONNECT_API_KEY_URL is not set"
        log_warning "TestFlight upload may fail"
    fi
    
    log_success "TestFlight configuration validated"
else
    log_info "TestFlight upload is disabled (IS_TESTFLIGHT=false)"
fi

# Step 5: Validate Project Structure
log_info "Step 5: Validating Project Structure"
log "================================================"

REQUIRED_FILES=(
    "ios/Runner.xcworkspace"
    "ios/Podfile"
    "lib/scripts/utils/gen_env_config.sh"
    "pubspec.yaml"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        log_success "✅ Found: $file"
    else
        log_error "❌ Missing: $file"
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    log_error "Missing required project files: ${MISSING_FILES[*]}"
    log_warning "Some files may be missing but the build can continue"
fi

log_success "Project structure validated"

# Step 6: Final Summary
log_info "Step 6: Final Validation Summary"
log "================================================"

log_success "🎉 Environment Validation Completed!"
log "📱 App: $APP_NAME v$VERSION_NAME ($VERSION_CODE)"
log "🆔 Bundle ID: $BUNDLE_ID"
log "👥 Team ID: $APPLE_TEAM_ID"
log "🚀 TestFlight: $IS_TESTFLIGHT"
log "🔗 URLs Tested: $URL_TESTS"
log "❌ URL Failures: $URL_FAILURES"

if [ $URL_FAILURES -gt 0 ]; then
    log_warning "⚠️ Some URLs failed validation - build may continue with defaults"
fi

if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    log_success "✅ All critical validations passed - ready for iOS build!"
    exit 0
else
    log_error "❌ Validation failed - please fix the issues above"
    exit 1
fi 