#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BRANDING] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BRANDING] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BRANDING] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BRANDING] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BRANDING] ❌ $1"; }

log "🎨 Starting branding assets download"

# Create assets directory
mkdir -p assets/images

# Download logo if URL is provided
if [ -n "${LOGO_URL:-}" ]; then
    log_info "📥 Downloading logo from: $LOGO_URL"
    if curl -L -o "assets/images/logo.png" "$LOGO_URL" 2>/dev/null; then
        log_success "Logo downloaded successfully"
    else
        log_warning "Failed to download logo from $LOGO_URL"
    fi
else
    log_info "No logo URL provided, skipping logo download"
fi

# Download splash if URL is provided
if [ -n "${SPLASH_URL:-}" ]; then
    log_info "📥 Downloading splash from: $SPLASH_URL"
    if curl -L -o "assets/images/splash.png" "$SPLASH_URL" 2>/dev/null; then
        log_success "Splash downloaded successfully"
    else
        log_warning "Failed to download splash from $SPLASH_URL"
    fi
else
    log_info "No splash URL provided, skipping splash download"
fi

# Download splash background if URL is provided
if [ -n "${SPLASH_BG_URL:-}" ]; then
    log_info "📥 Downloading splash background from: $SPLASH_BG_URL"
    if curl -L -o "assets/images/splash_bg.png" "$SPLASH_BG_URL" 2>/dev/null; then
        log_success "Splash background downloaded successfully"
    else
        log_warning "Failed to download splash background from $SPLASH_BG_URL"
    fi
else
    log_info "No splash background URL provided, skipping download"
fi

log_success "Branding assets download completed"
exit 0 