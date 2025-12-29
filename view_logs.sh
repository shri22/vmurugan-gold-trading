#!/bin/bash

# VMurugan Gold Trading - Debug Log Viewer
# This script helps view app logs when phone is connected via USB

echo "🔍 VMurugan App Debug Log Viewer"
echo "================================"
echo ""
echo "Make sure:"
echo "1. Phone is connected via USB"
echo "2. USB Debugging is enabled"
echo "3. App is running"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "❌ ADB not found. Installing..."
    brew install android-platform-tools
fi

# Check connected devices
echo "📱 Connected devices:"
adb devices
echo ""

# Start logging
echo "📊 Starting log stream..."
echo "========================"
adb logcat | grep -E "ProfileScreen|AuthService|getBackendToken|Saving login|LOGOUT|SqlServerService|GoldSchemeService"
