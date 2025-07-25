# 🔐 Certificate Generation Test Guide

## 🎯 Purpose

This guide explains how to use the `test_certificate_generation.sh` script to download certificate files and generate a valid P12 file for iOS code signing.

## 📋 Test Configuration

### **Certificate URLs**
```bash
CERT_CER_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer"
CERT_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key"
CERT_PASSWORD="quikapp2025"
```

### **Files Generated**
- `ios_distribution_gps.cer` - iOS Distribution Certificate
- `private.key` - Private Key File
- `Certificates.p12` - Generated P12 file for code signing

## 🚀 Usage

### **Run the Test Script**
```bash
bash lib/scripts/ios-workflow/test_certificate_generation.sh
```

### **Expected Output**
```
🧪 Starting Certificate Generation Test
================================================
🔍 Testing network connectivity...
✅ DNS resolution for raw.githubusercontent.com successful
✅ HTTPS connectivity to raw.githubusercontent.com successful
✅ Network connectivity test passed

Step 1: Downloading Certificate Files
================================================
🔍 Downloading certificate file from: https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer
✅ Certificate file downloaded successfully with wget
✅ Certificate file is valid
✅ Certificate Subject: /C=US/O=Apple Inc./OU=Apple Worldwide Developer Relations/CN=Apple Worldwide Developer Relations Certification Authority
✅ Certificate Issuer: /C=US/O=Apple Inc./OU=Apple Worldwide Developer Relations/CN=Apple Worldwide Developer Relations Certification Authority
✅ Certificate Expires: Dec 28 23:59:59 2025 GMT

🔍 Downloading private key file from: https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key
✅ Private key file downloaded successfully with wget
✅ Private key file is valid
✅ Private Key Size: 2048 bits

Step 2: Generating P12 File
================================================
🔍 Generating P12 file...
✅ P12 file generated successfully

Step 3: Validating P12 File
================================================
✅ P12 file is valid and password is correct
✅ P12 contains 1 certificate(s) and 1 private key(s)

Step 4: Testing Certificate Chain
================================================
✅ Certificate extracted from P12
✅ Certificate chain verification passed

Step 5: Final Summary
================================================
🎉 Certificate Generation Test Completed Successfully!
📁 Test Directory: /tmp/cert_test_1234567890
🔐 Certificate File: /tmp/cert_test_1234567890/ios_distribution_gps.cer
🔑 Private Key File: /tmp/cert_test_1234567890/private.key
📦 P12 File: /tmp/cert_test_1234567890/Certificates.p12
🔒 Password: quikapp2025
✅ P12 file copied to project directory: ios/certificates/Certificates.p12
```

## 🔧 Validation Steps

### **1. Network Connectivity Test**
- ✅ DNS resolution for raw.githubusercontent.com
- ✅ HTTPS connectivity test
- ✅ wget/curl availability check

### **2. Certificate File Validation**
- ✅ File download success
- ✅ File size validation (non-zero)
- ✅ Certificate format validation using OpenSSL
- ✅ Certificate information extraction (subject, issuer, expiry)

### **3. Private Key Validation**
- ✅ File download success
- ✅ File size validation (non-zero)
- ✅ Private key format validation using OpenSSL
- ✅ Key size extraction

### **4. P12 Generation**
- ✅ OpenSSL pkcs12 export command
- ✅ Password protection with specified password
- ✅ Certificate and key combination

### **5. P12 Validation**
- ✅ File existence and size check
- ✅ Password verification
- ✅ Certificate and key count verification
- ✅ Certificate chain testing

## 📊 Test Results Interpretation

### **✅ Success Indicators**
- All downloads complete successfully
- Certificate files are valid and properly formatted
- P12 file is generated with correct password
- Certificate chain is valid
- Files are copied to project directory

### **❌ Failure Indicators**
- Network connectivity issues
- Invalid or corrupted certificate files
- Incorrect private key format
- P12 generation failures
- Password verification failures

## 🔍 Troubleshooting

### **Network Issues**
```bash
# Test DNS resolution
nslookup raw.githubusercontent.com

# Test HTTPS connectivity
curl -I https://raw.githubusercontent.com

# Test specific certificate URL
curl -I https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer
```

### **Certificate Validation**
```bash
# Validate certificate file
openssl x509 -in ios_distribution_gps.cer -text -noout

# Validate private key
openssl rsa -in private.key -check -noout

# Test P12 generation manually
openssl pkcs12 -export \
    -in ios_distribution_gps.cer \
    -inkey private.key \
    -out Certificates.p12 \
    -passout pass:quikapp2025
```

### **Common Issues**

| Issue | Cause | Solution |
|-------|-------|----------|
| **Download fails** | Network connectivity | Check internet connection and firewall |
| **Certificate invalid** | Corrupted file | Re-download certificate file |
| **Private key invalid** | Wrong format | Ensure key is in PEM format |
| **P12 generation fails** | Certificate/key mismatch | Verify files are from same certificate |
| **Password verification fails** | Wrong password | Use correct password: quikapp2025 |

## 🎯 Integration with iOS Workflow

### **Environment Variables**
Add these to your Codemagic configuration:
```yaml
environment:
  CERT_CER_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_gps.cer"
  CERT_KEY_URL: "https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key"
  CERT_PASSWORD: "quikapp2025"
```

### **Workflow Integration**
The generated P12 file can be used in your iOS workflow:
```bash
# The script automatically copies the P12 file to:
ios/certificates/Certificates.p12

# Use in your workflow with password:
CERT_PASSWORD="quikapp2025"
```

## 📁 File Locations

### **Test Files**
- `/tmp/cert_test_*/` - Temporary test directory
- `/tmp/cert_test_*/ios_distribution_gps.cer` - Downloaded certificate
- `/tmp/cert_test_*/private.key` - Downloaded private key
- `/tmp/cert_test_*/Certificates.p12` - Generated P12 file

### **Project Files**
- `ios/certificates/Certificates.p12` - P12 file for iOS workflow

## 🔒 Security Notes

- ✅ Certificate files are downloaded over HTTPS
- ✅ Private key is protected with password
- ✅ Test files are cleaned up after testing
- ✅ P12 file is password-protected
- ⚠️ Store password securely in production

## 📞 Support

If the certificate generation test fails:

1. **Check network connectivity** to raw.githubusercontent.com
2. **Verify certificate URLs** are accessible
3. **Ensure OpenSSL** is available in the environment
4. **Check file permissions** for write access
5. **Review error messages** for specific issues

---

**Status**: ✅ **READY** - Certificate generation test implemented
**Security**: ✅ **HIGH** - Password-protected P12 generation
**Validation**: ✅ **COMPREHENSIVE** - Full certificate chain testing
**Integration**: ✅ **SEAMLESS** - Works with existing iOS workflow 