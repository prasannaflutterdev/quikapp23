#!/bin/bash
# 🧪 Test Ultimate Download Script
# Tests download functionality with proven working parameters

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_ULTIMATE] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Test URLs from the build logs
TEST_URLS=(
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode_sign_app_profile.mobileprovision"
    "https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_S95LCWAH99.p8"
)

# Ultimate download function with proven working parameters
ultimate_download() {
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
    
    # Use the exact working parameters from the debug environment
    if curl -L -f -s --connect-timeout 30 --max-time 120 -o "$output_path" "$url" 2>/dev/null; then
        log_success "$description downloaded successfully"
        return 0
    fi
    
    # Fallback: Try with different user agent
    if curl -L -f -s --connect-timeout 30 --max-time 120 -o "$output_path" \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$url" 2>/dev/null; then
        log_success "$description downloaded successfully (with custom user agent)"
        return 0
    fi
    
    # Fallback: Try without redirect
    if curl -f -s --connect-timeout 30 --max-time 120 -o "$output_path" "$url" 2>/dev/null; then
        log_success "$description downloaded successfully (without redirect)"
        return 0
    fi
    
    # Fallback: Try with wget if available
    if command -v wget >/dev/null 2>&1; then
        if wget --timeout=60 --tries=3 -O "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully (with wget)"
            return 0
        fi
    fi
    
    log_error "Failed to download $description"
    return 1
}

# Main test execution
main() {
    log_info "🧪 Starting Ultimate Download Test"
    log "================================================"
    
    # Test each URL
    local success_count=0
    local total_count=0
    
    for url in "${TEST_URLS[@]}"; do
        total_count=$((total_count + 1))
        local test_name=$(echo "$url" | sed 's/.*\///' | sed 's/\.[^.]*$//')
        local output_file="/tmp/test_ultimate_${test_name}.tmp"
        
        log_info "Testing download: $test_name"
        log "URL: $url"
        
        if ultimate_download "$url" "$output_file" "$test_name"; then
            success_count=$((success_count + 1))
            local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
            log "Downloaded size: $size bytes"
            rm -f "$output_file"
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
        log_info "The ultimate download function is working correctly"
    elif [ $success_count -gt 0 ]; then
        log_warning "Some downloads failed, but some succeeded"
        log_info "The download function has partial success"
    else
        log_error "All downloads failed - there may be a network issue"
    fi
}

# Execute main function
main "$@" 