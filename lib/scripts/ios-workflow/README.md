# 🍎 iOS Workflow Scripts

This directory contains all scripts required for the iOS build and deployment workflow in Codemagic.

## 📁 Scripts Overview

### Core Build Scripts

- **`build_ios.sh`** - Complete iOS build script with all features
- **`build_ios_simple.sh`** - Simplified iOS build script (recommended)
- **`validate_env.sh`** - Environment validation script

### Utility Scripts

- **`inject_info_plist.sh`** - Inject permissions into Info.plist
- **`comprehensive_build.sh`** - Advanced build with fallbacks
- **`improved_ipa_export.sh`** - Enhanced IPA export
- **`archive_structure_fix.sh`** - Fix archive structure issues
- **`enhanced_bundle_executable_fix.sh`** - Fix bundle executable issues
- **`fix_app_store_connect_issues.sh`** - Fix App Store Connect issues
- **`branding_assets.sh`** - Download and setup branding assets

## 🚀 Quick Start

### For Codemagic (Recommended)

The iOS workflow is configured in `codemagic.yaml` and uses the simplified build script:

```yaml
workflows:
  ios-workflow:
    scripts:
      - name: 🔍 Validate Environment
        script: ./lib/scripts/ios-workflow/validate_env.sh
      - name: 🚀 Single iOS Build Script
        script: ./lib/scripts/ios-workflow/build_ios_simple.sh
```

### Manual Usage

```bash
# Validate environment first
./lib/scripts/ios-workflow/validate_env.sh

# Run the simplified build
./lib/scripts/ios-workflow/build_ios_simple.sh

# Or run the full build with all features
./lib/scripts/ios-workflow/build_ios.sh
```

## 🔧 Required Environment Variables

### Critical Variables (Must be set)

```bash
BUNDLE_ID="com.yourcompany.yourapp"
APPLE_TEAM_ID="YOUR_TEAM_ID"
```

### Optional Variables

```bash
# App Configuration
APP_NAME="Your App Name"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
WORKFLOW_ID="ios-workflow"

# Code Signing
PROFILE_URL="https://example.com/profile.mobileprovision"
PROFILE_TYPE="app-store"

# TestFlight Upload
IS_TESTFLIGHT="true"
APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_API_KEY_ID"
APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
APP_STORE_CONNECT_API_KEY_URL="https://example.com/AuthKey.p8"

# Branding
LOGO_URL="https://example.com/logo.png"
SPLASH_URL="https://example.com/splash.png"
SPLASH_BG_COLOR="#FFFFFF"
SPLASH_TAGLINE="Your Tagline"
SPLASH_TAGLINE_COLOR="#000000"

# Email Notifications
ENABLE_EMAIL_NOTIFICATIONS="true"
EMAIL_ID="admin@example.com"
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT="587"
EMAIL_SMTP_USER="your-email@gmail.com"
EMAIL_SMTP_PASS="your-app-password"
```

## 🔍 Environment Validation

The `validate_env.sh` script performs comprehensive validation:

1. **Critical Variables Check** - Ensures BUNDLE_ID and APPLE_TEAM_ID are set
2. **URL Accessibility Test** - Tests all provided URLs for accessibility
3. **TestFlight Configuration** - Validates App Store Connect credentials
4. **Project Structure** - Checks for required files and directories

### Validation Output Example

```
🔍 Step 1: Validating Critical Environment Variables
================================================
✅ Found BUNDLE_ID: com.example.quikapp
✅ Found APPLE_TEAM_ID: ABC123DEF4
✅ Critical environment variables validated

🔍 Step 2: Validating Optional Environment Variables
================================================
✅ Found PROFILE_URL: https://example.com/profile.mobileprovision
⚠️ IS_TESTFLIGHT not set, using fallback: false

🔍 Step 3: Testing URL Accessibility
================================================
✅ URL accessible: provisioning profile
✅ URL accessible: app logo

🎉 Environment Validation Completed!
📱 App: QuikApp v1.0.0 (1)
🆔 Bundle ID: com.example.quikapp
👥 Team ID: ABC123DEF4
🚀 TestFlight: false
🔗 URLs Tested: 2
❌ URL Failures: 0
✅ All critical validations passed - ready for iOS build!
```

