# 🍎 New iOS Workflow - Comprehensive Guide

This document describes the new comprehensive iOS workflow script that handles all aspects of iOS app building, from asset downloads to IPA generation and email notifications.

## 🚀 Features

### ✅ **Complete Asset Management**
- Downloads app logo, splash images, and background images
- Handles Firebase configuration for push notifications
- Manages iOS certificates (P12 or CER+KEY)
- Downloads provisioning profiles

### ✅ **Dynamic Configuration**
- Configures app name and bundle ID
- Generates `env_config.dart` with all environment variables
- Injects permissions dynamically based on feature flags
- Handles Firebase setup for push notifications

### ✅ **Comprehensive Build Process**
- Flutter build without code signing
- Xcode archive with proper code signing
- IPA export with configurable options
- Multiple fallback strategies for reliability

### ✅ **Email Notifications**
- Build start notifications
- Build success notifications
- Detailed app information in emails
- Feature flags and permissions summary

## 📋 Required Environment Variables

### **Critical Variables (Must be set)**
```bash
BUNDLE_ID="com.yourcompany.yourapp"
APPLE_TEAM_ID="YOUR_TEAM_ID"
```

### **App Configuration**
```bash
WORKFLOW_ID="ios-workflow"
USER_NAME="your_name"
APP_ID="your_app_id"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
APP_NAME="Your App Name"
ORG_NAME="Your Organization"
WEB_URL="https://yourapp.com"
PKG_NAME="com.yourcompany.yourapp"
EMAIL_ID="admin@yourapp.com"
```

### **Feature Flags**
```bash
PUSH_NOTIFY="true"
IS_CHATBOT="true"
IS_DOMAIN_URL="true"
IS_SPLASH="true"
IS_PULLDOWN="true"
IS_BOTTOMMENU="true"
IS_LOAD_IND="true"
```

### **Permissions**
```bash
IS_CAMERA="false"
IS_LOCATION="false"
IS_MIC="true"
IS_NOTIFICATION="true"
IS_CONTACT="false"
IS_BIOMETRIC="false"
IS_CALENDAR="false"
IS_STORAGE="true"
```

### **Asset URLs**
```bash
LOGO_URL="https://example.com/logo.png"
SPLASH_URL="https://example.com/splash.png"
SPLASH_BG_URL="https://example.com/splash_bg.png"
SPLASH_BG_COLOR="#FFFFFF"
SPLASH_TAGLINE="Your Tagline"
SPLASH_TAGLINE_COLOR="#000000"
SPLASH_ANIMATION="fade"
SPLASH_DURATION="3"
```

### **Bottom Menu Configuration**
```bash
BOTTOMMENU_ITEMS="[{\"label\":\"Home\",\"icon\":{\"type\":\"preset\",\"name\":\"home_outlined\"},\"url\":\"https://yourapp.com/\"}]"
BOTTOMMENU_BG_COLOR="#FFFFFF"
BOTTOMMENU_ICON_COLOR="#000000"
BOTTOMMENU_TEXT_COLOR="#000000"
BOTTOMMENU_FONT="System"
BOTTOMMENU_FONT_SIZE="12"
BOTTOMMENU_FONT_BOLD="false"
BOTTOMMENU_FONT_ITALIC="false"
BOTTOMMENU_ACTIVE_TAB_COLOR="#007AFF"
BOTTOMMENU_ICON_POSITION="above"
```

### **iOS Certificates (Choose Option 1 OR Option 2)**

#### **Option 1: P12 Certificate**
```bash
CERT_P12_URL="https://example.com/Certificates.p12"
CERT_PASSWORD="your_password"
```

#### **Option 2: CER and KEY Files**
```bash
CERT_CER_URL="https://example.com/ios_distribution.cer"
CERT_KEY_URL="https://example.com/private.key"
CERT_PASSWORD="your_password"
```

### **Provisioning Profile**
```bash
PROFILE_URL="https://example.com/App_Store.mobileprovision"
PROFILE_TYPE="app-store"
```

### **Firebase Configuration**
```bash
FIREBASE_CONFIG_IOS="https://example.com/GoogleService-Info.plist"
APNS_KEY_ID="YOUR_APNS_KEY_ID"
APNS_AUTH_KEY_URL="https://example.com/AuthKey.p8"
```

### **Email Notifications**
```bash
ENABLE_EMAIL_NOTIFICATIONS="true"
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT="587"
EMAIL_SMTP_USER="your-email@gmail.com"
EMAIL_SMTP_PASS="your-app-password"
```

## 🔧 Build Process Steps

### **Step 1: Environment Setup and Validation**
- Validates critical environment variables
- Sets all required variables with fallbacks
- Ensures proper configuration

### **Step 2: Download Assets for Dart Codes**
- Downloads app logo (`LOGO_URL`)
- Downloads splash image (`SPLASH_URL`)
- Downloads splash background (`SPLASH_BG_URL`)
- Places files in correct paths for Dart code

