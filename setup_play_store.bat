@echo off
echo ========================================
echo 🏆 VMurugan Gold Trading - Play Store Setup
echo ========================================
echo.

echo This script will help you prepare for Play Store submission.
echo.

echo Step 1: Creating Play Store assets folder...
if not exist "play_store_assets" mkdir play_store_assets
if not exist "play_store_assets\screenshots" mkdir play_store_assets\screenshots
if not exist "play_store_assets\graphics" mkdir play_store_assets\graphics
if not exist "play_store_assets\legal" mkdir play_store_assets\legal
echo ✅ Folders created!
echo.

echo Step 2: Copying legal documents...
copy "privacy_policy.html" "play_store_assets\legal\" >nul 2>&1
copy "terms_of_service.html" "play_store_assets\legal\" >nul 2>&1
copy "play_store_listing.md" "play_store_assets\" >nul 2>&1
copy "PRE_LAUNCH_CHECKLIST.md" "play_store_assets\" >nul 2>&1
echo ✅ Legal documents copied!
echo.

echo Step 3: Creating asset templates...

echo Creating app icon template...
echo ^<html^>^<body style="text-align:center; padding:50px;"^> > "play_store_assets\graphics\app_icon_template.html"
echo ^<h1^>App Icon Required^</h1^> >> "play_store_assets\graphics\app_icon_template.html"
echo ^<p^>Size: 512x512 pixels^</p^> >> "play_store_assets\graphics\app_icon_template.html"
echo ^<p^>Format: PNG (32-bit)^</p^> >> "play_store_assets\graphics\app_icon_template.html"
echo ^<p^>Content: VMurugan logo with gold theme^</p^> >> "play_store_assets\graphics\app_icon_template.html"
echo ^</body^>^</html^> >> "play_store_assets\graphics\app_icon_template.html"

echo Creating feature graphic template...
echo ^<html^>^<body style="text-align:center; padding:50px;"^> > "play_store_assets\graphics\feature_graphic_template.html"
echo ^<h1^>Feature Graphic Required^</h1^> >> "play_store_assets\graphics\feature_graphic_template.html"
echo ^<p^>Size: 1024x500 pixels^</p^> >> "play_store_assets\graphics\feature_graphic_template.html"
echo ^<p^>Format: PNG or JPG^</p^> >> "play_store_assets\graphics\feature_graphic_template.html"
echo ^<p^>Content: App showcase with gold theme^</p^> >> "play_store_assets\graphics\feature_graphic_template.html"
echo ^</body^>^</html^> >> "play_store_assets\graphics\feature_graphic_template.html"

echo Creating screenshot guide...
echo Screenshots Required > "play_store_assets\screenshots\README.txt"
echo =================== >> "play_store_assets\screenshots\README.txt"
echo. >> "play_store_assets\screenshots\README.txt"
echo Required Screenshots: >> "play_store_assets\screenshots\README.txt"
echo 1. Login/Registration Screen >> "play_store_assets\screenshots\README.txt"
echo 2. Dashboard/Portfolio View >> "play_store_assets\screenshots\README.txt"
echo 3. Gold Trading Interface >> "play_store_assets\screenshots\README.txt"
echo 4. Transaction History >> "play_store_assets\screenshots\README.txt"
echo 5. Payment Screen >> "play_store_assets\screenshots\README.txt"
echo 6. Profile/Settings >> "play_store_assets\screenshots\README.txt"
echo. >> "play_store_assets\screenshots\README.txt"
echo Specifications: >> "play_store_assets\screenshots\README.txt"
echo - Minimum 2, Maximum 8 screenshots >> "play_store_assets\screenshots\README.txt"
echo - 16:9 or 9:16 aspect ratio >> "play_store_assets\screenshots\README.txt"
echo - Minimum 320px on shortest side >> "play_store_assets\screenshots\README.txt"
echo - Maximum 3840px on longest side >> "play_store_assets\screenshots\README.txt"
echo - Format: PNG or JPG (24-bit) >> "play_store_assets\screenshots\README.txt"

echo ✅ Asset templates created!
echo.