## 🏗️ Build Process

The simplified build script (`build_ios_simple.sh`) follows these steps:

1. **Environment Setup** - Set and validate environment variables
2. **Download Assets** - Download provisioning profiles and API keys
3. **Generate Config** - Generate env_config.dart
4. **Flutter Setup** - Clean and get dependencies
5. **iOS Setup** - Update Podfile and install CocoaPods
6. **Flutter Build** - Build without code signing
7. **Xcode Archive** - Create archive with code signing
8. **Export IPA** - Export signed IPA
9. **TestFlight Upload** - Upload to TestFlight (optional)
10. **Final Summary** - Display build results

## 🔧 Troubleshooting

### Common Issues

#### 1. Curl Download Failures

**Problem**: `curl: (3) bad range in URL position 7`

**Solution**: The script now uses improved error handling and retry logic. If downloads fail, the build continues with defaults.

#### 2. Missing Environment Variables

**Problem**: `BUNDLE_ID is required but not set`

**Solution**: Set the required environment variables in your Codemagic environment or as build variables.

#### 3. Code Signing Issues

**Problem**: `Code signing is required for product type`

**Solution**: Ensure `APPLE_TEAM_ID` is set and valid. The script uses automatic code signing.

#### 4. TestFlight Upload Failures

**Problem**: `altool: error: No API key was provided`

**Solution**: Set `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_API_KEY_URL`.

### Debug Mode

To enable verbose logging, set the environment variable:

```bash
export IOS_DEBUG="true"
```

This will provide detailed output for troubleshooting.

## 📦 Artifacts

The build process generates the following artifacts:

- **IPA File**: `build/export/Runner.ipa` (copied to `output/ios/`)
- **Archive**: `build/Runner.xcarchive`
- **Logs**: `build/ios/logs/`

## 🔄 Workflow Integration

### Codemagic YAML Configuration

The iOS workflow is configured in `codemagic.yaml`:

```yaml
ios-workflow:
  name: Build iOS App using Dynamic Config
  max_build_duration: 120
  environment:
    vars:
      # Core App Configuration
      WORKFLOW_ID: $WORKFLOW_ID
      APP_NAME: $APP_NAME
      BUNDLE_ID: $BUNDLE_ID
      APPLE_TEAM_ID: $APPLE_TEAM_ID
      # ... other variables
    xcode: latest
    cocoapods: default
    flutter: stable
    groups:
      - app_store_credentials
      - firebase_credentials
      - email_credentials
  scripts:
    - name: 🔍 Validate Environment
      script: ./lib/scripts/ios-workflow/validate_env.sh
    - name: 🚀 Single iOS Build Script
      script: ./lib/scripts/ios-workflow/build_ios_simple.sh
  artifacts:
    - build/export/*.ipa
    - output/ios/*.ipa
    - build/Runner.xcarchive
```

## 🛡️ Security Best Practices

1. **Never hardcode secrets** - Use environment variables
2. **Use Codemagic groups** - Store sensitive data in encrypted groups
3. **Validate URLs** - The validation script tests URL accessibility
4. **Secure file permissions** - API keys are set to 600 permissions
5. **Clean up sensitive files** - Temporary files are removed after use

## 📞 Support

For issues with the iOS workflow:

1. Check the validation output for specific errors
2. Review the build logs for detailed error messages
3. Ensure all required environment variables are set
4. Verify URL accessibility for external resources
5. Check Apple Developer account and provisioning profiles

## 🔄 Updates

To update the iOS workflow:

1. Modify the scripts in this directory
2. Test locally with the validation script
3. Update the `codemagic.yaml` if needed
4. Commit and push changes
5. Monitor the build in Codemagic

---

**Note**: All scripts use environment variables and never hardcode values. This ensures the workflow is portable and secure across different environments. 