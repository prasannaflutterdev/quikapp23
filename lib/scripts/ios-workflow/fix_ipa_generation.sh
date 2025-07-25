#!/bin/bash
# 🔧 Fix IPA Generation Script
# Addresses missing IPA file generation and provides detailed error reporting

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IPA_FIX] $1"; }
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

# Function to check if IPA exists and provide detailed analysis
check_ipa_generation() {
    log_info "Checking IPA file generation..."
    
    # Check for IPA in various possible locations
    local ipa_locations=(
        "build/export/Runner.ipa"
        "output/ios/Runner.ipa"
        "build/Runner.ipa"
        "*.ipa"
    )
    
    local ipa_found=false
    local found_location=""
    
    for location in "${ipa_locations[@]}"; do
        if [ -f "$location" ]; then
            ipa_found=true
            found_location="$location"
            break
        fi
    done
    
    if [ "$ipa_found" = true ]; then
        local size=$(stat -f%z "$found_location" 2>/dev/null || stat -c%s "$found_location" 2>/dev/null || echo "0")
        log_success "IPA file found: $found_location ($size bytes)"
        return 0
    else
        log_error "IPA file not found in any expected location"
        return 1
    fi
}

# Function to analyze build artifacts
analyze_build_artifacts() {
    log_info "Analyzing build artifacts..."
    
    # Check for Xcode archive
    if [ -d "build/Runner.xcarchive" ]; then
        log_success "Xcode archive found: build/Runner.xcarchive"
        ls -la build/Runner.xcarchive/
    else
        log_error "Xcode archive not found - build may have failed"
    fi
    
    # Check for export directory
    if [ -d "build/export" ]; then
        log_success "Export directory found: build/export"
        ls -la build/export/
    else
        log_error "Export directory not found - IPA export may have failed"
    fi
    
    # Check for Flutter build artifacts
    if [ -d "build/ios" ]; then
        log_success "Flutter iOS build directory found: build/ios"
        ls -la build/ios/
    else
        log_error "Flutter iOS build directory not found - Flutter build may have failed"
    fi
}

# Function to check build logs for errors
check_build_logs() {
    log_info "Checking build logs for errors..."
    
    # Look for common build error patterns
    local error_patterns=(
        "error:"
        "failed"
        "ERROR:"
        "BUILD FAILED"
        "xcodebuild: error"
        "flutter build ios"
    )
    
    # Check recent build output
    if [ -f "build/ios/logs/build.log" ]; then
        log_info "Found build log: build/ios/logs/build.log"
        for pattern in "${error_patterns[@]}"; do
            if grep -i "$pattern" build/ios/logs/build.log >/dev/null 2>&1; then
                log_error "Found error pattern in build log: $pattern"
                grep -i "$pattern" build/ios/logs/build.log | head -5
            fi
        done
    else
        log_warning "No build log found"
    fi
}

