#!/bin/bash
# 🔧 iOS Workflow Fix Script
# Fixes common issues with the iOS workflow and improves reliability

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIX] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Create necessary directories
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p ios/certificates
mkdir -p output/ios
mkdir -p build/ios/logs

# Function to create default assets if missing
create_default_assets() {
    log_info "Creating default assets..."
    
    # Create default logo if missing
    if [ ! -f "assets/images/default_logo.png" ]; then
        log_info "Creating default logo..."
        if command -v convert >/dev/null 2>&1; then
            # Create a simple colored square as default logo
            convert -size 512x512 xc:"#007AFF" -fill white -draw "text 256,256 'Q'" assets/images/default_logo.png
            log_success "Default logo created"
        else
            log_warning "ImageMagick not available, cannot create default logo"
        fi
    fi
    
    # Create default splash if missing
    if [ ! -f "assets/images/splash.png" ]; then
        log_info "Creating default splash..."
        if command -v convert >/dev/null 2>&1; then
            # Create a simple splash screen
            convert -size 1125x2436 xc:"#FFFFFF" -fill "#007AFF" -draw "text 562,1218 'QuikApp'" assets/images/splash.png
            log_success "Default splash created"
        else
            log_warning "ImageMagick not available, cannot create default splash"
        fi
    fi
}

# Function to improve download reliability
improve_download_reliability() {
    log_info "Improving download reliability..."
    
    # Create an improved download function
    cat > lib/scripts/ios-workflow/improved_download.sh <<'EOF'
#!/bin/bash
# Improved download function with better error handling

improved_download() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    if [ -z "$url" ]; then
        echo "No URL provided for $description, skipping"
        return 0
    fi
    
    echo "Downloading $description from: $url"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"
    
    # Try multiple download methods with exponential backoff
    local max_retries=5
    local retry_count=0
    local base_delay=2
    
    while [ $retry_count -lt $max_retries ]; do
        local delay=$((base_delay * (2 ** retry_count)))
        
        # Method 1: Standard curl with longer timeout
        if curl -L -f -s --connect-timeout 60 --max-time 300 -o "$output_path" "$url" 2>/dev/null; then
            echo "✅ $description downloaded successfully"
            return 0
        fi
        
        # Method 2: Curl with custom user agent
        if curl -L -f -s --connect-timeout 60 --max-time 300 -o "$output_path" \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -H "Accept: */*" \
            -H "Accept-Language: en-US,en;q=0.9" \
            "$url" 2>/dev/null; then
            echo "✅ $description downloaded successfully (with custom headers)"
            return 0
        fi
        
        # Method 3: Try without redirect
        if curl -f -s --connect-timeout 60 --max-time 300 -o "$output_path" "$url" 2>/dev/null; then
            echo "✅ $description downloaded successfully (without redirect)"
            return 0
        fi
        
        # Method 4: Wget if available
        if command -v wget >/dev/null 2>&1; then
            if wget --timeout=60 --tries=3 --user-agent="Mozilla/5.0" -O "$output_path" "$url" 2>/dev/null; then
                echo "✅ $description downloaded successfully (with wget)"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        echo "⚠️ Download attempt $retry_count failed for $description"
        
        if [ $retry_count -lt $max_retries ]; then
            echo "Retrying in $delay seconds..."
            sleep $delay
        fi
    done
    
    echo "❌ Failed to download $description after $max_retries attempts"
    return 1
}
EOF
    
    chmod +x lib/scripts/ios-workflow/improved_download.sh
    log_success "Improved download function created"
}

# Function to fix environment variable handling
fix_env_handling() {
    log_info "Fixing environment variable handling..."
    
    # Create a robust environment variable loader
    cat > lib/scripts/ios-workflow/env_loader.sh <<'EOF'
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
EOF
    
    chmod +x lib/scripts/ios-workflow/env_loader.sh
    log_success "Environment variable loader created"
}

