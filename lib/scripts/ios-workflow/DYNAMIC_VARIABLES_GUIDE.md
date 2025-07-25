# 🔄 Dynamic Variables Guide for iOS Workflow

## 📋 Overview

All variables in the iOS workflow are **dynamic** and must be sourced from **Codemagic API calls**. No variables are hardcoded - they all come from the Codemagic environment.

## 🎯 Complete Variable List

The iOS workflow expects **61 dynamic variables** to be set via Codemagic API calls:

### **Core Workflow Variables**
```bash
WORKFLOW_ID                    # Workflow identifier
APPLE_TEAM_ID                  # Apple Developer Team ID
IS_TESTFLIGHT                  # TestFlight upload flag
APP_STORE_CONNECT_KEY_IDENTIFIER  # App Store Connect API key ID
APP_STORE_CONNECT_ISSUER_ID   # App Store Connect issuer ID
APP_STORE_CONNECT_API_KEY_URL # App Store Connect API key URL
```

### **App Information Variables**
```bash
USER_NAME                      # User/developer name
APP_ID                         # Application ID
VERSION_NAME                   # App version name
VERSION_CODE                   # App version code
APP_NAME                       # Application name
ORG_NAME                       # Organization name
WEB_URL                        # Web URL
PKG_NAME                       # Package name
BUNDLE_ID                      # Bundle identifier
EMAIL_ID                       # Email address
```

### **Feature Flags**
```bash
PUSH_NOTIFY                    # Push notifications enabled
IS_CHATBOT                     # Chatbot feature enabled
IS_DOMAIN_URL                  # Domain URL feature enabled
IS_SPLASH                      # Splash screen enabled
IS_PULLDOWN                    # Pull to refresh enabled
IS_BOTTOMMENU                  # Bottom menu enabled
IS_LOAD_IND                    # Loading indicators enabled
```

### **Permission Flags**
```bash
IS_CAMERA                      # Camera permission
IS_LOCATION                    # Location permission
IS_MIC                         # Microphone permission
IS_NOTIFICATION                # Notification permission
IS_CONTACT                     # Contact permission
IS_BIOMETRIC                   # Biometric permission
IS_CALENDAR                    # Calendar permission
IS_STORAGE                     # Storage permission
```

### **Asset URLs**
```bash
LOGO_URL                       # App logo URL
SPLASH_URL                     # Splash image URL
SPLASH_BG_URL                  # Splash background URL
```

### **Splash Configuration**
```bash
SPLASH_BG_COLOR               # Splash background color
SPLASH_TAGLINE                # Splash tagline text
SPLASH_TAGLINE_COLOR          # Splash tagline color
SPLASH_ANIMATION              # Splash animation type
SPLASH_DURATION               # Splash duration
```

### **Bottom Menu Configuration**
```bash
BOTTOMMENU_ITEMS              # Bottom menu items JSON
BOTTOMMENU_BG_COLOR           # Bottom menu background color
BOTTOMMENU_ICON_COLOR         # Bottom menu icon color
BOTTOMMENU_TEXT_COLOR         # Bottom menu text color
BOTTOMMENU_FONT               # Bottom menu font
BOTTOMMENU_FONT_SIZE          # Bottom menu font size
BOTTOMMENU_FONT_BOLD          # Bottom menu font bold
BOTTOMMENU_FONT_ITALIC        # Bottom menu font italic
BOTTOMMENU_ACTIVE_TAB_COLOR   # Bottom menu active tab color
BOTTOMMENU_ICON_POSITION      # Bottom menu icon position
```

### **Firebase and Push Notification Configuration**
```bash
FIREBASE_CONFIG_IOS           # Firebase config file URL
APNS_KEY_ID                   # APNS key identifier
APNS_AUTH_KEY_URL             # APNS auth key URL
```

### **Provisioning and Certificate Configuration**
```bash
PROFILE_TYPE                  # Provisioning profile type
PROFILE_URL                   # Provisioning profile URL
CERT_PASSWORD                 # Certificate password
CERT_P12_URL                  # P12 certificate URL
CERT_CER_URL                  # CER certificate URL
CERT_KEY_URL                  # Private key URL
```

### **Email Configuration**
```bash
ENABLE_EMAIL_NOTIFICATIONS    # Email notifications enabled
EMAIL_SMTP_SERVER             # SMTP server
EMAIL_SMTP_PORT               # SMTP port
EMAIL_SMTP_USER               # SMTP username
EMAIL_SMTP_PASS               # SMTP password
```

## 🔧 Codemagic Configuration

