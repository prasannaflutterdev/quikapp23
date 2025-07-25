#!/bin/bash
# 🍎 Enhanced iOS Workflow with Certificate Generation
# Integrates robust downloads with certificate generation and validation

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENHANCED_IOS] $1"; }
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

# Robust download function with wget as primary method
robust_download() {
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
    
    # Method 1: Wget (Primary method)
    if command -v wget >/dev/null 2>&1; then
        log_info "Trying wget download..."
        if wget --timeout=60 --tries=3 --retry-connrefused --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with wget"
            return 0
        else
            log_warning "wget download failed, trying curl..."
        fi
    else
        log_warning "wget not available, trying curl..."
    fi
    
    # Method 2: Curl with different options
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl download..."
        if curl -L -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl"
            return 0
        else
            log_warning "curl download failed, trying without redirect..."
        fi
        
        # Method 3: Curl without redirect
        if curl -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl (no redirect)"
            return 0
        else
            log_warning "curl without redirect failed..."
        fi
    else
        log_warning "curl not available..."
    fi
    
    log_error "Failed to download $description with all methods"
    return 1
}

# Function to detect certificate format
detect_certificate_format() {
    local file_path="$1"
    
    # Check if file starts with "-----BEGIN CERTIFICATE-----" (PEM format)
    if head -1 "$file_path" 2>/dev/null | grep -q "-----BEGIN CERTIFICATE-----"; then
        echo "PEM"
        return 0
    fi
    
    # Check if file is binary (DER format)
    if file "$file_path" 2>/dev/null | grep -q "data\|DER"; then
        echo "DER"
        return 0
    fi
    
    # Try to read as DER
    if openssl x509 -inform DER -in "$file_path" -noout >/dev/null 2>&1; then
        echo "DER"
        return 0
    fi
    
    # Try to read as PEM
    if openssl x509 -inform PEM -in "$file_path" -noout >/dev/null 2>&1; then
        echo "PEM"
        return 0
    fi
    
    echo "UNKNOWN"
    return 1
}

