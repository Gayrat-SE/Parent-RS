#!/bin/bash

# Microphone Permission Test Script
# This script helps verify microphone permission setup

echo "🎤 Microphone Permission Test Script"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

echo "✅ Project root directory confirmed"
echo ""

# Check Android Manifest
echo "📱 Checking Android Manifest..."
if grep -q "android.permission.RECORD_AUDIO" android/app/src/main/AndroidManifest.xml; then
    echo "✅ RECORD_AUDIO permission found in AndroidManifest.xml"
else
    echo "❌ RECORD_AUDIO permission NOT found in AndroidManifest.xml"
    echo "   Add: <uses-permission android:name=\"android.permission.RECORD_AUDIO\" />"
fi
echo ""

# Check iOS Info.plist
echo "🍎 Checking iOS Info.plist..."
if grep -q "NSMicrophoneUsageDescription" ios/Runner/Info.plist; then
    echo "✅ NSMicrophoneUsageDescription found in Info.plist"
else
    echo "❌ NSMicrophoneUsageDescription NOT found in Info.plist"
    echo "   Add microphone usage description to Info.plist"
fi
echo ""

# Check pubspec.yaml for required packages
echo "📦 Checking required packages..."
packages=("permission_handler" "flutter_inappwebview")
for package in "${packages[@]}"; do
    if grep -q "$package:" pubspec.yaml; then
        echo "✅ $package found in pubspec.yaml"
    else
        echo "❌ $package NOT found in pubspec.yaml"
    fi
done
echo ""

# Check main.dart for permission request
echo "🔧 Checking main.dart..."
if grep -q "Permission.microphone.request()" lib/main.dart; then
    echo "✅ Microphone permission request found in main.dart"
else
    echo "⚠️  Microphone permission request NOT found in main.dart"
    echo "   Consider adding: await Permission.microphone.request();"
fi
echo ""

# Check WebView configuration
echo "🌐 Checking WebView configuration..."
if grep -q "iframeAllow.*microphone" lib/flutter_flow/flutter_flow_inapp_web_view.dart; then
    echo "✅ Microphone allowed in WebView iframeAllow"
else
    echo "❌ Microphone NOT in WebView iframeAllow"
fi

if grep -q "onPermissionRequest" lib/flutter_flow/flutter_flow_inapp_web_view.dart; then
    echo "✅ onPermissionRequest handler found"
else
    echo "❌ onPermissionRequest handler NOT found"
fi
echo ""

# Summary
echo "📊 Summary"
echo "=========="
echo "Review the checks above. All items should show ✅"
echo ""
echo "Next steps:"
echo "1. Fix any ❌ items above"
echo "2. Run: flutter clean"
echo "3. Run: flutter pub get"
echo "4. Rebuild and test the app"
echo ""
echo "To view logs while testing:"
echo "  iOS:     flutter run --verbose"
echo "  Android: adb logcat | grep -E 'WebView|Permission|Microphone'"
echo ""

