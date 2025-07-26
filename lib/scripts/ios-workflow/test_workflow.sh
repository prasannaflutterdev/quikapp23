#!/usr/bin/env bash

# Test script for iOS Workflow Components
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Test function
test_component() {
    local component="$1"
    local description="$2"
    local test_command="$3"
    
    log_info "Testing $description..."
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "$description: PASSED"
        return 0
    else
        log_error "$description: FAILED"
        return 1
    fi
}

# Main test function
main() {
    echo "🧪 iOS Workflow Component Tests"
    echo "==============================="
    
    local test_results=()
    
    # Test 1: Check if fixed workflow script exists
    test_component "fixed_workflow" "Fixed iOS Workflow Script" "[ -f 'lib/scripts/ios-workflow/fixed_ios_workflow.sh' ]"
    test_results+=($?)
    
    # Test 2: Check if validation script exists
    test_component "validation_script" "Environment Validation Script" "[ -f 'lib/scripts/ios-workflow/validate_env_vars.sh' ]"
    test_results+=($?)
    
    # Test 3: Check if scripts are executable
    test_component "executable_permissions" "Script Executable Permissions" "[ -x 'lib/scripts/ios-workflow/fixed_ios_workflow.sh' ] && [ -x 'lib/scripts/ios-workflow/validate_env_vars.sh' ]"
    test_results+=($?)
    
    # Test 4: Check if codemagic.yaml exists
    test_component "codemagic_config" "Codemagic Configuration" "[ -f 'codemagic.yaml' ]"
    test_results+=($?)
    
    # Test 5: Check if iOS project exists
    test_component "ios_project" "iOS Project Structure" "[ -d 'ios' ] && [ -f 'ios/Runner.xcodeproj/project.pbxproj' ]"
    test_results+=($?)
    
    # Test 6: Check if Flutter project exists
    test_component "flutter_project" "Flutter Project Structure" "[ -f 'pubspec.yaml' ] && [ -d 'lib' ]"
    test_results+=($?)
    
    # Test 7: Check if required directories exist
    test_component "directories" "Required Directories" "[ -d 'lib/scripts' ] && [ -d 'lib/config' ] && [ -d 'assets' ]"
    test_results+=($?)
    
    # Test 8: Check if environment variables are accessible
    test_component "env_vars" "Environment Variables Access" "echo \$BUNDLE_ID > /dev/null 2>&1"
    test_results+=($?)
    
    # Test 9: Check if xcodebuild is available
    test_component "xcodebuild" "Xcode Build Tools" "command -v xcodebuild >/dev/null 2>&1"
    test_results+=($?)
    
    # Test 10: Check if flutter is available
    test_component "flutter" "Flutter SDK" "command -v flutter >/dev/null 2>&1"
    test_results+=($?)
    
    # Summary
    echo ""
    echo "📊 Test Results Summary:"
    echo "========================"
    
    local passed=0
    local failed=0
    
    for result in "${test_results[@]}"; do
        if [ "$result" -eq 0 ]; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo "✅ Passed: $passed"
    echo "❌ Failed: $failed"
    echo "📋 Total: ${#test_results[@]}"
    
    if [ "$failed" -eq 0 ]; then
        log_success "🎉 All tests passed! iOS workflow is ready to use."
        echo ""
        echo "🚀 Next steps:"
        echo "   1. Set up environment variables in Codemagic"
        echo "   2. Run the iOS workflow"
        echo "   3. Check build artifacts"
    else
        log_error "❌ Some tests failed. Please fix the issues before running the workflow."
        echo ""
        echo "💡 Common fixes:"
        echo "   - Ensure all required files exist"
        echo "   - Check file permissions"
        echo "   - Verify project structure"
        echo "   - Install required tools"
    fi
    
    exit $failed
}

# Run main function
main "$@" 