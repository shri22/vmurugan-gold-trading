@echo off
title VMurugan Gold Trading - Production APK Builder
color 0A

echo.
echo ========================================
echo 🏆 VMurugan Gold Trading - APK Builder
echo ========================================
echo.
echo Building production APK for server: 103.124.152.220
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ ERROR: Flutter is not installed or not in PATH!
    echo Please install Flutter from https://flutter.dev/
    echo.
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version
echo.

REM Check if we're in the correct directory
if not exist "pubspec.yaml" (
    echo ❌ ERROR: pubspec.yaml not found!
    echo Please run this script from the Flutter project root directory
    echo.
    pause
    exit /b 1
)

echo ✅ Flutter project found
echo.

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
if %errorLevel% neq 0 (
    echo ❌ Flutter clean failed
    pause
    exit /b 1
)
echo ✅ Clean completed
echo.

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get
if %errorLevel% neq 0 (
    echo ❌ Flutter pub get failed
    pause
    exit /b 1
)
echo ✅ Dependencies installed
echo.

REM Check Android setup
echo 🤖 Checking Android setup...
flutter doctor --android-licenses >nul 2>&1
flutter doctor | findstr "Android"
echo.

REM Build APK
echo 🚀 Building production APK...
echo This may take several minutes...
echo.

flutter build apk --release --target-platform android-arm,android-arm64,android-x64
if %errorLevel% neq 0 (
    echo ❌ APK build failed!
    echo.
    echo Common solutions:
    echo 1. Run: flutter doctor
    echo 2. Accept Android licenses: flutter doctor --android-licenses
    echo 3. Update Android SDK
    echo 4. Check Java version
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ APK build completed successfully!
echo.

REM Check if APK was created
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo 📱 APK Location: build\app\outputs\flutter-apk\app-release.apk
    
    REM Get APK size
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set size=%%~zA
        set /a sizeMB=!size!/1024/1024
    )
    echo 📊 APK Size: !sizeMB! MB
    
    REM Copy APK to root directory with descriptive name
    set timestamp=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%
    set timestamp=!timestamp: =0!
    copy "build\app\outputs\flutter-apk\app-release.apk" "VMurugan_Gold_Trading_v1.0.0_!timestamp!.apk"
    
    echo.
    echo ========================================
    echo 🎉 APK BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo 📱 APK Files Created:
    echo    Original: build\app\outputs\flutter-apk\app-release.apk
    echo    Copy:     VMurugan_Gold_Trading_v1.0.0_!timestamp!.apk
    echo.
    echo 🔗 Server Configuration:
    echo    API Server:    http://103.124.152.220:3001
    echo    Client Server: http://103.124.152.220:3000
    echo    Environment:   Production
    echo.
    echo 📋 APK Details:
    echo    App Name:      VMurugan Gold Trading
    echo    Version:       1.0.0+1
    echo    Package:       com.vmurugan.digi_gold
    echo    Size:          !sizeMB! MB
    echo    Architecture:  Universal (ARM, ARM64, x64)
    echo.
    echo 🧪 Testing Instructions:
    echo    1. Install APK on Android device
    echo    2. Test API connectivity to 103.124.152.220:3001
    echo    3. Test payment flows to 103.124.152.220:3000
    echo    4. Verify all features work with production server
    echo.
    echo 🏦 Bank Integration URLs (configured in APK):
    echo    Success: http://103.124.152.220:3000/payment/success
    echo    Failure: http://103.124.152.220:3000/payment/failure
    echo    Cancel:  http://103.124.152.220:3000/payment/cancel
    echo.
    
    REM Open APK location
    echo Opening APK location...
    explorer /select,"VMurugan_Gold_Trading_v1.0.0_!timestamp!.apk"
    
) else (
    echo ❌ APK file not found at expected location!
    echo Check build logs above for errors.
)

echo.
echo Press any key to exit...
pause >nul