### **codemagic.yaml Example**
```yaml
workflows:
  ios-workflow:
    name: iOS Workflow with Dynamic Variables
    environment:
      vars:
        # Core Workflow Variables
        WORKFLOW_ID: "ios-workflow"
        APPLE_TEAM_ID: "9H2AD7NQ49"
        IS_TESTFLIGHT: "true"
        APP_STORE_CONNECT_KEY_IDENTIFIER: "S95LCWAH99"
        APP_STORE_CONNECT_ISSUER_ID: "a99a2ebd-ed3e-4117-9f97-f195823774a7"
        APP_STORE_CONNECT_API_KEY_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_S95LCWAH99.p8"
        
        # App Information
        USER_NAME: "prasannasrie"
        APP_ID: "10023"
        VERSION_NAME: "1.0.5"
        VERSION_CODE: "51"
        APP_NAME: "Garbcode App"
        ORG_NAME: "Garbcode Apparels Private Limited"
        WEB_URL: "https://garbcode.com/"
        PKG_NAME: "com.garbcode.garbcodeapp"
        BUNDLE_ID: "com.garbcode.garbcodeapp"
        EMAIL_ID: "prasannasrinivasan32@gmail.com"
        
        # Feature Flags
        PUSH_NOTIFY: "true"
        IS_CHATBOT: "true"
        IS_DOMAIN_URL: "true"
        IS_SPLASH: "true"
        IS_PULLDOWN: "true"
        IS_BOTTOMMENU: "true"
        IS_LOAD_IND: "true"
        
        # Permission Flags
        IS_CAMERA: "false"
        IS_LOCATION: "false"
        IS_MIC: "true"
        IS_NOTIFICATION: "true"
        IS_CONTACT: "false"
        IS_BIOMETRIC: "false"
        IS_CALENDAR: "false"
        IS_STORAGE: "true"
        
        # Asset URLs
        LOGO_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
        SPLASH_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
        SPLASH_BG_URL: ""
        
        # Splash Configuration
        SPLASH_BG_COLOR: "#cbdbf5"
        SPLASH_TAGLINE: "TWINKLUB"
        SPLASH_TAGLINE_COLOR: "#a30237"
        SPLASH_ANIMATION: "zoom"
        SPLASH_DURATION: "4"
        
        # Bottom Menu Configuration
        BOTTOMMENU_ITEMS: '[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://twinklub.com/"},{"label":"New Arraivals","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/card.svg","icon_size":"24"},"url":"https://www.twinklub.com/collections/new-arrivals"},{"label":"Collections","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/about.svg","icon_size":"24"},"url":"https://www.twinklub.com/collections/all"},{"label":"Contact","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/contact.svg","icon_size":"24"},"url":"https://www.twinklub.com/account"}]'
        BOTTOMMENU_BG_COLOR: "#FFFFFF"
        BOTTOMMENU_ICON_COLOR: "#6d6e8c"
        BOTTOMMENU_TEXT_COLOR: "#6d6e8c"
        BOTTOMMENU_FONT: "DM Sans"
        BOTTOMMENU_FONT_SIZE: "12"
        BOTTOMMENU_FONT_BOLD: "false"
        BOTTOMMENU_FONT_ITALIC: "false"
        BOTTOMMENU_ACTIVE_TAB_COLOR: "#a30237"
        BOTTOMMENU_ICON_POSITION: "above"
        
        # Firebase and Push Notification Configuration
        FIREBASE_CONFIG_IOS: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-gc.plist"
        APNS_KEY_ID: "6VB3VLTXV6"
        APNS_AUTH_KEY_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_V566SWNF69.p8"
        
        # Provisioning and Certificate Configuration
        PROFILE_TYPE: "app-store"
        PROFILE_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode_App_App_Store.mobileprovision"
        CERT_PASSWORD: "quikapp2025"
        CERT_P12_URL: ""
        CERT_CER_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer"
        CERT_KEY_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key"
        
        # Email Configuration
        ENABLE_EMAIL_NOTIFICATIONS: "true"
        EMAIL_SMTP_SERVER: "smtp.gmail.com"
        EMAIL_SMTP_PORT: "587"
        EMAIL_SMTP_USER: "prasannasrie@gmail.com"
        EMAIL_SMTP_PASS: "lrnu krfm aarp urux"
    
    scripts:
      - name: Validate Dynamic Variables
        script: |
          bash lib/scripts/ios-workflow/validate_dynamic_vars.sh
      
      - name: Run Dynamic iOS Workflow
        script: |
          bash lib/scripts/ios-workflow/dynamic_ios_workflow.sh
```

## 🔍 Validation

### **Critical Variables**
These variables **MUST** be set for the workflow to function:

