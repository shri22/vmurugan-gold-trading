# Build Commands for Version 1.3.2 (Build 22)

## 🚀 Quick Build Commands

Copy and paste these commands in your terminal:

```bash
cd /Users/admin/Documents/Win-Projects/AntiGravity/vmurugan-gold-trading

# Step 1: Clean
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Build AAB
flutter build appbundle --release
```

---

## 📦 Expected Output

After running the commands, you should see:

```
✓ Built build/app/outputs/bundle/release/app-release.aab (XX.XMB).
```

---

## 📍 AAB Location

Your AAB file will be at:
```
/Users/admin/Documents/Win-Projects/AntiGravity/vmurugan-gold-trading/build/app/outputs/bundle/release/app-release.aab
```

---

## ✅ What Changed in Build 22

- **Version Name**: 1.3.2 (unchanged)
- **Version Code**: 22 (incremented from 21)
- **Changes**: 
  - ❌ Removed MANAGE_EXTERNAL_STORAGE permission
  - ✅ Added Scoped Storage support
  - ✅ Added device_info_plus package
  - ✅ Updated PDF download logic

---

## 🎯 Upload to Google Play Console

1. **Login**: Go to [Google Play Console](https://play.google.com/console)
2. **Navigate**: Your App → Production → Create New Release
3. **Upload**: Select the AAB file from the location above
4. **Release Notes**: 
   ```
   Bug fixes and improvements:
   • Updated storage permissions for better privacy and compliance
   • Improved PDF statement generation
   • Enhanced compatibility with Android 10+
   • Performance optimizations
   ```
5. **Permissions**: 
   - ⚠️ **IMPORTANT**: DO NOT declare MANAGE_EXTERNAL_STORAGE
   - Only declare the permissions that are actually in the app
6. **Submit**: Review and submit for approval

---

## 🔍 Verify Build

To verify the AAB doesn't have MANAGE_EXTERNAL_STORAGE:

```bash
# Extract AAB
unzip -q build/app/outputs/bundle/release/app-release.aab -d /tmp/aab_check

# Check manifest (if you have aapt2 installed)
aapt2 dump badging /tmp/aab_check/base/manifest/AndroidManifest.xml | grep MANAGE_EXTERNAL_STORAGE
```

You should see **NO OUTPUT** (meaning the permission is not there).

---

## 📊 Build Information

| Property | Value |
|----------|-------|
| App Name | VMurugan Digital Gold Trading |
| Package | com.vmurugan.digi_gold |
| Version Name | 1.3.2 |
| Version Code | 22 |
| Min SDK | 21 (Android 5.0) |
| Target SDK | Latest |
| Build Type | Release (Signed) |
| File Format | AAB (Android App Bundle) |

---

## ⚠️ Troubleshooting

### If Flutter command not found:
Make sure Flutter is in your PATH. Try:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

Or use the full path to Flutter:
```bash
/path/to/flutter/bin/flutter clean
/path/to/flutter/bin/flutter pub get
/path/to/flutter/bin/flutter build appbundle --release
```

### If build fails:
```bash
# Try upgrading dependencies
flutter pub upgrade

# Then rebuild
flutter clean
flutter pub get
flutter build appbundle --release
```

### If signing fails:
Make sure `key.properties` file exists in the `android` folder with:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../path/to/keystore.jks
```

---

## 📞 Need Help?

If you encounter any issues:
1. Check the error message carefully
2. Make sure all dependencies are installed
3. Verify your signing configuration
4. Check the documentation files created earlier

---

**Status**: ✅ Ready to build  
**Version**: 1.3.2+22  
**Date**: December 13, 2025
