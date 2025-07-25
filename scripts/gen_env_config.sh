#!/bin/bash
set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENV_GEN] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

log_info "Generating env_config.dart"

# Generate env_config.dart
cat > lib/config/env_config.dart << EOF
// 🔥 GENERATED FILE: DO NOT EDIT 🔥
//
// This file is generated by lib/scripts/utils/gen_env_config.sh
// It contains all environment-specific variables for the app.
// Generated for workflow: ${WORKFLOW_ID:-ios-workflow}

class EnvConfig {
  // App Metadata
  static const String appId = "${APP_ID:-}";
  static const String versionName = "${VERSION_NAME:-1.0.0}";
  static const int versionCode = ${VERSION_CODE:-1};
  static const String appName = "${APP_NAME:-}";
  static const String orgName = "${ORG_NAME:-}";
  static const String webUrl = "${WEB_URL:-}";
  static const String userName = "${USER_NAME:-}";
  static const String emailId = "${EMAIL_ID:-}";
  static const String branch = "${BRANCH:-main}";
  static const String workflowId = "${WORKFLOW_ID:-}";

  // Package Identifiers
  static const String pkgName = "${PKG_NAME:-}";
  static const String bundleId = "${BUNDLE_ID:-}";

  // Feature Flags (converted to bool)
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-false};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottommenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadIndicator = ${IS_LOAD_IND:-false};

  // Permissions (converted to bool)
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};
  static const bool isStorage = ${IS_STORAGE:-false};

  // UI/Branding
  static const String logoUrl = "${LOGO_URL:-}";
  static const String splashUrl = "${SPLASH_URL:-}";
  static const String splashBg = "${SPLASH_BG:-}";
  static const String splashBgColor = "${SPLASH_BG_COLOR:-}";
  static const String splashTagline = "${SPLASH_TAGLINE:-}";
  static const String splashTaglineColor = "${SPLASH_TAGLINE_COLOR:-}";
  static const String splashBgUrl = "${SPLASH_BG_URL:-}";
  static const String splashAnimation = "${SPLASH_ANIMATION:-}";
  static const int splashDuration = ${SPLASH_DURATION:-3};
  
  // Bottom Menu Configuration
  static const String bottommenuItems = r'${BOTTOMMENU_ITEMS:-[]}';
  static const String bottommenuBgColor = "${BOTTOMMENU_BG_COLOR:-}";
  static const String bottommenuIconColor = "${BOTTOMMENU_ICON_COLOR:-}";
  static const String bottommenuTextColor = "${BOTTOMMENU_TEXT_COLOR:-}";
  static const String bottommenuFont = "${BOTTOMMENU_FONT:-}";
  static const double bottommenuFontSize = ${BOTTOMMENU_FONT_SIZE:-12.0};
  static const bool bottommenuFontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool bottommenuFontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
  static const String bottommenuActiveTabColor = "${BOTTOMMENU_ACTIVE_TAB_COLOR:-}";
  static const String bottommenuIconPosition = "${BOTTOMMENU_ICON_POSITION:-}";
  
  // Firebase Configuration
  static const String firebaseConfigIos = "${FIREBASE_CONFIG_IOS:-}";
  static const String firebaseConfigAndroid = "${FIREBASE_CONFIG_ANDROID:-}";
  
  // iOS Signing
  static const String appleTeamId = "${APPLE_TEAM_ID:-}";
  static const String profileType = "${PROFILE_TYPE:-}";
  static const bool isTestflight = ${IS_TESTFLIGHT:-false};
  
  // Email Configuration
  static const bool enableEmailNotifications = ${ENABLE_EMAIL_NOTIFICATIONS:-false};
  static const String emailSmtpServer = "${EMAIL_SMTP_SERVER:-}";
  static const int emailSmtpPort = ${EMAIL_SMTP_PORT:-587};
  static const String emailSmtpUser = "${EMAIL_SMTP_USER:-}";
  static const String emailSmtpPass = "${EMAIL_SMTP_PASS:-}";
  
  // APNS Configuration
  static const String apnsKeyId = "${APNS_KEY_ID:-}";
  static const String apnsAuthKeyUrl = "${APNS_AUTH_KEY_URL:-}";
  
  // Android Keystore
  static const String keyStoreUrl = "${KEY_STORE_URL:-}";
  static const String cmKeystorePassword = "${CM_KEYSTORE_PASSWORD:-}";
  static const String cmKeyAlias = "${CM_KEY_ALIAS:-}";
  static const String cmKeyPassword = "${CM_KEY_PASSWORD:-}";
  
  // App Store Connect
  static const String appStoreConnectKeyIdentifier = "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}";
  static const String appStoreConnectIssuerId = "${APP_STORE_CONNECT_ISSUER_ID:-}";
  static const String appStoreConnectApiKeyUrl = "${APP_STORE_CONNECT_API_KEY_URL:-}";
  
  // Workflow
  static const String workflowId = "${WORKFLOW_ID:-ios-workflow}";

  // Build Environment
  static const String buildId = "${CM_BUILD_ID:-unknown}";
  static const String buildDir = "${CM_BUILD_DIR:-}";
  static const String projectRoot = "${PROJECT_ROOT:-}";
  static const String outputDir = "${OUTPUT_DIR:-output/ios}";

  // Utility Methods
  static bool get isAndroidBuild => workflowId.startsWith('android');
  static bool get isIosBuild => workflowId.contains('ios');
  static bool get isCombinedBuild => workflowId == 'combined';
  static bool get hasFirebase => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
  static bool get hasKeystore => keyStoreUrl.isNotEmpty;
  static bool get hasIosSigning => appleTeamId.isNotEmpty && profileType.isNotEmpty;
}
EOF

