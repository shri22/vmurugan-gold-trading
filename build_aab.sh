#!/bin/bash

# Build Script for VMurugan Gold Trading App
# Version: 1.3.2 (Build 22)
# Purpose: Build production AAB with storage permission fix

echo "🚀 Building VMurugan Gold Trading App - Version 1.3.2 (Build 22)"
echo "=================================================="
echo ""

# Step 1: Clean previous builds
echo "📦 Step 1/4: Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Flutter clean failed!"
    exit 1
fi
echo "✅ Clean completed"
echo ""

# Step 2: Get dependencies
echo "📥 Step 2/4: Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Flutter pub get failed!"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

# Step 3: Build release AAB
echo "🔨 Step 3/4: Building release AAB..."
echo "This may take several minutes..."
flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build completed successfully"
echo ""

# Step 4: Verify output
echo "🔍 Step 4/4: Verifying build output..."
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo "✅ AAB file created successfully!"
    echo ""
    echo "=================================================="
    echo "📊 Build Summary"
    echo "=================================================="
    echo "Version Name: 1.3.2"
    echo "Version Code: 22"
    echo "File Location: $AAB_PATH"
    echo "File Size: $AAB_SIZE"
    echo ""
    echo "🎉 SUCCESS! Your AAB is ready for Google Play Console"
    echo ""
    echo "Next steps:"
    echo "1. Go to Google Play Console"
    echo "2. Create a new release"
    echo "3. Upload: $AAB_PATH"
    echo "4. Remove MANAGE_EXTERNAL_STORAGE from permissions declaration"
    echo "5. Submit for review"
    echo ""
else
    echo "❌ AAB file not found at expected location!"
    exit 1
fi
