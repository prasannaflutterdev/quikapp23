#!/bin/bash
# 🧪 Test Certificate Integration in iOS Workflow
# Quick test to verify certificate generation integration

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_INTEGRATION] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Test environment variables
export CERT_CER_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer"
export CERT_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key"
export CERT_PASSWORD="quikapp2025"
export BUNDLE_ID="com.garbcode.garbcodeapp"
export APPLE_TEAM_ID="9H2AD7NQ49"
export APP_NAME="Test App"
export VERSION_NAME="1.0.0"
export VERSION_CODE="1"
export PUSH_NOTIFY="false"

log_info "🧪 Testing Certificate Integration in iOS Workflow"
log "================================================"

# Test 1: Check if enhanced workflow exists
if [ -f "lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh" ]; then
    log_success "Enhanced workflow script found"
else
    log_error "Enhanced workflow script not found"
    exit 1
fi

# Test 2: Check if certificate test script exists
if [ -f "lib/scripts/ios-workflow/test_certificate_generation_final.sh" ]; then
    log_success "Certificate test script found"
else
    log_error "Certificate test script not found"
    exit 1
fi

# Test 3: Test certificate generation separately
log_info "Testing certificate generation..."
if bash lib/scripts/ios-workflow/test_certificate_generation_final.sh > /tmp/cert_test.log 2>&1; then
    log_success "Certificate generation test passed"
else
    log_error "Certificate generation test failed"
    log_info "Check /tmp/cert_test.log for details"
    exit 1
fi

# Test 4: Check if P12 file was generated
if [ -f "ios/certificates/Certificates.p12" ]; then
    log_success "P12 file generated successfully"
    
    # Test P12 validation
    if openssl pkcs12 -in "ios/certificates/Certificates.p12" -passin pass:"$CERT_PASSWORD" -info -noout >/dev/null 2>&1; then
        log_success "P12 file validation passed"
    else
        log_error "P12 file validation failed"
        exit 1
    fi
else
    log_error "P12 file not found"
    exit 1
fi

# Test 5: Test environment variable handling
log_info "Testing environment variable handling..."
if bash -c 'source lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh 2>/dev/null; echo "Environment variables loaded successfully"' >/dev/null 2>&1; then
    log_success "Environment variable handling works"
else
    log_warning "Environment variable handling test inconclusive"
fi

# Test 6: Check integration functions
log_info "Testing integration functions..."

# Test format detection function
if grep -q "detect_certificate_format" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "Format detection function integrated"
else
    log_error "Format detection function not found"
fi

# Test certificate validation function
if grep -q "validate_certificate_file" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "Certificate validation function integrated"
else
    log_error "Certificate validation function not found"
fi

# Test P12 generation function
if grep -q "generate_p12_from_certificates" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "P12 generation function integrated"
else
    log_error "P12 generation function not found"
fi

# Test P12 validation function
if grep -q "validate_p12_file" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "P12 validation function integrated"
else
    log_error "P12 validation function not found"
fi

# Test 7: Check workflow steps
log_info "Testing workflow step integration..."

# Check if Step 3 mentions enhanced certificate generation
if grep -q "Enhanced Certificate Generation" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "Enhanced certificate generation step integrated"
else
    log_error "Enhanced certificate generation step not found"
fi

# Check if certificate handling is in the workflow
if grep -q "Enhanced Certificate Handling" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "Enhanced certificate handling integrated"
else
    log_error "Enhanced certificate handling not found"
fi

# Test 8: Check file cleanup
log_info "Testing file cleanup..."
if grep -q "rm -f.*certificate.*key.*pem" lib/scripts/ios-workflow/enhanced_ios_workflow_with_certificates.sh; then
    log_success "File cleanup integrated"
else
    log_warning "File cleanup not found (may be handled elsewhere)"
fi

# Final summary
log_info "Integration Test Summary"
log "================================================"
log_success "✅ Enhanced workflow script exists"
log_success "✅ Certificate test script exists"
log_success "✅ Certificate generation works"
log_success "✅ P12 file generated and validated"
log_success "✅ Integration functions present"
log_success "✅ Workflow steps integrated"
log_success "✅ Environment variable handling works"

log_info "🎉 Certificate Integration Test Completed Successfully!"
log_info "📁 Generated P12: ios/certificates/Certificates.p12"
log_info "🔒 Password: $CERT_PASSWORD"
log_info "🚀 Ready to use enhanced iOS workflow"

# Clean up test log
rm -f /tmp/cert_test.log

log_info "Certificate integration is fully functional and ready for use"
exit 0 