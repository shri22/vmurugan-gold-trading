@echo off
echo ========================================
echo 🏆 VMurugan Gold Trading - Release Build
echo ========================================
echo.

echo Step 1: Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter not found! Please install Flutter first.
    pause
    exit /b 1
)
echo ✅ Flutter found!
echo.

echo Step 2: Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ Flutter clean failed!
    pause
    exit /b 1
)
echo ✅ Clean completed!
echo.

echo Step 3: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies!
    pause
    exit /b 1
)
echo ✅ Dependencies updated!
echo.

echo Step 4: Running code analysis...
flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️ Code analysis found issues. Continue anyway? (y/n)
    set /p continue=
    if /i not "%continue%"=="y" (
        echo Build cancelled.
        pause
        exit /b 1
    )
)
echo ✅ Code analysis completed!
echo.

echo Step 5: Building App Bundle (AAB) for Play Store...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ App Bundle build failed!
    pause
    exit /b 1
)
echo ✅ App Bundle built successfully!
echo.

echo Step 6: Building APK for testing...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ❌ APK build failed!
    pause
    exit /b 1
)
echo ✅ APK built successfully!
echo.

echo ========================================
echo 🎉 BUILD COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo 📱 Files created:
echo    App Bundle (for Play Store): build\app\outputs\bundle\release\app-release.aab
echo    APK (for testing):          build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📋 Next Steps:
echo    1. Test the APK on a real device
echo    2. Upload AAB to Google Play Console
echo    3. Complete Play Store listing
echo    4. Submit for review
echo.
echo 🔗 Useful Links:
echo    Google Play Console: https://play.google.com/console
echo    Flutter Deployment:  https://docs.flutter.dev/deployment/android
echo.

echo Opening build output folder...
start "" "build\app\outputs"

echo.
echo Press any key to exit...
pause >nul