log_success "✅ Generated env_config.dart"

# Generate exportOptions.plist for iOS
log_info "Generating exportOptions.plist"
cat > scripts/exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$PROFILE_TYPE</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>$APP_NAME</string>
    </dict>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

log_success "✅ Generated exportOptions.plist"

# Generate environment.g.dart for Flutter
log_info "Generating environment.g.dart"
cat > lib/config/environment.g.dart << EOF
// Generated by gen_env_config.sh
// Do not edit manually

class Environment {
  static const String appName = "$APP_NAME";
  static const String bundleId = "$BUNDLE_ID";
  static const String versionName = "$VERSION_NAME";
  static const String versionCode = "$VERSION_CODE";
  static const String appId = "$APP_ID";
  static const String orgName = "$ORG_NAME";
  static const String webUrl = "$WEB_URL";
  static const String pkgName = "$PKG_NAME";
  static const String userName = "$USER_NAME";
  static const String emailId = "$EMAIL_ID";
  static const String workflowId = "$WORKFLOW_ID";
}
EOF

log_success "✅ Generated environment.g.dart"

# Generate .env file for local development
log_info "Generating .env file"
cat > .env << EOF
# App Configuration
APP_NAME=$APP_NAME
BUNDLE_ID=$BUNDLE_ID
VERSION_NAME=$VERSION_NAME
VERSION_CODE=$VERSION_CODE
APP_ID=$APP_ID
ORG_NAME=$ORG_NAME
WEB_URL=$WEB_URL
PKG_NAME=$PKG_NAME

# User Configuration
USER_NAME=$USER_NAME
EMAIL_ID=$EMAIL_ID

# Feature Flags
PUSH_NOTIFY=$PUSH_NOTIFY
IS_CHATBOT=$IS_CHATBOT
IS_DOMAIN_URL=$IS_DOMAIN_URL
IS_SPLASH=$IS_SPLASH
IS_PULLDOWN=$IS_PULLDOWN
IS_BOTTOMMENU=$IS_BOTTOMMENU
IS_LOAD_IND=$IS_LOAD_IND

