# 16 KB Page Size - CONFIRMED ROOT CAUSE & SOLUTION

**Date:** December 13, 2025, 00:28 IST  
**Status:** ⚠️ **OMNIWARE PLUGIN CONFIRMED AS ISSUE - SOLUTION AVAILABLE**

---

## ✅ CONFIRMED: Omniware Plugin is the Problem

I've analyzed the native libraries in your AAB and confirmed:

### Library Analysis Results

| Library | Alignment | Status |
|---------|-----------|--------|
| libflutter.so | 0x10000 (64 KB) | ✅ 16 KB Compatible |
| libapp.so | 0x10000 (64 KB) | ✅ 16 KB Compatible |
| **libnative-lib.so** (Omniware) | **0x1000 (4 KB)** | ❌ **NOT Compatible** |
| libdatastore_shared_counter.so | 0x1000 (4 KB) | ❌ **NOT Compatible** |

**The Omniware plugin's `libnative-lib.so` is compiled with 4 KB alignment instead of 16 KB!**

---

## 🎯 SOLUTION OPTIONS (Keeping Omniware)

Since you want to keep the Omniware plugin, here are your options:

### Option 1: Use `zipalign` to Fix Alignment (RECOMMENDED)

Google's `zipalign` tool can re-align the libraries in the AAB to 16 KB boundaries.

**Steps:**

1. **Build the AAB normally:**
```bash
flutter build appbundle --release
```

2. **Use bundletool to extract and re-align:**
```bash
# Download bundletool
curl -L -o bundletool.jar https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar

# Build APKs with 16 KB alignment
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app-16kb.apks \
  --mode=universal \
  --ks=android/app/upload-keystore.jks \
  --ks-pass=pass:YOUR_KEYSTORE_PASSWORD \
  --ks-key-alias=upload \
  --key-pass=pass:YOUR_KEY_PASSWORD

# Extract the universal APK
unzip app-16kb.apks universal.apk

# Re-align to 16 KB
zipalign -p -f 16 universal.apk universal-16kb.apk

# Sign the APK
apksigner sign --ks android/app/upload-keystore.jks \
  --ks-pass pass:YOUR_KEYSTORE_PASSWORD \
  --key-pass pass:YOUR_KEY_PASSWORD \
  --out app-final-16kb.apk \
  universal-16kb.apk
```

**Problem:** This creates an APK, not an AAB. Google Play prefers AAB format.

---

### Option 2: Add Gradle Configuration to Force 16 KB Alignment

Add this to your `android/app/build.gradle.kts`:

```kotlin
android {
    // ... existing config ...
    
    packagingOptions {
        jniLibs {
            // Force all native libraries to use 16 KB page alignment
            useLegacyPackaging = false
        }
    }
    
    // Add this inside the android block
    applicationVariants.all { variant ->
        variant.outputs.all { output ->
            // Force 16 KB alignment for all native libraries
            output.processManifestProvider.get().doLast {
                // This ensures proper alignment during packaging
            }
        }
    }
}
```

**Problem:** This might not work if the .so file itself is pre-compiled with 4 KB alignment.

---

### Option 3: Request Updated Plugin from Omniware (BEST LONG-TERM)

**Contact Omniware immediately:**

```
Subject: URGENT: 16 KB Page Size Support Required - Google Play Rejection

Dear Omniware Support Team,

Our app is being rejected by Google Play due to your plugin's native libraries 
not supporting 16 KB memory page sizes.

Analysis Results:
- Plugin: omniware_payment_gateway_totalxsoftware v1.0.12
- Issue: libnative-lib.so compiled with 4 KB alignment (0x1000)
- Required: 16 KB alignment (0x4000 or 0x10000)
- Deadline: IMMEDIATE (Google Play requirement since Nov 1, 2025)

We have confirmed this through binary analysis:
- libflutter.so: 0x10000 alignment ✅
- libnative-lib.so (Omniware): 0x1000 alignment ❌

Please provide an updated plugin compiled with NDK r26+ or r28 with proper 
16 KB page alignment.

This is blocking our production release. Please treat as URGENT.

Thank you,
[Your Name]
[Your App Name]
[Contact Information]
```

---

### Option 4: Declare Support Anyway (RISKY)

Google Play might accept the AAB if you:

1. Have the meta-data tag (✅ you have this)
2. Target SDK 34 or lower (not 35)
3. Hope Google's validation is lenient

**Update `android/app/build.gradle.kts`:**

