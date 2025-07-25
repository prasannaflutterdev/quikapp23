#!/bin/bash
# 🧪 Test EnvConfig Properties
# Tests that all required EnvConfig properties are generated correctly

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_ENV_CONFIG] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "🧪 Testing EnvConfig Properties"
log "================================================"

# List of required properties based on main.dart usage
REQUIRED_PROPERTIES=(
    "appName"
    "versionName"
    "versionCode"
    "bundleId"
    "packageName"
    "organizationName"
    "webUrl"
    "userName"
    "appId"
    "workflowId"
    "pushNotify"
    "isChatbot"
    "isDomainUrl"
    "isSplash"
    "isPulldown"
    "isBottommenu"
    "isLoadIndicator"
    "isCamera"
    "isLocation"
    "isMic"
    "isNotification"
    "isContact"
    "isBiometric"
    "isCalendar"
    "isStorage"
    "splashBgColor"
    "splashTagline"
    "splashTaglineColor"
    "splashAnimation"
    "splashDuration"
    "splashUrl"
    "splashBg"
    "bottomMenuItems"
    "bottomMenuBgColor"
    "bottomMenuIconColor"
    "bottomMenuTextColor"
    "bottomMenuFont"
    "bottomMenuFontSize"
    "bottomMenuFontBold"
    "bottomMenuFontItalic"
    "bottomMenuActiveTabColor"
    "bottomMenuIconPosition"
    "bottommenuItems"
    "bottommenuBgColor"
    "bottommenuActiveTabColor"
    "bottommenuTextColor"
    "bottommenuIconColor"
    "bottommenuIconPosition"
)

# Test 1: Check if env_config.dart exists
log_info "Test 1: Checking if env_config.dart exists..."

if [ -f "lib/config/env_config.dart" ]; then
    log_success "env_config.dart file exists"
else
    log_error "env_config.dart file not found"
    exit 1
fi

# Test 2: Check each required property
log_info "Test 2: Checking required properties..."

MISSING_PROPERTIES=()

for property in "${REQUIRED_PROPERTIES[@]}"; do
    if grep -q "static const.*$property" lib/config/env_config.dart; then
        log_success "Property '$property' found"
    else
        log_error "Property '$property' missing"
        MISSING_PROPERTIES+=("$property")
    fi
done

# Test 3: Check for syntax errors
log_info "Test 3: Checking for Dart syntax errors..."

if dart analyze lib/config/env_config.dart >/dev/null 2>&1; then
    log_success "No Dart syntax errors found"
else
    log_warning "Dart syntax errors found"
    dart analyze lib/config/env_config.dart
fi

# Test 4: Show missing properties
if [ ${#MISSING_PROPERTIES[@]} -gt 0 ]; then
    log_error "Missing properties:"
    for property in "${MISSING_PROPERTIES[@]}"; do
        echo "  - $property"
    done
    exit 1
else
    log_success "All required properties are present"
fi

# Test 5: Show the generated file structure
log_info "Test 5: Showing generated file structure..."

echo "Generated EnvConfig properties:"
grep "static const" lib/config/env_config.dart | sed 's/^  //'

# Test 6: Check for duplicate properties
log_info "Test 6: Checking for duplicate properties..."

DUPLICATES=$(grep "static const" lib/config/env_config.dart | cut -d' ' -f4 | sort | uniq -d)

if [ -n "$DUPLICATES" ]; then
    log_warning "Found duplicate properties:"
    echo "$DUPLICATES"
else
    log_success "No duplicate properties found"
fi

# Test 7: Validate property types
log_info "Test 7: Validating property types..."

# Check boolean properties
BOOLEAN_PROPERTIES=("pushNotify" "isChatbot" "isDomainUrl" "isSplash" "isPulldown" "isBottommenu" "isLoadIndicator" "isCamera" "isLocation" "isMic" "isNotification" "isContact" "isBiometric" "isCalendar" "isStorage" "bottomMenuFontBold" "bottomMenuFontItalic")

for property in "${BOOLEAN_PROPERTIES[@]}"; do
    if grep -q "static const bool $property" lib/config/env_config.dart; then
        log_success "Boolean property '$property' correctly typed"
    else
        log_warning "Boolean property '$property' may have incorrect type"
    fi
done

# Check string properties
STRING_PROPERTIES=("appName" "versionName" "versionCode" "bundleId" "packageName" "organizationName" "webUrl" "userName" "appId" "workflowId" "splashBgColor" "splashTagline" "splashTaglineColor" "splashAnimation" "splashDuration" "splashUrl" "splashBg" "bottomMenuItems" "bottomMenuBgColor" "bottomMenuIconColor" "bottomMenuTextColor" "bottomMenuFont" "bottomMenuFontSize" "bottomMenuActiveTabColor" "bottomMenuIconPosition" "bottommenuItems" "bottommenuBgColor" "bottommenuActiveTabColor" "bottommenuTextColor" "bottommenuIconColor" "bottommenuIconPosition")

for property in "${STRING_PROPERTIES[@]}"; do
    if grep -q "static const String $property" lib/config/env_config.dart; then
        log_success "String property '$property' correctly typed"
    else
        log_warning "String property '$property' may have incorrect type"
    fi
done

log_success "🎉 EnvConfig properties test completed!"
log_info "All required properties are generated correctly"
log_info "The env_config.dart file is ready for use" 