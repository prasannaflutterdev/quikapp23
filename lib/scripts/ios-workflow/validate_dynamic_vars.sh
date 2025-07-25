#!/bin/bash
# 🧪 Validate Dynamic Variables Script
# Checks all variables are properly sourced from Codemagic API calls

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE_VARS] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# All required dynamic variables from user's list
declare -a ALL_VARIABLES=(
    "WORKFLOW_ID"
    "APPLE_TEAM_ID"
    "IS_TESTFLIGHT"
    "APP_STORE_CONNECT_KEY_IDENTIFIER"
    "APP_STORE_CONNECT_ISSUER_ID"
    "APP_STORE_CONNECT_API_KEY_URL"
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
    "PUSH_NOTIFY"
    "IS_CHATBOT"
    "IS_DOMAIN_URL"
    "IS_SPLASH"
    "IS_PULLDOWN"
    "IS_BOTTOMMENU"
    "IS_LOAD_IND"
    "IS_CAMERA"
    "IS_LOCATION"
    "IS_MIC"
    "IS_NOTIFICATION"
    "IS_CONTACT"
    "IS_BIOMETRIC"
    "IS_CALENDAR"
    "IS_STORAGE"
    "LOGO_URL"
    "SPLASH_URL"
    "SPLASH_BG_URL"
    "SPLASH_BG_COLOR"
    "SPLASH_TAGLINE"
    "SPLASH_TAGLINE_COLOR"
    "SPLASH_ANIMATION"
    "SPLASH_DURATION"
    "BOTTOMMENU_ITEMS"
    "BOTTOMMENU_BG_COLOR"
    "BOTTOMMENU_ICON_COLOR"
    "BOTTOMMENU_TEXT_COLOR"
    "BOTTOMMENU_FONT"
    "BOTTOMMENU_FONT_SIZE"
    "BOTTOMMENU_FONT_BOLD"
    "BOTTOMMENU_FONT_ITALIC"
    "BOTTOMMENU_ACTIVE_TAB_COLOR"
    "BOTTOMMENU_ICON_POSITION"
    "FIREBASE_CONFIG_IOS"
    "APNS_KEY_ID"
    "APNS_AUTH_KEY_URL"
    "PROFILE_TYPE"
    "PROFILE_URL"
    "CERT_CER_URL"
    "CERT_KEY_URL"
    "ENABLE_EMAIL_NOTIFICATIONS"
    "EMAIL_SMTP_SERVER"
    "EMAIL_SMTP_PORT"
    "EMAIL_SMTP_USER"
    "EMAIL_SMTP_PASS"
)

# Critical variables that must be set
declare -a CRITICAL_VARIABLES=(
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

# Function to check if variable is set
check_variable() {
    local var_name="$1"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        log_success "$var_name: $value"
        return 0
    else
        log_warning "$var_name: NOT SET"
        return 1
    fi
}

# Function to validate critical variables
validate_critical_vars() {
    local missing_critical=()
    
    for var in "${CRITICAL_VARIABLES[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_critical+=("$var")
        fi
    done
    
    if [ ${#missing_critical[@]} -gt 0 ]; then
        log_error "Critical variables missing: ${missing_critical[*]}"
        return 1
    fi
    
    return 0
}

# Main validation function
main() {
    log_info "🧪 Validating Dynamic Variables from Codemagic API"
    log "================================================"
    
    local total_vars=${#ALL_VARIABLES[@]}
    local set_vars=0
    local missing_vars=()
    
    log_info "Checking all $total_vars dynamic variables..."
    
    # Check each variable
    for var in "${ALL_VARIABLES[@]}"; do
        if check_variable "$var"; then
            ((set_vars++))
        else
            missing_vars+=("$var")
        fi
    done
    
    # Summary
    log_info "Validation Summary"
    log "================================================"
    log_info "Total variables: $total_vars"
    log_success "Set variables: $set_vars"
    log_warning "Missing variables: $(($total_vars - $set_vars))"
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_warning "Missing variables:"
        for var in "${missing_vars[@]}"; do
            log_warning "  - $var"
        done
    fi
    
    # Validate critical variables
    log_info "Validating critical variables..."
    if validate_critical_vars; then
        log_success "All critical variables are set"
    else
        log_error "Critical variables are missing"
        log_error "These variables must be set via Codemagic API calls"
        exit 1
    fi
    
    # Check if variables are properly sourced
    log_info "Checking variable sourcing..."
    
    # Test if variables are coming from environment (not hardcoded)
    if [ -n "${WORKFLOW_ID:-}" ] && [ "$WORKFLOW_ID" != "ios-workflow" ]; then
        log_success "WORKFLOW_ID appears to be dynamically sourced"
    else
        log_warning "WORKFLOW_ID may be using fallback value"
    fi
    
    if [ -n "${APPLE_TEAM_ID:-}" ] && [ "$APPLE_TEAM_ID" != "9H2AD7NQ49" ]; then
        log_success "APPLE_TEAM_ID appears to be dynamically sourced"
    else
        log_warning "APPLE_TEAM_ID may be using fallback value"
    fi
    
    if [ -n "${BUNDLE_ID:-}" ] && [ "$BUNDLE_ID" != "com.garbcode.garbcodeapp" ]; then
        log_success "BUNDLE_ID appears to be dynamically sourced"
    else
        log_warning "BUNDLE_ID may be using fallback value"
    fi
    
    # Final status
    if [ $set_vars -eq $total_vars ]; then
        log_success "🎉 All dynamic variables are properly set!"
        log_info "All variables appear to be sourced from Codemagic API calls"
    elif [ $set_vars -gt $(($total_vars / 2)) ]; then
        log_warning "⚠️ Most variables are set, but some are missing"
        log_info "Consider setting the missing variables via Codemagic API calls"
    else
        log_error "❌ Many variables are missing"
        log_error "Please ensure all variables are set via Codemagic API calls"
        exit 1
    fi
    
    log_info "Dynamic variable validation completed"
}

# Execute main function
main "$@" 