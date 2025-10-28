#!/bin/bash

# Script to setup the splash screen and install dependencies

echo "🚀 Setting up splash screen and dependencies..."

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Generate splash screen
echo "🎨 Generating native splash screen..."
dart run flutter_native_splash:create

echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Run 'flutter clean' to clean the build"
echo "2. Run 'flutter run' to test the app"
echo ""
echo "The app should now:"
echo "  ✓ Show a branded splash screen instead of white screen"
echo "  ✓ Start much faster (permissions requested after UI loads)"
echo "  ✓ Display the app UI immediately after Firebase initialization"

