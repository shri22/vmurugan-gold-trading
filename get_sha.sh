#!/bin/bash
echo "=========================================="
echo "      GETTING SHA-1 FOR FIREBASE"
echo "=========================================="
echo ""

# 1. Try Debug Keystore (Standard Location)
echo "🔍 Checking Default Debug Keystore (~/.android/debug.keystore)..."
if [ -f ~/.android/debug.keystore ]; then
    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1"
else
    echo "❌ Debug keystore not found at ~/.android/debug.keystore"
fi

echo ""

# 2. Try Project Key Properties if they exist (Release)
echo "🔍 Checking Release Keystore from key.properties..."

# Extract keystore path from key.properties if possible
if [ -f android/key.properties ]; then
    STORE_FILE=$(grep "storeFile" android/key.properties | cut -d'=' -f2 | tr -d '[:space:]')
    STORE_PASS=$(grep "storePassword" android/key.properties | cut -d'=' -f2 | tr -d '[:space:]')
    KEY_ALIAS=$(grep "keyAlias" android/key.properties | cut -d'=' -f2 | tr -d '[:space:]')
    
    if [ ! -z "$STORE_FILE" ]; then
        KEYSTORE_PATH="android/$STORE_FILE"
        if [ -f "$KEYSTORE_PATH" ]; then
            echo "Found release keystore at: $KEYSTORE_PATH"
            echo "Attempting to read SHA1..."
            keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$KEY_ALIAS" -storepass "$STORE_PASS" | grep "SHA1"
        else
            echo "❌ Release keystore file defined but not found at $KEYSTORE_PATH"
        fi
    else
        echo "❌ Could not parse storeFile from key.properties"
    fi
else
    echo "❌ android/key.properties not found (Production keys not accessible)"
fi

echo ""
echo "=========================================="
echo "📋 INSTRUCTIONS:"
echo "1. Copy the SHA1 fingerprint(s) above."
echo "2. Go to Firebase Console -> Project Settings."
echo "3. Add Fingerprint."
echo "4. Paste the SHA1."
echo "5. Ensure 'Phone' is enabled in Authentication -> Sign-in methods."
echo "=========================================="