# Function to validate certificate file
validate_certificate_file() {
    local file_path="$1"
    local file_type="$2"
    
    if [ ! -f "$file_path" ]; then
        log_error "$file_type file not found: $file_path"
        return 1
    fi
    
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")
    log_info "$file_type file size: $file_size bytes"
    
    if [ "$file_size" -eq 0 ]; then
        log_error "$file_type file is empty"
        return 1
    fi
    
    # Validate CER file
    if [ "$file_type" = "Certificate" ]; then
        # Detect certificate format
        local format=$(detect_certificate_format "$file_path")
        log_info "Detected certificate format: $format"
        
        if [ "$format" = "DER" ]; then
            # Validate DER certificate
            if openssl x509 -inform DER -in "$file_path" -text -noout >/dev/null 2>&1; then
                log_success "DER certificate file is valid"
                
                # Extract certificate information
                local subject=$(openssl x509 -inform DER -in "$file_path" -noout -subject 2>/dev/null | sed 's/subject=//')
                local issuer=$(openssl x509 -inform DER -in "$file_path" -noout -issuer 2>/dev/null | sed 's/issuer=//')
                local not_after=$(openssl x509 -inform DER -in "$file_path" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
                
                log_info "Certificate Subject: $subject"
                log_info "Certificate Issuer: $issuer"
                log_info "Certificate Expires: $not_after"
                
                return 0
            else
                log_error "DER certificate file is invalid or corrupted"
                return 1
            fi
        elif [ "$format" = "PEM" ]; then
            # Validate PEM certificate
            if openssl x509 -inform PEM -in "$file_path" -text -noout >/dev/null 2>&1; then
                log_success "PEM certificate file is valid"
                
                # Extract certificate information
                local subject=$(openssl x509 -inform PEM -in "$file_path" -noout -subject 2>/dev/null | sed 's/subject=//')
                local issuer=$(openssl x509 -inform PEM -in "$file_path" -noout -issuer 2>/dev/null | sed 's/issuer=//')
                local not_after=$(openssl x509 -inform PEM -in "$file_path" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
                
                log_info "Certificate Subject: $subject"
                log_info "Certificate Issuer: $issuer"
                log_info "Certificate Expires: $not_after"
                
                return 0
            else
                log_error "PEM certificate file is invalid or corrupted"
                return 1
            fi
        else
            log_error "Unknown certificate format"
            return 1
        fi
    fi
    
    # Validate KEY file
    if [ "$file_type" = "Private Key" ]; then
        if openssl rsa -in "$file_path" -check -noout >/dev/null 2>&1; then
            log_success "Private key file is valid"
            
            # Extract key information
            local key_size=$(openssl rsa -in "$file_path" -noout -text 2>/dev/null | grep "Private-Key:" | awk '{print $2}')
            log_info "Private Key Size: $key_size bits"
            
            return 0
        else
            log_error "Private key file is invalid or corrupted"
            return 1
        fi
    fi
    
    return 0
}

# Function to generate p12 file with proper format handling
generate_p12_from_certificates() {
    local cer_file="$1"
    local key_file="$2"
    local p12_file="$3"
    local password="$4"
    
    log_info "Generating P12 file..."
    log_info "Certificate file: $cer_file"
    log_info "Private key file: $key_file"
    log_info "Output P12 file: $p12_file"
    log_info "Password: $password"
    
    # Detect certificate format
    local cert_format=$(detect_certificate_format "$cer_file")
    log_info "Certificate format: $cert_format"
    
    # Convert DER to PEM if needed
    local pem_cert_file="$cer_file"
    if [ "$cert_format" = "DER" ]; then
        log_info "Converting DER certificate to PEM format..."
        pem_cert_file="/tmp/certificate.pem"
        if openssl x509 -inform DER -in "$cer_file" -out "$pem_cert_file" 2>/dev/null; then
            log_success "Certificate converted to PEM format"
        else
            log_error "Failed to convert certificate to PEM format"
            return 1
        fi
    fi
    
    # Generate p12 file using PEM certificate
    log_info "Generating P12 file from PEM certificate..."
    if openssl pkcs12 -export \
        -in "$pem_cert_file" \
        -inkey "$key_file" \
        -out "$p12_file" \
        -passout pass:"$password" \
        -name "iOS Distribution Certificate" \
        -caname "Apple Worldwide Developer Relations Certification Authority" \
        2>/dev/null; then
        
        log_success "P12 file generated successfully"
        return 0
    else
        log_error "Failed to generate P12 file"
        return 1
    fi
}

# Function to validate p12 file
validate_p12_file() {
    local p12_file="$1"
    local password="$2"
    
    if [ ! -f "$p12_file" ]; then
        log_error "P12 file not found: $p12_file"
        return 1
    fi
    
    local file_size=$(stat -f%z "$p12_file" 2>/dev/null || stat -c%s "$p12_file" 2>/dev/null || echo "0")
    log_info "P12 file size: $file_size bytes"
    
    if [ "$file_size" -eq 0 ]; then
        log_error "P12 file is empty"
        return 1
    fi
    
    # Validate p12 file structure
    if openssl pkcs12 -in "$p12_file" -passin pass:"$password" -info -noout >/dev/null 2>&1; then
        log_success "P12 file is valid and password is correct"
        
        # Extract p12 information
        local cert_count=$(openssl pkcs12 -in "$p12_file" -passin pass:"$password" -info -noout 2>&1 | grep -c "Certificate:" || echo "0")
        local key_count=$(openssl pkcs12 -in "$p12_file" -passin pass:"$password" -info -noout 2>&1 | grep -c "Private Key:" || echo "0")
        
        log_info "P12 contains $cert_count certificate(s) and $key_count private key(s)"
        
        return 0
    else
        log_error "P12 file is invalid or password is incorrect"
        return 1
    fi
}

# Function to test network connectivity
test_network_connectivity() {
    log_info "Testing network connectivity..."
    
    # Test DNS resolution
    if nslookup raw.githubusercontent.com >/dev/null 2>&1; then
        log_success "DNS resolution for raw.githubusercontent.com successful"
    else
        log_error "DNS resolution for raw.githubusercontent.com failed"
        return 1
    fi
    
    # Test HTTPS connectivity
    if curl -I -s --connect-timeout 10 https://raw.githubusercontent.com >/dev/null 2>&1; then
        log_success "HTTPS connectivity to raw.githubusercontent.com successful"
    else
        log_error "HTTPS connectivity to raw.githubusercontent.com failed"
        return 1
    fi
    
    return 0
}

# Set all required variables with defaults
WORKFLOW_ID=$(get_env_var "WORKFLOW_ID" "ios-workflow")
USER_NAME=$(get_env_var "USER_NAME" "prasannasrie")
APP_ID=$(get_env_var "APP_ID" "10023")
VERSION_NAME=$(get_env_var "VERSION_NAME" "1.0.5")
VERSION_CODE=$(get_env_var "VERSION_CODE" "51")
APP_NAME=$(get_env_var "APP_NAME" "Garbcode App")
ORG_NAME=$(get_env_var "ORG_NAME" "Garbcode Apparels Private Limited")
WEB_URL=$(get_env_var "WEB_URL" "https://garbcode.com/")
PKG_NAME=$(get_env_var "PKG_NAME" "com.garbcode.garbcodeapp")
BUNDLE_ID=$(get_env_var "BUNDLE_ID" "com.garbcode.garbcodeapp")
EMAIL_ID=$(get_env_var "EMAIL_ID" "prasannasrinivasan32@gmail.com")
PUSH_NOTIFY=$(get_env_var "PUSH_NOTIFY" "true")
IS_CHATBOT=$(get_env_var "IS_CHATBOT" "true")
IS_DOMAIN_URL=$(get_env_var "IS_DOMAIN_URL" "true")
IS_SPLASH=$(get_env_var "IS_SPLASH" "true")
IS_PULLDOWN=$(get_env_var "IS_PULLDOWN" "true")
IS_BOTTOMMENU=$(get_env_var "IS_BOTTOMMENU" "true")
IS_LOAD_IND=$(get_env_var "IS_LOAD_IND" "true")
IS_CAMERA=$(get_env_var "IS_CAMERA" "false")
IS_LOCATION=$(get_env_var "IS_LOCATION" "false")
IS_MIC=$(get_env_var "IS_MIC" "true")
IS_NOTIFICATION=$(get_env_var "IS_NOTIFICATION" "true")
IS_CONTACT=$(get_env_var "IS_CONTACT" "false")
IS_BIOMETRIC=$(get_env_var "IS_BIOMETRIC" "false")
IS_CALENDAR=$(get_env_var "IS_CALENDAR" "false")
IS_STORAGE=$(get_env_var "IS_STORAGE" "true")
LOGO_URL=$(get_env_var "LOGO_URL" "")
SPLASH_URL=$(get_env_var "SPLASH_URL" "")
SPLASH_BG_URL=$(get_env_var "SPLASH_BG_URL" "")
SPLASH_BG_COLOR=$(get_env_var "SPLASH_BG_COLOR" "#cbdbf5")
SPLASH_TAGLINE=$(get_env_var "SPLASH_TAGLINE" "TWINKLUB")
SPLASH_TAGLINE_COLOR=$(get_env_var "SPLASH_TAGLINE_COLOR" "#a30237")
SPLASH_ANIMATION=$(get_env_var "SPLASH_ANIMATION" "zoom")
SPLASH_DURATION=$(get_env_var "SPLASH_DURATION" "4")
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
FIREBASE_CONFIG_IOS=$(get_env_var "FIREBASE_CONFIG_IOS" "")
APNS_KEY_ID=$(get_env_var "APNS_KEY_ID" "")
APNS_AUTH_KEY_URL=$(get_env_var "APNS_AUTH_KEY_URL" "")
PROFILE_TYPE=$(get_env_var "PROFILE_TYPE" "app-store")
PROFILE_URL=$(get_env_var "PROFILE_URL" "")
CERT_PASSWORD=$(get_env_var "CERT_PASSWORD" "quikapp2025")
CERT_P12_URL=$(get_env_var "CERT_P12_URL" "")
CERT_CER_URL=$(get_env_var "CERT_CER_URL" "")
CERT_KEY_URL=$(get_env_var "CERT_KEY_URL" "")
ENABLE_EMAIL_NOTIFICATIONS=$(get_env_var "ENABLE_EMAIL_NOTIFICATIONS" "true")
EMAIL_SMTP_SERVER=$(get_env_var "EMAIL_SMTP_SERVER" "smtp.gmail.com")
EMAIL_SMTP_PORT=$(get_env_var "EMAIL_SMTP_PORT" "587")
EMAIL_SMTP_USER=$(get_env_var "EMAIL_SMTP_USER" "prasannasrie@gmail.com")
EMAIL_SMTP_PASS=$(get_env_var "EMAIL_SMTP_PASS" "lrnu krfm aarp urux")

# Validate critical variables
if [ -z "$BUNDLE_ID" ]; then
    log_error "BUNDLE_ID is required but not set"
    exit 1
fi

if [ -z "$APPLE_TEAM_ID" ]; then
    log_error "APPLE_TEAM_ID is required but not set"
    exit 1
fi

# Step 1: Test Network Connectivity
log_info "Step 1: Test Network Connectivity"
log "================================================"

if ! test_network_connectivity; then
    log_error "Network connectivity test failed"
    exit 1
fi

log_success "Network connectivity test passed"

# Step 2: Download Assets for Dart Codes
log_info "Step 2: Download Assets for Dart Codes"
log "================================================"

# Download logo
if [ -n "$LOGO_URL" ]; then
    if robust_download "$LOGO_URL" "assets/images/logo.png" "app logo"; then
        log_success "Logo downloaded successfully"
    else
        log_warning "Failed to download logo, using default"
        if [ -f "assets/images/default_logo.png" ]; then
            cp "assets/images/default_logo.png" "assets/images/logo.png"
            log_info "Using default logo"
        fi
    fi
else
    log_warning "LOGO_URL not provided, using default"
    if [ -f "assets/images/default_logo.png" ]; then
        cp "assets/images/default_logo.png" "assets/images/logo.png"
        log_info "Using default logo"
    fi
fi

# Download splash image
if [ -n "$SPLASH_URL" ]; then
    if robust_download "$SPLASH_URL" "assets/images/splash.png" "splash image"; then
        log_success "Splash image downloaded successfully"
    else
        log_warning "Failed to download splash image, using default"
        if [ -f "assets/images/splash.png" ]; then
            log_info "Using existing splash image"
        elif [ -f "assets/images/default_logo.png" ]; then
            cp "assets/images/default_logo.png" "assets/images/splash.png"
            log_info "Using default logo as splash"
        fi
    fi
else
    log_warning "SPLASH_URL not provided, using default"
    if [ -f "assets/images/splash.png" ]; then
        log_info "Using existing splash image"
    elif [ -f "assets/images/default_logo.png" ]; then
        cp "assets/images/default_logo.png" "assets/images/splash.png"
        log_info "Using default logo as splash"
    fi
fi

# Download splash background
if [ -n "$SPLASH_BG_URL" ]; then
    if robust_download "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background"; then
        log_success "Splash background downloaded successfully"
    else
        log_warning "Failed to download splash background, using default"
        if command -v magick >/dev/null 2>&1; then
            magick -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
            log_info "Created default splash background with color: $SPLASH_BG_COLOR"
        elif command -v convert >/dev/null 2>&1; then
            convert -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
            log_info "Created default splash background with color: $SPLASH_BG_COLOR"
        fi
    fi
else
    log_warning "SPLASH_BG_URL not provided, using default"
    if command -v magick >/dev/null 2>&1; then
        magick -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
        log_info "Created default splash background with color: $SPLASH_BG_COLOR"
    elif command -v convert >/dev/null 2>&1; then
        convert -size 1125x2436 xc:"$SPLASH_BG_COLOR" "assets/images/splash_bg.png"
        log_info "Created default splash background with color: $SPLASH_BG_COLOR"
    fi
fi

# Step 3: Download iOS Certificates and Files with Enhanced Certificate Generation
log_info "Step 3: Download iOS Certificates and Files with Enhanced Certificate Generation"
log "================================================"

# Download Firebase config if push notifications enabled
if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_IOS" ]; then
    if robust_download "$FIREBASE_CONFIG_IOS" "ios/GoogleService-Info.plist" "Firebase config"; then
        log_success "Firebase config downloaded successfully"
    else
        log_warning "Failed to download Firebase config"
        log_info "Firebase setup will be skipped due to missing config"
    fi
fi

# Download APNS auth key if provided
if [ -n "$APNS_AUTH_KEY_URL" ] && [ -n "$APNS_KEY_ID" ]; then
    if robust_download "$APNS_AUTH_KEY_URL" "ios/AuthKey_${APNS_KEY_ID}.p8" "APNS auth key"; then
        log_success "APNS auth key downloaded successfully"
    else
        log_warning "Failed to download APNS auth key"
        log_info "APNS setup will be skipped due to missing auth key"
    fi
fi

# Enhanced Certificate Handling with Generation
log_info "Enhanced Certificate Handling with Generation"

# Handle iOS certificates (Option 1: P12 file)
if [ -n "$CERT_P12_URL" ] && [ -n "$CERT_PASSWORD" ]; then
    log_info "Using Option 1: P12 certificate"
    if robust_download "$CERT_P12_URL" "ios/certificates/Certificates.p12" "P12 certificate"; then
        log_success "P12 certificate downloaded successfully"
        # Validate the downloaded P12
        if validate_p12_file "ios/certificates/Certificates.p12" "$CERT_PASSWORD"; then
            log_success "P12 certificate validated successfully"
        else
            log_warning "P12 certificate validation failed"
        fi
    else
        log_warning "Failed to download P12 certificate"
        log_info "Will use automatic code signing instead"
    fi
# Handle iOS certificates (Option 2: CER and KEY files with enhanced generation)
elif [ -n "$CERT_CER_URL" ] && [ -n "$CERT_KEY_URL" ] && [ -n "$CERT_PASSWORD" ]; then
    log_info "Using Option 2: CER and KEY files with enhanced generation"
    
    # Download cer and key files
    if robust_download "$CERT_CER_URL" "/tmp/certificate.cer" "certificate file" && \
       robust_download "$CERT_KEY_URL" "/tmp/private.key" "private key file"; then
        
        log_success "Certificate files downloaded successfully"
        
        # Validate certificate files
        if validate_certificate_file "/tmp/certificate.cer" "Certificate" && \
           validate_certificate_file "/tmp/private.key" "Private Key"; then
            
            log_success "Certificate files validated successfully"
            
            # Generate P12 with enhanced generation
            if generate_p12_from_certificates "/tmp/certificate.cer" "/tmp/private.key" "ios/certificates/Certificates.p12" "$CERT_PASSWORD"; then
                log_success "P12 file generated successfully with enhanced generation"
                
                # Validate the generated P12
                if validate_p12_file "ios/certificates/Certificates.p12" "$CERT_PASSWORD"; then
                    log_success "Generated P12 file validated successfully"
                else
                    log_warning "Generated P12 file validation failed"
                fi
            else
                log_warning "Failed to generate P12 file with enhanced generation"
                log_info "Will use automatic code signing instead"
            fi
        else
            log_warning "Certificate file validation failed"
            log_info "Will use automatic code signing instead"
        fi
        
        # Clean up temporary files
        rm -f "/tmp/certificate.cer" "/tmp/private.key" "/tmp/certificate.pem"
    else
        log_warning "Failed to download certificate files"
        log_info "Will use automatic code signing instead"
    fi
else
    log_info "No certificate configuration found, using automatic code signing"
fi

# Download provisioning profile
if [ -n "$PROFILE_URL" ]; then
    if robust_download "$PROFILE_URL" "ios/Runner.mobileprovision" "provisioning profile"; then
        log_success "Provisioning profile downloaded successfully"
    else
        log_warning "Failed to download provisioning profile"
        log_info "Will use automatic provisioning profile management"
    fi
else
    log_info "No provisioning profile URL provided, using automatic management"
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
// Generated by Enhanced iOS Workflow with Certificate Generation
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

  // Assets
  static const String logoUrl = '${LOGO_URL//\'/\\\'}';
  static const String splashUrl = '${SPLASH_URL//\'/\\\'}';
  static const String splashBgUrl = '${SPLASH_BG_URL//\'/\\\'}';
  static const String splashBgColor = '${SPLASH_BG_COLOR//\'/\\\'}';
  static const String splashTagline = '$ESCAPED_SPLASH_TAGLINE';
  static const String splashTaglineColor = '${SPLASH_TAGLINE_COLOR//\'/\\\'}';
  static const String splashAnimation = '${SPLASH_ANIMATION//\'/\\\'}';
  static const String splashDuration = '${SPLASH_DURATION//\'/\\\'}';

  // Bottom Menu
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

  // Firebase Configuration
  static const String firebaseConfigIos = '${FIREBASE_CONFIG_IOS//\'/\\\'}';
  static const String apnsKeyId = '${APNS_KEY_ID//\'/\\\'}';
  static const String apnsAuthKeyUrl = '${APNS_AUTH_KEY_URL//\'/\\\'}';

  // Certificate Configuration
  static const String certPassword = '${CERT_PASSWORD//\'/\\\'}';
  static const String certP12Url = '${CERT_P12_URL//\'/\\\'}';
  static const String certCerUrl = '${CERT_CER_URL//\'/\\\'}';
  static const String certKeyUrl = '${CERT_KEY_URL//\'/\\\'}';

  // Provisioning Profile
  static const String profileType = '${PROFILE_TYPE//\'/\\\'}';
  static const String profileUrl = '${PROFILE_URL//\'/\\\'}';

  // Email Configuration
  static const bool enableEmailNotifications = $ENABLE_EMAIL_NOTIFICATIONS;
  static const String emailSmtpServer = '${EMAIL_SMTP_SERVER//\'/\\\'}';
  static const String emailSmtpPort = '${EMAIL_SMTP_PORT//\'/\\\'}';
  static const String emailSmtpUser = '${EMAIL_SMTP_USER//\'/\\\'}';
  static const String emailSmtpPass = '${EMAIL_SMTP_PASS//\'/\\\'}';
  static const String emailId = '${EMAIL_ID//\'/\\\'}';
}
EOF

log_success "env_config.dart generated successfully"

# Step 6: Configure Firebase for iOS
log_info "Step 6: Configure Firebase for iOS"
log "================================================"

if [ "$PUSH_NOTIFY" = "true" ]; then
    log_info "Configuring Firebase for iOS..."
    
    # Copy Firebase config if downloaded
    if [ -f "ios/GoogleService-Info.plist" ]; then
        log_success "Firebase config is ready for use"
    else
        log_warning "Firebase config not found, push notifications may not work"
    fi
    
    # Add Firebase pods to Podfile if not already present
    if [ -f "ios/Podfile" ]; then
        if ! grep -q "pod 'Firebase/Core'" ios/Podfile; then
            echo "pod 'Firebase/Core'" >> ios/Podfile
        fi
        if ! grep -q "pod 'Firebase/Messaging'" ios/Podfile; then
            echo "pod 'Firebase/Messaging'" >> ios/Podfile
        fi
        log_success "Firebase pods added to Podfile"
    fi
else
    log_info "Push notifications disabled, skipping Firebase configuration"
fi

# Step 7: Inject Permissions Dynamically
log_info "Step 7: Inject Permissions Dynamically"
log "================================================"

if [ -f "ios/Runner/Info.plist" ]; then
    log_info "Injecting permissions into Info.plist..."
    
    # Camera permission
    if [ "$IS_CAMERA" = "true" ]; then
        plutil -replace NSCameraUsageDescription -string "This app needs camera access to take photos and videos" ios/Runner/Info.plist || log_warning "Failed to add camera permission"
    fi
    
    # Location permission
    if [ "$IS_LOCATION" = "true" ]; then
        plutil -replace NSLocationWhenInUseUsageDescription -string "This app needs location access to provide location-based services" ios/Runner/Info.plist || log_warning "Failed to add location permission"
        plutil -replace NSLocationAlwaysAndWhenInUseUsageDescription -string "This app needs location access to provide location-based services" ios/Runner/Info.plist || log_warning "Failed to add location permission"
    fi
    
    # Microphone permission
    if [ "$IS_MIC" = "true" ]; then
        plutil -replace NSMicrophoneUsageDescription -string "This app needs microphone access for voice features" ios/Runner/Info.plist || log_warning "Failed to add microphone permission"
    fi
    
    # Notification permission
    if [ "$IS_NOTIFICATION" = "true" ]; then
        log_info "Notification permission will be requested at runtime"
    fi
    
    # Contact permission
    if [ "$IS_CONTACT" = "true" ]; then
        plutil -replace NSContactsUsageDescription -string "This app needs contact access to share contacts" ios/Runner/Info.plist || log_warning "Failed to add contact permission"
    fi
    
    # Biometric permission
    if [ "$IS_BIOMETRIC" = "true" ]; then
        plutil -replace NSFaceIDUsageDescription -string "This app uses Face ID for secure authentication" ios/Runner/Info.plist || log_warning "Failed to add biometric permission"
    fi
    
    # Calendar permission
    if [ "$IS_CALENDAR" = "true" ]; then
        plutil -replace NSCalendarsUsageDescription -string "This app needs calendar access to manage events" ios/Runner/Info.plist || log_warning "Failed to add calendar permission"
    fi
    
    # Storage permission
    if [ "$IS_STORAGE" = "true" ]; then
        log_info "Storage permission will be requested at runtime"
    fi
    
    log_success "Permissions injected successfully"
else
    log_warning "Info.plist not found, skipping permission injection"
fi

# Step 8: Flutter Build without Code Signing
log_info "Step 8: Flutter Build without Code Signing"
log "================================================"

log_info "Running flutter clean..."
flutter clean

log_info "Running flutter pub get..."
flutter pub get

log_info "Building iOS app without code signing..."
flutter build ios --release --no-codesign

log_success "Flutter build completed successfully"

# Step 9: Install CocoaPods Dependencies
log_info "Step 9: Install CocoaPods Dependencies"
log "================================================"

log_info "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

log_success "CocoaPods dependencies installed successfully"

# Step 10: Create Xcode Archive
log_info "Step 10: Create Xcode Archive"
log "================================================"

log_info "Creating Xcode archive..."
xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphoneos \
    -configuration Release \
    archive \
    -archivePath build/Runner.xcarchive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Automatic"

log_success "Xcode archive created successfully"

# Step 11: Create Export Options
log_info "Step 11: Create Export Options"
log "================================================"

log_info "Creating export options..."

cat > lib/scripts/ios-workflow/exportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$PROFILE_TYPE</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

log_success "Export options created successfully"

# Step 12: Export IPA
log_info "Step 12: Export IPA"
log "================================================"

log_info "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
    -exportPath build/export \
    -allowProvisioningUpdates

log_success "IPA exported successfully"

# Step 13: Verify and Copy IPA
log_info "Step 13: Verify and Copy IPA"
log "================================================"

if [ -f "build/export/Runner.ipa" ]; then
    log_success "IPA file found: build/export/Runner.ipa"
    
    # Copy to output directory
    cp "build/export/Runner.ipa" "output/ios/"
    log_success "IPA file copied to output/ios/"
    
    # Get file size
    IPA_SIZE=$(stat -f%z "output/ios/Runner.ipa" 2>/dev/null || stat -c%s "output/ios/Runner.ipa" 2>/dev/null || echo "0")
    log_info "IPA file size: $IPA_SIZE bytes"
else
    log_error "IPA file not found at build/export/Runner.ipa"
    exit 1
fi

# Step 14: Final Summary
log_info "Step 14: Final Summary"
log "================================================"

log_success "🎉 Enhanced iOS Workflow with Certificate Generation Completed Successfully!"
log "📱 App Name: $APP_NAME"
log "🆔 Bundle ID: $BUNDLE_ID"
log "📦 Version: $VERSION_NAME ($VERSION_CODE)"
log "👥 Team ID: $APPLE_TEAM_ID"
log "📁 IPA Location: output/ios/Runner.ipa"
log "🔐 Certificate: $(if [ -f "ios/certificates/Certificates.p12" ]; then echo "✅ Available"; else echo "❌ Not available"; fi)"
log "📋 Push Notifications: $(if [ "$PUSH_NOTIFY" = "true" ]; then echo "✅ Enabled"; else echo "❌ Disabled"; fi)"

# Clean up temporary files
rm -f "/tmp/certificate.cer" "/tmp/private.key" "/tmp/certificate.pem" 2>/dev/null || true

log_info "Enhanced iOS workflow completed with certificate generation support"
exit 0 