# Function to create fallback workflow
create_fallback_workflow() {
    log_info "Creating fallback workflow..."
    
    cat > lib/scripts/ios-workflow/fallback_workflow.sh <<'EOF'
#!/bin/bash
# Fallback iOS workflow that works even with network issues

set -euo pipefail

# Source environment loader
source "$(dirname "$0")/env_loader.sh"

# Load environment variables
set_defaults

# Create default assets
create_default_assets() {
    echo "Creating default assets for build..."
    
    # Ensure default assets exist
    if [ ! -f "assets/images/default_logo.png" ]; then
        echo "Creating default logo..."
        if command -v convert >/dev/null 2>&1; then
            convert -size 512x512 xc:"#007AFF" -fill white -draw "text 256,256 'Q'" assets/images/default_logo.png
        fi
    fi
    
    if [ ! -f "assets/images/splash.png" ]; then
        echo "Creating default splash..."
        if command -v convert >/dev/null 2>&1; then
            convert -size 1125x2436 xc:"#FFFFFF" -fill "#007AFF" -draw "text 562,1218 'QuikApp'" assets/images/splash.png
        fi
    fi
}

# Generate env_config.dart
generate_env_config() {
    echo "Generating env_config.dart..."
    
    cat > lib/config/env_config.dart <<ENVEOF
// Generated by Fallback iOS Workflow
// Do not edit manually

class EnvConfig {
  // App Information
  static const String appName = '$APP_NAME';
  static const String versionName = '$VERSION_NAME';
  static const String versionCode = '$VERSION_CODE';
  static const String bundleId = '$BUNDLE_ID';
  
  // Feature Flags
  static const bool isPushNotify = $PUSH_NOTIFY;
  static const bool isCamera = $IS_CAMERA;
  static const bool isLocation = $IS_LOCATION;
  static const bool isMic = $IS_MIC;
  static const bool isNotification = $IS_NOTIFICATION;
  static const bool isContact = $IS_CONTACT;
  static const bool isBiometric = $IS_BIOMETRIC;
  static const bool isCalendar = $IS_CALENDAR;
  static const bool isStorage = $IS_STORAGE;
  
  // UI Configuration
  static const String splashBgColor = '$SPLASH_BG_COLOR';
}
ENVEOF
    
    echo "✅ env_config.dart generated"
}

# Build without external dependencies
build_without_externals() {
    echo "Building without external dependencies..."
    
    # Clean and get dependencies
    flutter clean
    flutter pub get
    
    # Build without code signing
    if flutter build ios --release --no-codesign; then
        echo "✅ Flutter build completed"
    else
        echo "❌ Flutter build failed"
        return 1
    fi
    
    # Try to create archive with automatic signing
    cd ios
    pod install || echo "⚠️ CocoaPods install failed, continuing anyway"
    cd ..
    
    if xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -sdk iphoneos \
        -configuration Release archive \
        -archivePath build/Runner.xcarchive \
        DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        CODE_SIGN_STYLE="Automatic"; then
        echo "✅ Xcode archive completed"
    else
        echo "❌ Xcode archive failed"
        return 1
    fi
}

# Main fallback workflow
main() {
    echo "🚀 Starting Fallback iOS Workflow"
    
    # Create default assets
    create_default_assets
    
    # Generate environment config
    generate_env_config
    
    # Build without external dependencies
    if build_without_externals; then
        echo "🎉 Fallback workflow completed successfully!"
        echo "📦 Archive available at: build/Runner.xcarchive"
    else
        echo "❌ Fallback workflow failed"
        exit 1
    fi
}

# Execute main function
main "$@"
EOF
    
    chmod +x lib/scripts/ios-workflow/fallback_workflow.sh
    log_success "Fallback workflow created"
}

# Function to update the main workflow script
update_main_workflow() {
    log_info "Updating main workflow script..."
    
    # Add fallback logic to the main workflow
    cat > lib/scripts/ios-workflow/robust_workflow.sh <<'EOF'
#!/bin/bash
# Robust iOS workflow with fallback options

set -euo pipefail

# Source environment loader
source "$(dirname "$0")/env_loader.sh"

# Load environment variables
set_defaults

# Main workflow with fallback
main() {
    echo "🚀 Starting Robust iOS Workflow"
    
    # Try the main workflow first
    if bash "$(dirname "$0")/new_ios_workflow.sh"; then
        echo "✅ Main workflow completed successfully"
        return 0
    else
        echo "⚠️ Main workflow failed, trying fallback..."
        
        # Try fallback workflow
        if bash "$(dirname "$0")/fallback_workflow.sh"; then
            echo "✅ Fallback workflow completed successfully"
            return 0
        else
            echo "❌ Both main and fallback workflows failed"
            return 1
        fi
    fi
}

# Execute main function
main "$@"
EOF
    
    chmod +x lib/scripts/ios-workflow/robust_workflow.sh
    log_success "Robust workflow created"
}

# Main fix execution
main() {
    log_info "🔧 Starting iOS Workflow Fix Script"
    log "================================================"
    
    # Create default assets
    create_default_assets
    
    # Improve download reliability
    improve_download_reliability
    
    # Fix environment variable handling
    fix_env_handling
    
    # Create fallback workflow
    create_fallback_workflow
    
    # Update main workflow
    update_main_workflow
    
    log_success "🎉 iOS Workflow Fix Completed!"
    log "📋 Summary of fixes:"
    log "   ✅ Created default assets"
    log "   ✅ Improved download reliability"
    log "   ✅ Fixed environment variable handling"
    log "   ✅ Created fallback workflow"
    log "   ✅ Created robust workflow"
    log ""
    log "🚀 To use the fixed workflow:"
    log "   bash lib/scripts/ios-workflow/robust_workflow.sh"
    log ""
    log "🧪 To test downloads:"
    log "   bash lib/scripts/ios-workflow/test_downloads.sh"
}

# Execute main function
main "$@" 