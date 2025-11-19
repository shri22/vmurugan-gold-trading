# Quick Post-Clone Setup Guide

This is a quick reference for setting up the project after cloning. For detailed information, see `REPOSITORY_VERIFICATION_REPORT.md`.

---

## 🚀 Quick Start (5 Minutes)

### 1. Clone the Repository
```bash
git clone https://github.com/shri22/vmurugan-gold-trading.git
cd vmurugan-gold-trading
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Create Platform Configuration

**macOS:**
```bash
cat > android/local.properties << EOF
sdk.dir=/Users/$USER/Library/Android/sdk
flutter.sdk=/Users/$USER/flutter
EOF
```

**Windows (PowerShell):**
```powershell
@"
sdk.dir=C:\Users\$env:USERNAME\AppData\Local\Android\sdk
flutter.sdk=C:\src\flutter
"@ | Out-File -FilePath android\local.properties -Encoding ASCII
```

**Windows (Command Prompt):**
```cmd
(
echo sdk.dir=C:\Users\%USERNAME%\AppData\Local\Android\sdk
echo flutter.sdk=C:\src\flutter
) > android\local.properties
```

### 4. Build the App
```bash
# Debug build (for testing)
flutter build apk --debug

# Release build (requires signing key - see below)
flutter build apk --release
```

---

## 🔑 Release Build Setup (Optional)

### If You Have the Existing Keystore

1. Obtain `upload-keystore.jks` from the team
2. Place it in the `android/` directory
3. Create `android/key.properties`:
```properties
storePassword=vmurugan123
keyPassword=vmurugan123
keyAlias=upload
storeFile=upload-keystore.jks
```

### If Creating a New Keystore

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cd ..
```

Then create `android/key.properties` with your chosen passwords.

⚠️ **NEVER commit these files to Git!** They are already in `.gitignore`.

---

## 🍎 macOS Additional Setup (for iOS builds)

```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios
pod install
cd ..

# Install macOS dependencies (optional)
cd macos
pod install
cd ..
```

---

## 🖥️ Server Setup (Optional)

If you need to run the backend servers:

```bash
# SQL Server API
cd sql_server_api
npm install
# Update .env with your database credentials
npm start
cd ..

# Node.js Server (if needed)
cd server
npm install
# Update .env with your configuration
npm start
cd ..
```

---

## ✅ Verify Setup

```bash
# Check Flutter installation
flutter doctor -v

# Should show:
# ✓ Flutter (Channel stable, 3.38.2)
# ✓ Android toolchain
# ✓ Xcode (macOS only)
# ✓ Connected devices

# Test build
flutter build apk --debug

# Should complete without errors
```

---

## 🐛 Common Issues

### "SDK location not found"
→ Create `android/local.properties` (see step 3 above)

### "Gradle build failed"
```bash
flutter clean
rm -rf android/.gradle
flutter pub get
flutter build apk --debug
```

### "CocoaPods not installed" (macOS)
```bash
sudo gem install cocoapods
```

### "No such file or directory: lib/..."
→ This should NOT happen. All source files are in the repository. Try:
```bash
git status
git pull
```

---

## 📱 Running the App

### On Physical Device
```bash
# Connect device via USB
flutter devices

# Run the app
flutter run --release
```

### On Emulator
```bash
# Start Android emulator
flutter emulators --launch <emulator_id>

# Run the app
flutter run
```

---

## 📦 What's Included

✅ All source code (99 Dart files)  
✅ All Android resources and icons  
✅ All iOS resources and icons  
✅ Firebase configuration  
✅ Server code (Node.js)  
✅ Documentation  

❌ Signing keystores (security - must create/obtain)  
❌ Platform-specific configs (auto-generated or machine-specific)  
❌ node_modules (run `npm install`)  

---

## 🆘 Need Help?

1. Check `REPOSITORY_VERIFICATION_REPORT.md` for detailed information
2. Run `flutter doctor -v` to diagnose issues
3. Check the troubleshooting section in the verification report
4. Ensure you're using Flutter 3.24.5 or higher

---

## 📋 Quick Checklist

After cloning, verify:

- [ ] `flutter pub get` completed successfully
- [ ] `android/local.properties` created
- [ ] `flutter doctor` shows no critical errors
- [ ] `flutter build apk --debug` succeeds
- [ ] APK generated in `build/app/outputs/flutter-apk/`

For release builds, also verify:
- [ ] Signing keystore obtained/created
- [ ] `android/key.properties` configured
- [ ] `flutter build apk --release` succeeds

---

**Ready to build!** 🚀

For detailed information, troubleshooting, and platform-specific notes, see:
- `REPOSITORY_VERIFICATION_REPORT.md` - Complete verification report
- `GIT_LINE_ENDINGS_EXPLANATION.md` - Line ending issues explained
- `BUILD_SUMMARY.md` - Latest build information