### **Step 3: Download iOS Certificates and Files**
- Downloads Firebase config if `PUSH_NOTIFY=true`
- Downloads APNS auth key if provided
- Handles iOS certificates (P12 or CER+KEY)
- Downloads provisioning profile

### **Step 4: Configure App Name and Bundle ID**
- Updates app name in `Info.plist`
- Updates bundle identifier in `project.pbxproj`
- Ensures proper app identification

### **Step 5: Generate env_config.dart with cat EOF**
- Creates `lib/config/env_config.dart`
- Injects all environment variables
- Provides type-safe access to configuration

### **Step 6: Configure Firebase for iOS**
- Copies Firebase config to Runner directory
- Adds Firebase pods to Podfile
- Configures push notifications

### **Step 7: Inject Permissions Dynamically**
- Adds camera permission if `IS_CAMERA=true`
- Adds location permission if `IS_LOCATION=true`
- Adds microphone permission if `IS_MIC=true`
- Adds notification permission if `IS_NOTIFICATION=true`
- Adds contacts permission if `IS_CONTACT=true`
- Adds biometric permission if `IS_BIOMETRIC=true`
- Adds calendar permission if `IS_CALENDAR=true`
- Adds storage permission if `IS_STORAGE=true`

### **Step 8: Flutter Build without Code Signing**
- Cleans previous builds
- Gets Flutter dependencies
- Builds iOS app without code signing

### **Step 9: Build Xcode Archive with Code Signing**
- Installs CocoaPods dependencies
- Creates Xcode archive with proper code signing
- Uses automatic code signing with team ID

### **Step 10: Create Export Options and Export IPA**
- Creates `ExportOptions.plist` with proper configuration
- Exports IPA from archive
- Verifies IPA file creation

### **Step 11: Final Summary and Email Notification**
- Displays comprehensive build summary
- Sends success email notification
- Copies IPA to output directory

## 🛠️ Usage

### **For Codemagic**
The workflow is configured in `codemagic.yaml`:

```yaml
workflows:
  ios-workflow:
    scripts:
      - name: 🐛 Debug Environment
        script: ./lib/scripts/ios-workflow/debug_build.sh
      - name: 🔍 Validate Environment
        script: ./lib/scripts/ios-workflow/validate_env.sh
      - name: 🚀 New Comprehensive iOS Build Script
        script: ./lib/scripts/ios-workflow/new_ios_workflow.sh
```

### **Manual Usage**
```bash
# Make script executable
chmod +x lib/scripts/ios-workflow/new_ios_workflow.sh

# Run the comprehensive build
./lib/scripts/ios-workflow/new_ios_workflow.sh
```

## 📦 Artifacts

The build process generates:

- **IPA File**: `build/export/Runner.ipa` (copied to `output/ios/`)
- **Archive**: `build/Runner.xcarchive`
- **Logs**: `build/ios/logs/`
- **Generated Config**: `lib/config/env_config.dart`
- **Assets**: `assets/images/logo.png`, `assets/images/splash.png`

## 🔍 Error Handling

### **Robust Download System**
- Multiple retry methods for downloads
- Fallback strategies for failed downloads
- Graceful handling of missing assets

### **Build Resilience**
- Continues even if some steps fail
- Multiple fallback strategies for builds
- Detailed error logging and reporting

### **Email Notifications**
- Build start notifications
- Success notifications with app details
- No error emails (as per requirements)

## 🚀 Example Configuration

Here's a complete example configuration for `codemagic.yaml`:

```yaml
workflows:
  ios-workflow:
    name: Build iOS App using Dynamic Config
    max_build_duration: 120
    environment:
      vars:
        # Core App Configuration
        WORKFLOW_ID: $WORKFLOW_ID
        USER_NAME: $USER_NAME
        APP_ID: $APP_ID
        VERSION_NAME: $VERSION_NAME
        VERSION_CODE: $VERSION_CODE
        APP_NAME: $APP_NAME
        ORG_NAME: $ORG_NAME
        WEB_URL: $WEB_URL
        PKG_NAME: $PKG_NAME
        BUNDLE_ID: $BUNDLE_ID
        EMAIL_ID: $EMAIL_ID
        APPLE_TEAM_ID: $APPLE_TEAM_ID
        
        # Feature Flags
        PUSH_NOTIFY: $PUSH_NOTIFY
        IS_CHATBOT: $IS_CHATBOT
        IS_DOMAIN_URL: $IS_DOMAIN_URL
        IS_SPLASH: $IS_SPLASH
        IS_PULLDOWN: $IS_PULLDOWN
        IS_BOTTOMMENU: $IS_BOTTOMMENU
        IS_LOAD_IND: $IS_LOAD_IND
        
        # Permissions
        IS_CAMERA: $IS_CAMERA
        IS_LOCATION: $IS_LOCATION
        IS_MIC: $IS_MIC
        IS_NOTIFICATION: $IS_NOTIFICATION
        IS_CONTACT: $IS_CONTACT
        IS_BIOMETRIC: $IS_BIOMETRIC
        IS_CALENDAR: $IS_CALENDAR
        IS_STORAGE: $IS_STORAGE
        
        # Assets
        LOGO_URL: $LOGO_URL
        SPLASH_URL: $SPLASH_URL
        SPLASH_BG_URL: $SPLASH_BG_URL
        SPLASH_BG_COLOR: $SPLASH_BG_COLOR
        SPLASH_TAGLINE: $SPLASH_TAGLINE
        SPLASH_TAGLINE_COLOR: $SPLASH_TAGLINE_COLOR
        SPLASH_ANIMATION: $SPLASH_ANIMATION
        SPLASH_DURATION: $SPLASH_DURATION
        
        # Bottom Menu
        BOTTOMMENU_ITEMS: $BOTTOMMENU_ITEMS
        BOTTOMMENU_BG_COLOR: $BOTTOMMENU_BG_COLOR
        BOTTOMMENU_ICON_COLOR: $BOTTOMMENU_ICON_COLOR
        BOTTOMMENU_TEXT_COLOR: $BOTTOMMENU_TEXT_COLOR
        BOTTOMMENU_FONT: $BOTTOMMENU_FONT
        BOTTOMMENU_FONT_SIZE: $BOTTOMMENU_FONT_SIZE
        BOTTOMMENU_FONT_BOLD: $BOTTOMMENU_FONT_BOLD
        BOTTOMMENU_FONT_ITALIC: $BOTTOMMENU_FONT_ITALIC
        BOTTOMMENU_ACTIVE_TAB_COLOR: $BOTTOMMENU_ACTIVE_TAB_COLOR
        BOTTOMMENU_ICON_POSITION: $BOTTOMMENU_ICON_POSITION
        
        # Certificates
        PROFILE_TYPE: $PROFILE_TYPE
        PROFILE_URL: $PROFILE_URL
        CERT_PASSWORD: $CERT_PASSWORD
        CERT_P12_URL: $CERT_P12_URL
        CERT_CER_URL: $CERT_CER_URL
        CERT_KEY_URL: $CERT_KEY_URL
        
        # Firebase
        FIREBASE_CONFIG_IOS: $FIREBASE_CONFIG_IOS
        APNS_KEY_ID: $APNS_KEY_ID
        APNS_AUTH_KEY_URL: $APNS_AUTH_KEY_URL
        
        # Email
        ENABLE_EMAIL_NOTIFICATIONS: $ENABLE_EMAIL_NOTIFICATIONS
        EMAIL_SMTP_SERVER: $EMAIL_SMTP_SERVER
        EMAIL_SMTP_PORT: $EMAIL_SMTP_PORT
        EMAIL_SMTP_USER: $EMAIL_SMTP_USER
        EMAIL_SMTP_PASS: $EMAIL_SMTP_PASS
      xcode: latest
      cocoapods: default
      flutter: stable
      groups:
        - app_store_credentials
        - firebase_credentials
        - email_credentials
    scripts:
      - name: 🐛 Debug Environment
        script: ./lib/scripts/ios-workflow/debug_build.sh
      - name: 🔍 Validate Environment
        script: ./lib/scripts/ios-workflow/validate_env.sh
      - name: 🚀 New Comprehensive iOS Build Script
        script: ./lib/scripts/ios-workflow/new_ios_workflow.sh
    artifacts:
      - build/export/*.ipa
      - output/ios/*.ipa
      - build/Runner.xcarchive
      - lib/config/env_config.dart
      - flutter_drive.log
```

## 🎯 Benefits

1. **Complete Automation**: Handles all aspects of iOS building
2. **Dynamic Configuration**: No hardcoded values, everything from environment variables
3. **Robust Error Handling**: Multiple fallback strategies for reliability
4. **Comprehensive Logging**: Detailed progress tracking and debugging
5. **Email Notifications**: Build status updates with app information
6. **Flexible Certificate Management**: Supports both P12 and CER+KEY options
7. **Permission Management**: Dynamic permission injection based on features
8. **Firebase Integration**: Automatic Firebase setup for push notifications

## 🔄 Updates

To update the iOS workflow:

1. Modify the script in `lib/scripts/ios-workflow/new_ios_workflow.sh`
2. Test locally with the debug script
3. Update the `codemagic.yaml` if needed
4. Commit and push changes
5. Monitor the build in Codemagic

---

**Note**: This workflow follows all the requirements from the new iOS workflow specification, including no hardcoded variables, comprehensive asset management, dynamic configuration, and email notifications. 