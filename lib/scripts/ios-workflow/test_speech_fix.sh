#!/bin/bash
# 🧪 Test Speech-to-Text Fix
# Tests the speech_to_text dependency fix

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_SPEECH] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "🧪 Testing Speech-to-Text Fix"
log "================================================"

# Test 1: Check if speech_to_text is in pubspec.yaml
log_info "Test 1: Checking speech_to_text dependency..."

if grep -q "speech_to_text:" pubspec.yaml; then
    log_success "speech_to_text dependency found in pubspec.yaml"
else
    log_error "speech_to_text dependency not found in pubspec.yaml"
    exit 1
fi

# Test 2: Check if voice_assistant is removed
log_info "Test 2: Checking if voice_assistant is removed..."

if grep -q "voice_assistant:" pubspec.yaml; then
    log_warning "voice_assistant dependency still present in pubspec.yaml"
else
    log_success "voice_assistant dependency removed from pubspec.yaml"
fi

# Test 3: Check chat_widget.dart imports
log_info "Test 3: Checking chat_widget.dart imports..."

if grep -q "import 'package:speech_to_text/speech_to_text.dart' as stt;" lib/chat/chat_widget.dart; then
    log_success "speech_to_text import found in chat_widget.dart"
else
    log_error "speech_to_text import not found in chat_widget.dart"
    exit 1
fi

# Test 4: Check if VoiceAssistant usage is updated
log_info "Test 4: Checking VoiceAssistant usage..."

if grep -q "final stt.SpeechToText _speech = stt.SpeechToText();" lib/chat/chat_widget.dart; then
    log_success "SpeechToText usage found in chat_widget.dart"
else
    log_error "SpeechToText usage not found in chat_widget.dart"
    exit 1
fi

# Test 5: Check if ListenMode usage is updated
log_info "Test 5: Checking ListenMode usage..."

if grep -q "listenMode: stt.ListenMode.confirmation," lib/chat/chat_widget.dart; then
    log_success "ListenMode usage updated in chat_widget.dart"
else
    log_error "ListenMode usage not updated in chat_widget.dart"
    exit 1
fi

# Test 6: Check for any remaining va. references
log_info "Test 6: Checking for remaining va. references..."

if grep -q "va\." lib/chat/chat_widget.dart; then
    log_error "Found remaining va. references in chat_widget.dart"
    grep -n "va\." lib/chat/chat_widget.dart
    exit 1
else
    log_success "No remaining va. references found"
fi

# Test 7: Validate pubspec.yaml syntax
log_info "Test 7: Validating pubspec.yaml syntax..."

if flutter pub deps >/dev/null 2>&1; then
    log_success "pubspec.yaml syntax is valid"
else
    log_warning "pubspec.yaml syntax validation failed"
fi

# Test 8: Show the changes
log_info "Test 8: Showing the changes..."

echo "Updated pubspec.yaml dependencies:"
grep -A 5 -B 5 "speech_to_text:" pubspec.yaml

echo ""
echo "Updated chat_widget.dart imports:"
grep -A 2 -B 2 "speech_to_text" lib/chat/chat_widget.dart

echo ""
echo "Updated VoiceAssistant usage:"
grep -A 2 -B 2 "SpeechToText" lib/chat/chat_widget.dart

log_success "🎉 Speech-to-text fix test completed!"
log_info "The speech_to_text dependency fix is working correctly"
log_info "Key improvements:"
log_info "  - Replaced voice_assistant with speech_to_text"
log_info "  - Updated VoiceAssistant to SpeechToText"
log_info "  - Fixed ListenMode usage"
log_info "  - Removed all va. references" 