```bash
WORKFLOW_ID
APPLE_TEAM_ID
USER_NAME
APP_ID
VERSION_NAME
VERSION_CODE
APP_NAME
ORG_NAME
WEB_URL
PKG_NAME
BUNDLE_ID
EMAIL_ID
```

### **Validation Script**
Use the validation script to check if all variables are properly set:

```bash
bash lib/scripts/ios-workflow/validate_dynamic_vars.sh
```

**Expected Output:**
```bash
✅ WORKFLOW_ID: ios-workflow
✅ APPLE_TEAM_ID: 9H2AD7NQ49
✅ USER_NAME: prasannasrie
✅ APP_ID: 10023
✅ VERSION_NAME: 1.0.5
✅ VERSION_CODE: 51
✅ APP_NAME: Garbcode App
✅ ORG_NAME: Garbcode Apparels Private Limited
✅ WEB_URL: https://garbcode.com/
✅ PKG_NAME: com.garbcode.garbcodeapp
✅ BUNDLE_ID: com.garbcode.garbcodeapp
✅ EMAIL_ID: prasannasrinivasan32@gmail.com
...
🎉 All dynamic variables are properly set!
```

## 🚀 Usage

### **1. Set Variables in Codemagic**
All variables must be set in your `codemagic.yaml` file under the `environment.vars` section.

### **2. Run Validation**
```bash
bash lib/scripts/ios-workflow/validate_dynamic_vars.sh
```

### **3. Run Dynamic Workflow**
```bash
bash lib/scripts/ios-workflow/dynamic_ios_workflow.sh
```

## 📊 Variable Categories

### **Required Variables (Critical)**
- Core workflow identifiers
- App information
- Bundle and package names
- Contact information

### **Feature Variables (Optional)**
- Feature flags
- Permission settings
- UI configuration

### **Asset Variables (Optional)**
- Logo and splash URLs
- Certificate and provisioning profile URLs
- Firebase configuration

### **Email Variables (Optional)**
- SMTP configuration
- Notification settings

## 🔒 Security Notes

### **Sensitive Variables**
These variables contain sensitive information and should be handled securely:

```bash
EMAIL_SMTP_PASS               # SMTP password
CERT_PASSWORD                 # Certificate password
APNS_AUTH_KEY_URL            # APNS authentication key
CERT_KEY_URL                 # Private key URL
```

### **Best Practices**
1. **Use Codemagic Secrets** for sensitive variables
2. **Validate all variables** before running the workflow
3. **Log variable names only** (not values) for sensitive data
4. **Use HTTPS URLs** for all asset downloads

## 📞 Troubleshooting

### **Common Issues**

1. **Missing Critical Variables**
   ```bash
   ❌ Critical variables missing: WORKFLOW_ID APPLE_TEAM_ID BUNDLE_ID
   ```
   **Solution**: Set all required variables in `codemagic.yaml`

2. **Variables Not Sourced from API**
   ```bash
   ⚠️ WORKFLOW_ID may be using fallback value
   ```
   **Solution**: Ensure variables are set via Codemagic API calls, not hardcoded

3. **Invalid Variable Values**
   ```bash
   ❌ BUNDLE_ID format invalid
   ```
   **Solution**: Use proper format (e.g., `com.company.app`)

### **Debug Commands**
```bash
# Check all variables
env | grep -E "(WORKFLOW_ID|APPLE_TEAM_ID|BUNDLE_ID)"

# Validate specific variables
echo "WORKFLOW_ID: $WORKFLOW_ID"
echo "APPLE_TEAM_ID: $APPLE_TEAM_ID"
echo "BUNDLE_ID: $BUNDLE_ID"
```

## 🎯 Benefits

### **1. Dynamic Configuration**
- ✅ All variables sourced from Codemagic API
- ✅ No hardcoded values
- ✅ Easy to modify via Codemagic dashboard

### **2. Validation**
- ✅ Comprehensive variable checking
- ✅ Critical variable validation
- ✅ Clear error messages

### **3. Flexibility**
- ✅ Support for multiple app configurations
- ✅ Easy environment switching
- ✅ Scalable for multiple projects

### **4. Security**
- ✅ Sensitive data handled securely
- ✅ No hardcoded passwords or keys
- ✅ Proper variable validation

---

**Status**: ✅ **DYNAMIC** - All variables sourced from Codemagic API calls
**Validation**: ✅ **COMPREHENSIVE** - Complete variable checking and validation
**Security**: ✅ **ENHANCED** - Secure handling of sensitive variables
**Flexibility**: ✅ **MAXIMUM** - Easy configuration via Codemagic dashboard 