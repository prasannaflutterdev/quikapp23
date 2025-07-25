#!/bin/bash
# 🧪 Test Download Script for iOS Workflow
# Tests download functionality and network connectivity

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Test URLs from the error logs
TEST_URLS=(
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_V566SWNF69.p8"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode_sign_app_profile.mobileprovision"
)

# Function to test download with different methods
test_download() {
    local url="$1"
    local test_name="$2"
    local output_file="/tmp/test_${test_name}.tmp"
    
    log_info "Testing download: $test_name"
    log "URL: $url"
    
    # Test 1: Basic curl
    log_info "Test 1: Basic curl"
    if curl -L -f -s --connect-timeout 30 --max-time 120 -o "$output_file" "$url" 2>/dev/null; then
        log_success "Basic curl succeeded"
        local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        log "Downloaded size: $size bytes"
        rm -f "$output_file"
        return 0
    else
        log_warning "Basic curl failed"
    fi
    
    # Test 2: Curl with custom user agent
    log_info "Test 2: Curl with custom user agent"
    if curl -L -f -s --connect-timeout 60 --max-time 180 -o "$output_file" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" "$url" 2>/dev/null; then
        log_success "Curl with custom user agent succeeded"
        local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        log "Downloaded size: $size bytes"
        rm -f "$output_file"
        return 0
    else
        log_warning "Curl with custom user agent failed"
    fi
    
    # Test 3: Curl without redirect
    log_info "Test 3: Curl without redirect"
    if curl -f -s --connect-timeout 30 --max-time 120 -o "$output_file" "$url" 2>/dev/null; then
        log_success "Curl without redirect succeeded"
        local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        log "Downloaded size: $size bytes"
        rm -f "$output_file"
        return 0
    else
        log_warning "Curl without redirect failed"
    fi
    
    # Test 4: Wget if available
    if command -v wget >/dev/null 2>&1; then
        log_info "Test 4: Wget"
        if wget --timeout=60 --tries=3 -O "$output_file" "$url" 2>/dev/null; then
            log_success "Wget succeeded"
            local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
            log "Downloaded size: $size bytes"
            rm -f "$output_file"
            return 0
        else
            log_warning "Wget failed"
        fi
    fi
    
    # Test 5: Check if URL is accessible
    log_info "Test 5: Check URL accessibility"
    if curl -I -s --connect-timeout 10 "$url" | head -1 | grep -q "200\|301\|302"; then
        log_success "URL is accessible (HTTP 200/301/302)"
    else
        log_error "URL is not accessible"
    fi
    
    log_error "All download methods failed for: $test_name"
    return 1
}

# Function to test network connectivity
test_network() {
    log_info "Testing network connectivity..."
    
    # Test DNS resolution
    if nslookup raw.githubusercontent.com >/dev/null 2>&1; then
        log_success "DNS resolution for raw.githubusercontent.com successful"
    else
        log_error "DNS resolution for raw.githubusercontent.com failed"
    fi
    
    # Test HTTPS connectivity
    if curl -I -s --connect-timeout 10 https://raw.githubusercontent.com >/dev/null 2>&1; then
        log_success "HTTPS connectivity to raw.githubusercontent.com successful"
    else
        log_error "HTTPS connectivity to raw.githubusercontent.com failed"
    fi
    
    # Test GitHub API
    if curl -I -s --connect-timeout 10 https://api.github.com >/dev/null 2>&1; then
        log_success "GitHub API connectivity successful"
    else
        log_error "GitHub API connectivity failed"
    fi
}

# Main test execution
main() {
    log_info "🧪 Starting Download Test Script"
    log "================================================"
    
    # Test network connectivity first
    test_network
    
    log_info "Testing specific URLs from error logs..."
    
    # Test each URL
    local success_count=0
    local total_count=0
    
    for url in "${TEST_URLS[@]}"; do
        total_count=$((total_count + 1))
        local test_name=$(echo "$url" | sed 's/.*\///' | sed 's/\.[^.]*$//')
        
        if test_download "$url" "$test_name"; then
            success_count=$((success_count + 1))
        fi
        
        log "----------------------------------------"
    done
    
    # Summary
    log_info "Test Summary"
    log "================================================"
    log "Total URLs tested: $total_count"
    log "Successful downloads: $success_count"
    log "Failed downloads: $((total_count - success_count))"
    
    if [ $success_count -eq $total_count ]; then
        log_success "All downloads successful!"
    elif [ $success_count -gt 0 ]; then
        log_warning "Some downloads failed, but some succeeded"
    else
        log_error "All downloads failed - network connectivity issue detected"
    fi
    
    # Recommendations
    log_info "Recommendations:"
    if [ $success_count -eq 0 ]; then
        log "1. Check network connectivity and firewall settings"
        log "2. Verify DNS resolution for raw.githubusercontent.com"
        log "3. Check if GitHub is accessible from this environment"
        log "4. Consider using a different network or VPN"
    elif [ $success_count -lt $total_count ]; then
        log "1. Some URLs may be temporarily unavailable"
        log "2. Consider implementing fallback URLs"
        log "3. Add more retry logic with exponential backoff"
    else
        log "1. Network connectivity is working properly"
        log "2. The issue might be in the workflow script timing"
    fi
}

# Execute main function
main "$@" 