# Permissions
IS_CAMERA=$IS_CAMERA
IS_LOCATION=$IS_LOCATION
IS_MIC=$IS_MIC
IS_NOTIFICATION=$IS_NOTIFICATION
IS_CONTACT=$IS_CONTACT
IS_BIOMETRIC=$IS_BIOMETRIC
IS_CALENDAR=$IS_CALENDAR
IS_STORAGE=$IS_STORAGE

# UI Configuration
LOGO_URL=$LOGO_URL
SPLASH_URL=$SPLASH_URL
SPLASH_BG_COLOR=$SPLASH_BG_COLOR
SPLASH_TAGLINE=$SPLASH_TAGLINE
SPLASH_TAGLINE_COLOR=$SPLASH_TAGLINE_COLOR
SPLASH_BG_URL=$SPLASH_BG_URL
SPLASH_ANIMATION=$SPLASH_ANIMATION
SPLASH_DURATION=$SPLASH_DURATION

# Bottom Menu Configuration
BOTTOMMENU_ITEMS=$BOTTOMMENU_ITEMS
BOTTOMMENU_BG_COLOR=$BOTTOMMENU_BG_COLOR
BOTTOMMENU_ICON_COLOR=$BOTTOMMENU_ICON_COLOR
BOTTOMMENU_TEXT_COLOR=$BOTTOMMENU_TEXT_COLOR
BOTTOMMENU_FONT=$BOTTOMMENU_FONT
BOTTOMMENU_FONT_SIZE=$BOTTOMMENU_FONT_SIZE
BOTTOMMENU_FONT_BOLD=$BOTTOMMENU_FONT_BOLD
BOTTOMMENU_FONT_ITALIC=$BOTTOMMENU_FONT_ITALIC
BOTTOMMENU_ACTIVE_TAB_COLOR=$BOTTOMMENU_ACTIVE_TAB_COLOR
BOTTOMMENU_ICON_POSITION=$BOTTOMMENU_ICON_POSITION

# Firebase Configuration
FIREBASE_CONFIG_IOS=$FIREBASE_CONFIG_IOS
FIREBASE_CONFIG_ANDROID=$FIREBASE_CONFIG_ANDROID

# iOS Signing
APPLE_TEAM_ID=$APPLE_TEAM_ID
PROFILE_TYPE=$PROFILE_TYPE
IS_TESTFLIGHT=$IS_TESTFLIGHT

# Email Configuration
ENABLE_EMAIL_NOTIFICATIONS=$ENABLE_EMAIL_NOTIFICATIONS
EMAIL_SMTP_SERVER=$EMAIL_SMTP_SERVER
EMAIL_SMTP_PORT=$EMAIL_SMTP_PORT
EMAIL_SMTP_USER=$EMAIL_SMTP_USER
EMAIL_SMTP_PASS=$EMAIL_SMTP_PASS

# APNS Configuration
APNS_KEY_ID=$APNS_KEY_ID
APNS_AUTH_KEY_URL=$APNS_AUTH_KEY_URL

# Android Keystore
KEY_STORE_URL=$KEY_STORE_URL
CM_KEYSTORE_PASSWORD=$CM_KEYSTORE_PASSWORD
CM_KEY_ALIAS=$CM_KEY_ALIAS
CM_KEY_PASSWORD=$CM_KEY_PASSWORD

# App Store Connect
APP_STORE_CONNECT_KEY_IDENTIFIER=$APP_STORE_CONNECT_KEY_IDENTIFIER
APP_STORE_CONNECT_ISSUER_ID=$APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_URL=$APP_STORE_CONNECT_API_KEY_URL

# Workflow
WORKFLOW_ID=$WORKFLOW_ID
EOF

log_success "✅ Generated .env file"

log_success "✅ Environment configuration generation completed successfully"
exit 0 