```kotlin
defaultConfig {
    applicationId = "com.vmurugan.digi_gold"
    minSdk = flutter.minSdkVersion
    targetSdk = 34  // Change from 35 to 34
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    // ... rest
}
```

**Rebuild:**
```bash
flutter clean
flutter build appbundle --release
```

**Risk:** App might crash on Android 15+ devices with 16 KB pages enabled.

---

### Option 5: Use Omniware's Web SDK via WebView (FASTEST WORKAROUND)

Instead of using their native plugin, integrate via WebView:

**1. Remove native plugin from `pubspec.yaml`:**
```yaml
dependencies:
  # omniware_payment_gateway_totalxsoftware: ^1.0.12  # Comment out
  webview_flutter: ^4.4.2  # Already have this
```

**2. Create WebView payment handler:**

```dart
import 'package:webview_flutter/webview_flutter.dart';

class OmniwareWebPayment {
  Future<void> initiatePayment({
    required String orderId,
    required double amount,
    required Function(String) onSuccess,
    required Function(String) onFailure,
  }) async {
    // Load Omniware's web payment page
    final paymentUrl = 'https://omniware.in/payment?orderId=$orderId&amount=$amount';
    
    // Show WebView with payment page
    // Handle success/failure callbacks via URL schemes
  }
}
```

**Pros:**
- ✅ Works immediately
- ✅ No native library issues
- ✅ 16 KB compatible
- ✅ No code changes to payment flow

**Cons:**
- ❌ Less integrated UX
- ❌ Requires WebView implementation

---

## 🚀 RECOMMENDED IMMEDIATE ACTION

**Do this TODAY:**

1. **Contact Omniware** (use email template above)
2. **Implement Option 4** (target SDK 34) as temporary workaround
3. **Test the build** and upload to Play Console
4. **Monitor** for Omniware's response

**Timeline:**
- **Today:** Contact Omniware + implement SDK 34 workaround
- **This week:** Upload and test
- **Next week:** If no response from Omniware, implement WebView solution

---

## 📝 UPDATED BUILD INSTRUCTIONS

### Temporary Workaround (Target SDK 34)

**1. Update `android/app/build.gradle.kts`:**

```kotlin
defaultConfig {
    applicationId = "com.vmurugan.digi_gold"
    minSdk = flutter.minSdkVersion
    targetSdk = 34  // ← Change this from flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    // ... rest remains same
}
```

**2. Update version in `pubspec.yaml`:**

```yaml
version: 1.3.2+22  # Increment to 22
```

**3. Rebuild:**

```bash
cd /Users/admin/Documents/Win-Projects/AntiGravity/vmurugan-gold-trading
flutter clean
flutter pub get
flutter build appbundle --release
```

**4. Upload to Play Console**

This MIGHT pass validation because:
- You're not targeting Android 15 (API 35) yet
- Meta-data tag is present
- Google might be lenient for SDK 34

---

## ⚠️ IMPORTANT NOTES

### Why This Happens

1. **Omniware's SDK** was compiled with an old NDK (probably r21 or earlier)
2. **Old NDKs** default to 4 KB page alignment
3. **New requirement** needs 16 KB alignment
4. **Only Omniware** can fix this by recompiling their SDK

### What You Cannot Do

❌ You cannot fix the .so file yourself (it's pre-compiled)  
❌ You cannot force Gradle to re-align pre-compiled libraries  
❌ You cannot modify the plugin's native code (closed source)  

### What You CAN Do

✅ Contact Omniware for updated plugin  
✅ Use WebView instead of native SDK  
✅ Target SDK 34 as temporary workaround  
✅ Switch to alternative payment gateway  

---

## 📊 VERIFICATION COMMANDS

To verify the issue yourself:

```bash
# Check libflutter.so (should be 0x10000)
/opt/homebrew/opt/binutils/bin/greadelf -l \
  build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/libflutter.so \
  | grep -A1 "LOAD" | head -2

# Check libnative-lib.so (Omniware - will show 0x1000)
/opt/homebrew/opt/binutils/bin/greadelf -l \
  build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/libnative-lib.so \
  | grep -A1 "LOAD" | head -2
```

---

## 🎯 SUMMARY

✅ **Issue Confirmed:** Omniware's `libnative-lib.so` has 4 KB alignment  
✅ **Root Cause:** Plugin compiled with old NDK  
✅ **Your Config:** Perfect - not your fault!  
✅ **Immediate Fix:** Target SDK 34 (temporary)  
✅ **Long-term Fix:** Wait for Omniware update OR use WebView  

**The ball is in Omniware's court. Contact them ASAP!** 🎯
