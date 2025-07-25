#!/bin/bash
# 🧪 Test Wget Download Script
# Tests wget download functionality with specific URLs from error logs

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_WGET] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Test URLs from the error logs
TEST_URLS=(
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode_sign_app_profile.mobileprovision"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_S95LCWAH99.p8"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-gc.plist"
)

# Function to test wget download
test_wget_download() {
    local url="$1"
    local description="$2"
    local output_file="/tmp/test_$(basename "$url")"
    
    log_info "Testing wget download for $description..."
    log_info "URL: $url"
    
    # Check if wget is available
    if ! command -v wget >/dev/null 2>&1; then
        log_error "wget is not available"
        return 1
    fi
    
    # Test wget download with various options
    local success=false
    
    # Method 1: Basic wget
    log_info "Trying basic wget..."
    if wget --timeout=60 --tries=3 -O "$output_file" "$url" 2>/dev/null; then
        log_success "Basic wget download successful"
        success=true
    else
        log_warning "Basic wget failed"
    fi
    
    # Method 2: wget with user agent
    if [ "$success" = false ]; then
        log_info "Trying wget with user agent..."
        if wget --timeout=60 --tries=3 \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_file" "$url" 2>/dev/null; then
            log_success "wget with user agent successful"
            success=true
        else
            log_warning "wget with user agent failed"
        fi
    fi
    
    # Method 3: wget without certificate check
    if [ "$success" = false ]; then
        log_info "Trying wget without certificate check..."
        if wget --timeout=60 --tries=3 --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_file" "$url" 2>/dev/null; then
            log_success "wget without certificate check successful"
            success=true
        else
            log_warning "wget without certificate check failed"
        fi
    fi
    
    # Method 4: wget with retry connection refused
    if [ "$success" = false ]; then
        log_info "Trying wget with retry connection refused..."
        if wget --timeout=60 --tries=3 --retry-connrefused --no-check-certificate \
            --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -O "$output_file" "$url" 2>/dev/null; then
            log_success "wget with retry connection refused successful"
            success=true
        else
            log_warning "wget with retry connection refused failed"
        fi
    fi
    
    # Method 5: wget with different user agent
    if [ "$success" = false ]; then
        log_info "Trying wget with Windows user agent..."
        if wget --timeout=60 --tries=3 --no-check-certificate \
            --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
            -O "$output_file" "$url" 2>/dev/null; then
            log_success "wget with Windows user agent successful"
            success=true
        else
            log_warning "wget with Windows user agent failed"
        fi
    fi
    
    if [ "$success" = true ]; then
        # Check file size
        if [ -f "$output_file" ]; then
            local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
            log_success "$description downloaded successfully ($size bytes)"
            rm -f "$output_file"
            return 0
        else
            log_error "File not found after successful download"
            return 1
        fi
    else
        log_error "All wget methods failed for $description"
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
    
    # Test wget availability
    if command -v wget >/dev/null 2>&1; then
        log_success "wget is available"
    else
        log_error "wget is not available"
        return 1
    fi
    
    return 0
}

# Function to test curl as fallback
test_curl_download() {
    local url="$1"
    local description="$2"
    local output_file="/tmp/test_curl_$(basename "$url")"
    
    log_info "Testing curl download for $description..."
    log_info "URL: $url"
    
    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is not available"
        return 1
    fi
    
    # Test curl download
    if curl -L -f -s --connect-timeout 30 --max-time 120 \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        -o "$output_file" "$url" 2>/dev/null; then
        
        if [ -f "$output_file" ]; then
            local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
            log_success "$description downloaded successfully with curl ($size bytes)"
            rm -f "$output_file"
            return 0
        else
            log_error "File not found after successful curl download"
            return 1
        fi
    else
        log_error "curl download failed for $description"
        return 1
    fi
}

# Main execution
main() {
    log_info "🧪 Starting Wget Download Test"
    log "================================================"
    
    # Test network connectivity first
    if ! test_network_connectivity; then
        log_error "Network connectivity test failed"
        exit 1
    fi
    
    log_success "Network connectivity test passed"
    
    # Test each URL
    local total_tests=${#TEST_URLS[@]}
    local successful_tests=0
    local failed_tests=0
    
    log_info "Testing $total_tests URLs..."
    
    for url in "${TEST_URLS[@]}"; do
        local description=$(basename "$url")
        
        log_info "Testing: $description"
        log "----------------------------------------"
        
        # Try wget first
        if test_wget_download "$url" "$description"; then
            log_success "✅ wget download successful for $description"
            ((successful_tests++))
        else
            log_warning "⚠️ wget download failed for $description, trying curl..."
            
            # Try curl as fallback
            if test_curl_download "$url" "$description"; then
                log_success "✅ curl download successful for $description"
                ((successful_tests++))
            else
                log_error "❌ Both wget and curl failed for $description"
                ((failed_tests++))
            fi
        fi
        
        log ""
    done
    
    # Summary
    log_info "Test Summary"
    log "================================================"
    log "Total URLs tested: $total_tests"
    log "Successful downloads: $successful_tests"
    log "Failed downloads: $failed_tests"
    
    if [ $successful_tests -eq $total_tests ]; then
        log_success "🎉 All downloads successful!"
        log_info "wget download functionality is working correctly"
    elif [ $successful_tests -gt 0 ]; then
        log_warning "⚠️ Some downloads failed ($failed_tests/$total_tests)"
        log_info "wget is partially working, but some URLs may be inaccessible"
    else
        log_error "❌ All downloads failed"
        log_error "There may be network connectivity issues or URL accessibility problems"
    fi
    
    # Recommendations
    log_info "Recommendations:"
    if [ $failed_tests -gt 0 ]; then
        log "1. Check if the URLs are publicly accessible"
        log "2. Verify network connectivity and firewall settings"
        log "3. Try using different user agents or download methods"
        log "4. Consider using fallback assets for failed downloads"
    else
        log "1. wget download functionality is working correctly"
        log "2. The robust download workflow should work properly"
        log "3. Consider using wget as the primary download method"
    fi
}

# Execute main function
main "$@" 