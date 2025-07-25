#!/bin/bash
# Robust environment variable loader

# Function to safely get environment variable with fallback
get_env_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        echo "✅ Found $var_name: $value"
        printf "%s" "$value"
    else
        echo "⚠️ $var_name not set, using fallback: $fallback"
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
        echo "❌ Missing required variables: ${missing_vars[*]}"
        return 1
    fi
    
    echo "✅ All required variables are set"
    return 0
}

# Function to set default values for optional variables
set_defaults() {
    # App configuration
    export WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "ios-workflow")
    export APP_NAME=$(get_env_var "APP_NAME" "QuikApp")
    export VERSION_NAME=$(get_env_var "VERSION_NAME" "1.0.0")
    export VERSION_CODE=$(get_env_var "VERSION_CODE" "1")
    export BUNDLE_ID=$(get_env_var "BUNDLE_ID" "com.example.quikapp")
    export APPLE_TEAM_ID=$(get_env_var "APPLE_TEAM_ID" "")
    
    # Feature flags
    export PUSH_NOTIFY=$(get_env_var "PUSH_NOTIFY" "false")
    export IS_CAMERA=$(get_env_var "IS_CAMERA" "false")
    export IS_LOCATION=$(get_env_var "IS_LOCATION" "false")
    export IS_MIC=$(get_env_var "IS_MIC" "false")
    export IS_NOTIFICATION=$(get_env_var "IS_NOTIFICATION" "false")
    export IS_CONTACT=$(get_env_var "IS_CONTACT" "false")
    export IS_BIOMETRIC=$(get_env_var "IS_BIOMETRIC" "false")
    export IS_CALENDAR=$(get_env_var "IS_CALENDAR" "false")
    export IS_STORAGE=$(get_env_var "IS_STORAGE" "false")
    
    # Asset URLs
    export LOGO_URL=$(get_env_var "LOGO_URL" "")
    export SPLASH_URL=$(get_env_var "SPLASH_URL" "")
    export SPLASH_BG_URL=$(get_env_var "SPLASH_BG_URL" "")
    export SPLASH_BG_COLOR=$(get_env_var "SPLASH_BG_COLOR" "#FFFFFF")
    
    # Certificate URLs
    export PROFILE_URL=$(get_env_var "PROFILE_URL" "")
    export CERT_P12_URL=$(get_env_var "CERT_P12_URL" "")
    export CERT_PASSWORD=$(get_env_var "CERT_PASSWORD" "")
    export FIREBASE_CONFIG_IOS=$(get_env_var "FIREBASE_CONFIG_IOS" "")
    
    echo "✅ Environment variables loaded with defaults"
}
