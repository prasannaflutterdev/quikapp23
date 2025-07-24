#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_FIX] ❌ $1"; }

# Parse command line arguments
VALIDATE_IPA="${1:-}"
IPA_PATH="${2:-}"

log "🔧 Starting enhanced bundle executable fix"

# Function to validate IPA file
validate_ipa() {
    local ipa_path="$1"
    
    log_info "🔍 Validating IPA: $ipa_path"
    
    if [ ! -f "$ipa_path" ]; then
        log_error "IPA file not found: $ipa_path"
        return 1
    fi
    
    # Check file size
    local file_size=$(stat -f%z "$ipa_path" 2>/dev/null || stat -c%s "$ipa_path" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1000000 ]; then
        log_error "IPA file is too small: $file_size bytes"
        return 1
    fi
    
    # Check if it's a valid ZIP file
    if ! unzip -t "$ipa_path" > /dev/null 2>&1; then
        log_error "IPA file is not a valid ZIP archive"
        return 1
    fi
    
    log_success "IPA validation passed"
    return 0
}

# Function to extract and analyze IPA
analyze_ipa() {
    local ipa_path="$1"
    local temp_dir=$(mktemp -d)
    
    log_info "📦 Extracting IPA for analysis..."
    
    # Extract IPA
    unzip -q "$ipa_path" -d "$temp_dir"
    
    # Look for app bundle
    local app_bundle=""
    for app in "$temp_dir/Payload"/*.app; do
        if [ -d "$app" ]; then
            app_bundle="$app"
            break
        fi
    done
    
    if [ -z "$app_bundle" ]; then
        log_error "No app bundle found in IPA"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "Found app bundle: $app_bundle"
    
    # Check bundle executable
    local executable_name=$(plutil -extract CFBundleExecutable raw "$app_bundle/Info.plist" 2>/dev/null || echo "Runner")
    local executable_path="$app_bundle/$executable_name"
    
    if [ ! -f "$executable_path" ]; then
        log_error "Bundle executable not found: $executable_path"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check executable permissions
    if [ ! -x "$executable_path" ]; then
        log_warning "Bundle executable is not executable, fixing permissions..."
        chmod +x "$executable_path"
    fi
    
    # Check for required frameworks
    local frameworks_dir="$app_bundle/Frameworks"
    if [ -d "$frameworks_dir" ]; then
        log_info "Checking frameworks..."
        for framework in "$frameworks_dir"/*.framework; do
            if [ -d "$framework" ]; then
                local framework_name=$(basename "$framework" .framework)
                local framework_executable="$framework/$framework_name"
                
                if [ ! -f "$framework_executable" ]; then
                    log_warning "Framework executable missing: $framework_executable"
                elif [ ! -x "$framework_executable" ]; then
                    log_warning "Framework executable not executable, fixing permissions..."
                    chmod +x "$framework_executable"
                fi
            fi
        done
    fi
    
    # Check for required dylibs
    local dylibs_dir="$app_bundle/Frameworks"
    if [ -d "$dylibs_dir" ]; then
        log_info "Checking dylibs..."
        for dylib in "$dylibs_dir"/*.dylib; do
            if [ -f "$dylib" ]; then
                if [ ! -x "$dylib" ]; then
                    log_warning "Dylib not executable, fixing permissions..."
                    chmod +x "$dylib"
                fi
            fi
        done
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    log_success "IPA analysis completed"
    return 0
}

# Function to fix bundle executable issues
fix_bundle_executable() {
    local ipa_path="$1"
    local temp_dir=$(mktemp -d)
    
    log_info "🔧 Fixing bundle executable issues..."
    
    # Extract IPA
    unzip -q "$ipa_path" -d "$temp_dir"
    
    # Look for app bundle
    local app_bundle=""
    for app in "$temp_dir/Payload"/*.app; do
        if [ -d "$app" ]; then
            app_bundle="$app"
            break
        fi
    done
    
    if [ -z "$app_bundle" ]; then
        log_error "No app bundle found in IPA"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Fix executable permissions
    local executable_name=$(plutil -extract CFBundleExecutable raw "$app_bundle/Info.plist" 2>/dev/null || echo "Runner")
    local executable_path="$app_bundle/$executable_name"
    
    if [ -f "$executable_path" ]; then
        chmod +x "$executable_path"
        log_info "Fixed main executable permissions: $executable_path"
    fi
    
    # Fix framework permissions
    local frameworks_dir="$app_bundle/Frameworks"
    if [ -d "$frameworks_dir" ]; then
        for framework in "$frameworks_dir"/*.framework; do
            if [ -d "$framework" ]; then
                local framework_name=$(basename "$framework" .framework)
                local framework_executable="$framework/$framework_name"
                
                if [ -f "$framework_executable" ]; then
                    chmod +x "$framework_executable"
                    log_info "Fixed framework executable permissions: $framework_executable"
                fi
            fi
        done
        
        # Fix dylib permissions
        for dylib in "$frameworks_dir"/*.dylib; do
            if [ -f "$dylib" ]; then
                chmod +x "$dylib"
                log_info "Fixed dylib permissions: $dylib"
            fi
        done
    fi
    
    # Recreate IPA
    cd "$temp_dir"
    zip -r "fixed.ipa" Payload/
    cd - > /dev/null
    
    # Replace original IPA
    mv "$temp_dir/fixed.ipa" "$ipa_path"
    
    # Clean up
    rm -rf "$temp_dir"
    
    log_success "Bundle executable fixes applied"
    return 0
}

# Main execution
if [ "$VALIDATE_IPA" = "--validate-ipa" ] && [ -n "$IPA_PATH" ]; then
    # Validate IPA
    if validate_ipa "$IPA_PATH"; then
        if analyze_ipa "$IPA_PATH"; then
            log_success "IPA validation completed successfully"
            exit 0
        else
            log_error "IPA analysis failed"
            exit 1
        fi
    else
        log_error "IPA validation failed"
        exit 1
    fi
else
    # Fix bundle executable issues
    if [ -n "$IPA_PATH" ]; then
        if fix_bundle_executable "$IPA_PATH"; then
            log_success "Bundle executable fix completed successfully"
            exit 0
        else
            log_error "Bundle executable fix failed"
            exit 1
        fi
    else
        log_error "IPA path is required"
        echo "Usage: $0 --validate-ipa <ipa_path>"
        echo "   or: $0 <ipa_path>"
        exit 1
    fi
fi 