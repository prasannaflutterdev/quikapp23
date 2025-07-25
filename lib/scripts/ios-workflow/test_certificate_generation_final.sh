#!/bin/bash
# 🧪 Test Certificate Generation Script (Final)
# Downloads CER and KEY files and generates P12 with validation
# Properly handles DER to PEM conversion

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_CERT_FINAL] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Certificate URLs and configuration
CERT_CER_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer"
CERT_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key"
CERT_PASSWORD="quikapp2025"
TEST_DIR="/tmp/cert_test_$(date +%s)"
OUTPUT_P12="$TEST_DIR/Certificates.p12"

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

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

# Function to download file with multiple methods
download_file() {
    local url="$1"
    local output_file="$2"
    local description="$3"
    
    log_info "Downloading $description from: $url"
    
    # Method 1: wget (Primary)
    if command -v wget >/dev/null 2>&1; then
        log_info "Trying wget download..."
        if wget --timeout=60 --tries=3 --retry-connrefused --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_file" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with wget"
            return 0
        else
            log_warning "wget download failed, trying curl..."
        fi
    fi
    
    # Method 2: curl
    if command -v curl >/dev/null 2>&1; then
        log_info "Trying curl download..."
        if curl -L -f -s --connect-timeout 30 --max-time 120 \
            --retry 3 --retry-delay 2 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -o "$output_file" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully with curl"
            return 0
        else
            log_warning "curl download failed..."
        fi
    fi
    
    log_error "Failed to download $description"
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

# Function to generate p12 file
generate_p12() {
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
        pem_cert_file="$TEST_DIR/certificate.pem"
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

# Function to test certificate chain
test_certificate_chain() {
    local p12_file="$1"
    local password="$2"
    
    log_info "Testing certificate chain..."
    
    # Extract certificate from p12
    local temp_cert="$TEST_DIR/extracted_cert.pem"
    if openssl pkcs12 -in "$p12_file" -passin pass:"$password" -clcerts -nokeys -out "$temp_cert" 2>/dev/null; then
        log_success "Certificate extracted from P12"
        
        # Verify certificate chain
        if openssl verify -CAfile /dev/null -untrusted "$temp_cert" "$temp_cert" >/dev/null 2>&1; then
            log_success "Certificate chain verification passed"
        else
            log_warning "Certificate chain verification failed (this is normal for development certificates)"
        fi
        
        rm -f "$temp_cert"
    else
        log_error "Failed to extract certificate from P12"
    fi
}

# Main execution
main() {
    log_info "🧪 Starting Certificate Generation Test (Final)"
    log "================================================"
    
    # Test network connectivity
    if ! test_network_connectivity; then
        log_error "Network connectivity test failed"
        exit 1
    fi
    
    log_success "Network connectivity test passed"
    
    # Download certificate files
    log_info "Step 1: Downloading Certificate Files"
    log "================================================"
    
    local cer_file="$TEST_DIR/ios_distribution_gps.cer"
    local key_file="$TEST_DIR/private.key"
    
    # Download certificate file
    if download_file "$CERT_CER_URL" "$cer_file" "certificate file"; then
        if validate_certificate_file "$cer_file" "Certificate"; then
            log_success "✅ Certificate file downloaded and validated"
        else
            log_error "❌ Certificate file validation failed"
            exit 1
        fi
    else
        log_error "❌ Failed to download certificate file"
        exit 1
    fi
    
    # Download private key file
    if download_file "$CERT_KEY_URL" "$key_file" "private key file"; then
        if validate_certificate_file "$key_file" "Private Key"; then
            log_success "✅ Private key file downloaded and validated"
        else
            log_error "❌ Private key file validation failed"
            exit 1
        fi
    else
        log_error "❌ Failed to download private key file"
        exit 1
    fi
    
    # Generate p12 file
    log_info "Step 2: Generating P12 File"
    log "================================================"
    
    if generate_p12 "$cer_file" "$key_file" "$OUTPUT_P12" "$CERT_PASSWORD"; then
        log_success "✅ P12 file generated successfully"
    else
        log_error "❌ Failed to generate P12 file"
        exit 1
    fi
    
    # Validate p12 file
    log_info "Step 3: Validating P12 File"
    log "================================================"
    
    if validate_p12_file "$OUTPUT_P12" "$CERT_PASSWORD"; then
        log_success "✅ P12 file validated successfully"
    else
        log_error "❌ P12 file validation failed"
        exit 1
    fi
    
    # Test certificate chain
    log_info "Step 4: Testing Certificate Chain"
    log "================================================"
    
    test_certificate_chain "$OUTPUT_P12" "$CERT_PASSWORD"
    
    # Final summary
    log_info "Step 5: Final Summary"
    log "================================================"
    
    log_success "🎉 Certificate Generation Test Completed Successfully!"
    log "📁 Test Directory: $TEST_DIR"
    log "🔐 Certificate File: $cer_file"
    log "🔑 Private Key File: $key_file"
    log "📦 P12 File: $OUTPUT_P12"
    log "🔒 Password: $CERT_PASSWORD"
    
    # List files with sizes
    log_info "File Details:"
    ls -la "$TEST_DIR/"
    
    # Copy p12 to project directory for use
    mkdir -p "$PROJECT_ROOT/ios/certificates"
    if cp "$OUTPUT_P12" "$PROJECT_ROOT/ios/certificates/"; then
        log_success "✅ P12 file copied to project directory: ios/certificates/Certificates.p12"
    else
        log_warning "⚠️ Failed to copy P12 file to project directory"
    fi
    
    log_info "Certificate files are ready for iOS code signing"
    log_info "Use the P12 file with password '$CERT_PASSWORD' in your iOS workflow"
    
    # Cleanup option
    log_info "To clean up test files, run: rm -rf $TEST_DIR"
}

# Execute main function
main "$@" 