# Function to run the complete iOS build process
run_complete_ios_build() {
    log_info "Running complete iOS build process..."
    
    # Step 1: Environment Setup
    log_info "Step 1: Environment Setup"
    log "================================================"
    
    # Set required environment variables if not already set
    export WORKFLOW_ID=${WORKFLOW_ID:-"ios-workflow"}
    export APP_NAME=${APP_NAME:-"QuikApp"}
    export VERSION_NAME=${VERSION_NAME:-"1.0.0"}
    export VERSION_CODE=${VERSION_CODE:-"1"}
    export BUNDLE_ID=${BUNDLE_ID:-"com.example.quikapp"}
    export APPLE_TEAM_ID=${APPLE_TEAM_ID:-""}
    
    if [ -z "$APPLE_TEAM_ID" ]; then
        log_error "APPLE_TEAM_ID is required but not set"
        log "Please set APPLE_TEAM_ID environment variable"
        return 1
    fi
    
    log_success "Environment variables validated"
    
    # Step 2: Flutter Clean and Dependencies
    log_info "Step 2: Flutter Clean and Dependencies"
    log "================================================"
    
    log_info "Cleaning previous builds..."
    flutter clean || log_warning "Flutter clean failed, continuing anyway"
    
    log_info "Getting Flutter dependencies..."
    if ! flutter pub get; then
        log_error "Failed to get Flutter dependencies"
        return 1
    fi
    
    # Step 3: Flutter Build without Code Signing
    log_info "Step 3: Flutter Build without Code Signing"
    log "================================================"
    
    log_info "Building Flutter app without code signing..."
    if ! flutter build ios --release --no-codesign; then
        log_error "Flutter build failed"
        return 1
    fi
    
    log_success "Flutter build completed successfully"
    
    # Step 4: Install CocoaPods Dependencies
    log_info "Step 4: Install CocoaPods Dependencies"
    log "================================================"
    
    cd ios
    log_info "Installing CocoaPods dependencies..."
    if ! pod install --repo-update; then
        log_warning "CocoaPods install failed, trying without --repo-update..."
        if ! pod install; then
            log_error "CocoaPods install failed completely"
            cd ..
            return 1
        fi
    fi
    cd ..
    
    log_success "CocoaPods dependencies installed successfully"
    
    # Step 5: Create Xcode Archive
    log_info "Step 5: Create Xcode Archive"
    log "================================================"
    
    log_info "Creating Xcode archive with code signing..."
    if ! xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -sdk iphoneos \
        -configuration Release archive \
        -archivePath build/Runner.xcarchive \
        DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        CODE_SIGN_STYLE="Automatic"; then
        log_error "Xcode archive failed"
        return 1
    fi
    
    log_success "Xcode archive completed successfully"
    
    # Step 6: Create Export Options
    log_info "Step 6: Create Export Options"
    log "================================================"
    
    log_info "Creating ExportOptions.plist..."
    cat > lib/scripts/ios-workflow/exportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF
    
    log_success "ExportOptions.plist created"
    
    # Step 7: Export IPA
    log_info "Step 7: Export IPA"
    log "================================================"
    
    log_info "Exporting IPA..."
    if ! xcodebuild -exportArchive \
        -archivePath build/Runner.xcarchive \
        -exportOptionsPlist lib/scripts/ios-workflow/exportOptions.plist \
        -exportPath build/export \
        -allowProvisioningUpdates; then
        log_error "IPA export failed"
        return 1
    fi
    
    log_success "IPA export completed successfully"
    
    # Step 8: Verify and Copy IPA
    log_info "Step 8: Verify and Copy IPA"
    log "================================================"
    
    if [ -f "build/export/Runner.ipa" ]; then
        log_success "IPA file created successfully: build/export/Runner.ipa"
        ls -la build/export/
        
        # Copy to output directory for Codemagic artifacts
        log_info "Copying IPA to output directory..."
        if cp build/export/Runner.ipa output/ios/; then
            log_success "IPA copied to output directory successfully"
        else
            log_warning "Failed to copy IPA to output directory"
        fi
    else
        log_error "IPA file not found after export"
        return 1
    fi
    
    return 0
}

# Function to provide detailed error analysis
provide_error_analysis() {
    log_info "Providing detailed error analysis..."
    log "================================================"
    
    log_error "❌ IPA Generation Failed - Detailed Analysis"
    log ""
    log "🔍 Possible Causes:"
    log "1. Flutter build failed during iOS compilation"
    log "2. Xcode archive creation failed"
    log "3. IPA export failed due to code signing issues"
    log "4. Missing or invalid provisioning profiles"
    log "5. Apple Developer account access issues"
    log "6. Bundle identifier conflicts"
    log "7. Team ID or certificate issues"
    log ""
    log "🔧 Troubleshooting Steps:"
    log "1. Check Apple Developer account access"
    log "2. Verify provisioning profiles are valid"
    log "3. Ensure bundle identifier is unique"
    log "4. Check team ID and certificates"
    log "5. Review Xcode build logs for specific errors"
    log "6. Verify iOS project configuration"
    log ""
    log "📋 Required Environment Variables:"
    log "- APPLE_TEAM_ID: Your Apple Developer Team ID"
    log "- BUNDLE_ID: Your app's bundle identifier"
    log "- APP_NAME: Your app's display name"
    log ""
    log "🚀 Next Steps:"
    log "1. Run the complete build process manually"
    log "2. Check build logs for specific error messages"
    log "3. Verify Apple Developer account settings"
    log "4. Test with a simple iOS project first"
}

# Main execution
main() {
    log_info "🔧 Starting IPA Generation Fix"
    log "================================================"
    
    # Check if IPA already exists
    if check_ipa_generation; then
        log_success "IPA file already exists - no fix needed"
        return 0
    fi
    
    # Analyze existing build artifacts
    analyze_build_artifacts
    
    # Check build logs for errors
    check_build_logs
    
    # Run complete iOS build process
    if run_complete_ios_build; then
        log_success "🎉 IPA generation completed successfully!"
        
        # Final verification
        if check_ipa_generation; then
            log_success "✅ IPA file verified and ready for distribution"
            return 0
        else
            log_error "❌ IPA file still not found after build completion"
            provide_error_analysis
            return 1
        fi
    else
        log_error "❌ IPA generation failed"
        provide_error_analysis
        return 1
    fi
}

# Execute main function
main "$@" 