echo Step 4: Creating configuration checklist...
echo VMurugan Gold Trading - Configuration Checklist > "play_store_assets\configuration_checklist.txt"
echo ================================================= >> "play_store_assets\configuration_checklist.txt"
echo. >> "play_store_assets\configuration_checklist.txt"
echo BEFORE BUILDING: >> "play_store_assets\configuration_checklist.txt"
echo [ ] Update server IP in client_server_config.dart >> "play_store_assets\configuration_checklist.txt"
echo [ ] Set protocol to 'https' for production >> "play_store_assets\configuration_checklist.txt"
echo [ ] Test all API endpoints >> "play_store_assets\configuration_checklist.txt"
echo [ ] Verify payment integration >> "play_store_assets\configuration_checklist.txt"
echo [ ] Test app on real device >> "play_store_assets\configuration_checklist.txt"
echo. >> "play_store_assets\configuration_checklist.txt"
echo PLAY STORE REQUIREMENTS: >> "play_store_assets\configuration_checklist.txt"
echo [ ] Google Play Console account created >> "play_store_assets\configuration_checklist.txt"
echo [ ] App icon (512x512) ready >> "play_store_assets\configuration_checklist.txt"
echo [ ] Feature graphic (1024x500) ready >> "play_store_assets\configuration_checklist.txt"
echo [ ] Screenshots (2-8) ready >> "play_store_assets\configuration_checklist.txt"
echo [ ] Privacy policy hosted online >> "play_store_assets\configuration_checklist.txt"
echo [ ] Terms of service hosted online >> "play_store_assets\configuration_checklist.txt"
echo [ ] App description written >> "play_store_assets\configuration_checklist.txt"
echo [ ] Data safety section completed >> "play_store_assets\configuration_checklist.txt"

echo ✅ Configuration checklist created!
echo.

echo Step 5: Creating build instructions...
echo VMurugan Gold Trading - Build Instructions > "play_store_assets\build_instructions.txt"
echo ========================================== >> "play_store_assets\build_instructions.txt"
echo. >> "play_store_assets\build_instructions.txt"
echo 1. Update app configuration: >> "play_store_assets\build_instructions.txt"
echo    - Edit lib/core/config/client_server_config.dart >> "play_store_assets\build_instructions.txt"
echo    - Set your production server IP >> "play_store_assets\build_instructions.txt"
echo    - Set protocol to 'https' >> "play_store_assets\build_instructions.txt"
echo. >> "play_store_assets\build_instructions.txt"
echo 2. Run the build script: >> "play_store_assets\build_instructions.txt"
echo    - Double-click build_release.bat >> "play_store_assets\build_instructions.txt"
echo    - Or run: flutter build appbundle --release >> "play_store_assets\build_instructions.txt"
echo. >> "play_store_assets\build_instructions.txt"
echo 3. Files will be created at: >> "play_store_assets\build_instructions.txt"
echo    - App Bundle: build\app\outputs\bundle\release\app-release.aab >> "play_store_assets\build_instructions.txt"
echo    - APK: build\app\outputs\flutter-apk\app-release.apk >> "play_store_assets\build_instructions.txt"
echo. >> "play_store_assets\build_instructions.txt"
echo 4. Upload AAB to Google Play Console >> "play_store_assets\build_instructions.txt"

echo ✅ Build instructions created!
echo.

echo ========================================
echo 🎉 PLAY STORE SETUP COMPLETED!
echo ========================================
echo.
echo 📁 Files created in 'play_store_assets' folder:
echo    📄 Legal documents (privacy_policy.html, terms_of_service.html)
echo    📋 Play store listing content
echo    ✅ Pre-launch checklist
echo    🎨 Asset templates and requirements
echo    ⚙️ Configuration checklist
echo    🔨 Build instructions
echo.
echo 📋 Next Steps:
echo    1. Complete the configuration checklist
echo    2. Create required graphics (app icon, feature graphic)
echo    3. Take screenshots of your app
echo    4. Host legal documents on your website
echo    5. Run build_release.bat to create app bundle
echo    6. Upload to Google Play Console
echo.
echo 🔗 Important Links:
echo    Google Play Console: https://play.google.com/console
echo    Asset Guidelines: https://developer.android.com/distribute/marketing-tools/store-listing
echo.

echo Opening play_store_assets folder...
start "" "play_store_assets"

echo.
echo Press any key to exit...
pause >nul
