#!/bin/bash
# 🐛 Debug iOS Build Script
# Tests the build process step by step
# Usage: ./lib/scripts/ios-workflow/debug_build.sh

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DEBUG] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "Starting iOS Build Debug"
log "================================================"

# Step 1: Check Environment Variables
log_info "Step 1: Checking Environment Variables"
log "================================================"

# List all environment variables
log_info "All environment variables:"
env | grep -E "(BUNDLE_ID|APPLE_TEAM_ID|PROFILE_URL|APP_STORE|LOGO_URL|SPLASH_URL)" | sort

# Check specific variables
VARS=(
    "BUNDLE_ID"
    "APPLE_TEAM_ID"
    "PROFILE_URL"
    "APP_STORE_CONNECT_API_KEY_URL"
    "LOGO_URL"
    "SPLASH_URL"
    "IS_TESTFLIGHT"
)

for var in "${VARS[@]}"; do
    if [ -n "${!var:-}" ]; then
        log_success "✅ $var is set: ${!var}"
    else
        log_warning "⚠️ $var is not set"
    fi
done

# Step 2: Test URL Downloads
log_info "Step 2: Testing URL Downloads"
log "================================================"

if [ -n "${PROFILE_URL:-}" ]; then
    log_info "Testing provisioning profile download..."
    if curl -L -f -s -o /tmp/test_profile.mobileprovision "$PROFILE_URL" 2>/dev/null; then
        log_success "✅ Provisioning profile download successful"
        ls -la /tmp/test_profile.mobileprovision
    else
        log_error "❌ Provisioning profile download failed"
    fi
else
    log_warning "⚠️ PROFILE_URL not set"
fi

if [ -n "${APP_STORE_CONNECT_API_KEY_URL:-}" ]; then
    log_info "Testing App Store Connect API key download..."
    if curl -L -f -s -o /tmp/test_authkey.p8 "$APP_STORE_CONNECT_API_KEY_URL" 2>/dev/null; then
        log_success "✅ App Store Connect API key download successful"
        ls -la /tmp/test_authkey.p8
    else
        log_error "❌ App Store Connect API key download failed"
    fi
else
    log_warning "⚠️ APP_STORE_CONNECT_API_KEY_URL not set"
fi

if [ -n "${LOGO_URL:-}" ]; then
    log_info "Testing logo download..."
    if curl -L -f -s -o /tmp/test_logo.png "$LOGO_URL" 2>/dev/null; then
        log_success "✅ Logo download successful"
        ls -la /tmp/test_logo.png
    else
        log_error "❌ Logo download failed"
    fi
else
    log_warning "⚠️ LOGO_URL not set"
fi

# Step 3: Test Project Structure
log_info "Step 3: Testing Project Structure"
log "================================================"

REQUIRED_FILES=(
    "ios/Runner.xcworkspace"
    "ios/Podfile"
    "lib/scripts/utils/gen_env_config.sh"
    "pubspec.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        log_success "✅ Found: $file"
    else
        log_error "❌ Missing: $file"
    fi
done

# Step 4: Test Flutter Commands
log_info "Step 4: Testing Flutter Commands"
log "================================================"

log_info "Testing flutter --version..."
if flutter --version >/dev/null 2>&1; then
    log_success "✅ Flutter is available"
else
    log_error "❌ Flutter not available"
fi

log_info "Testing flutter pub get..."
if flutter pub get >/dev/null 2>&1; then
    log_success "✅ Flutter dependencies installed"
else
    log_error "❌ Flutter dependencies failed"
fi

# Step 5: Test iOS Commands
log_info "Step 5: Testing iOS Commands"
log "================================================"

log_info "Testing xcodebuild -version..."
if xcodebuild -version >/dev/null 2>&1; then
    log_success "✅ Xcode is available"
else
    log_error "❌ Xcode not available"
fi

log_info "Testing pod --version..."
if pod --version >/dev/null 2>&1; then
    log_success "✅ CocoaPods is available"
else
    log_error "❌ CocoaPods not available"
fi

# Step 6: Test iOS Project
log_info "Step 6: Testing iOS Project"
log "================================================"

if [ -d "ios" ]; then
    log_success "✅ iOS directory exists"
    
    if [ -f "ios/Podfile" ]; then
        log_success "✅ Podfile exists"
        
        log_info "Testing pod install..."
        cd ios
        if pod install --repo-update >/dev/null 2>&1; then
            log_success "✅ CocoaPods install successful"
        else
            log_error "❌ CocoaPods install failed"
        fi
        cd ..
    else
        log_error "❌ Podfile not found"
    fi
else
    log_error "❌ iOS directory not found"
fi

# Step 7: Final Summary
log_info "Step 7: Final Debug Summary"
log "================================================"

log_success "🎉 Debug completed!"
log "📱 Project: $(basename "$PWD")"
log "📁 Directory: $PWD"
log "🔧 Scripts: $(ls -la lib/scripts/ios-workflow/*.sh | wc -l) scripts found"

# Clean up test files
rm -f /tmp/test_profile.mobileprovision /tmp/test_authkey.p8 /tmp/test_logo.png 2>/dev/null || true

log_success "✅ Debug script completed successfully!"
exit 0 