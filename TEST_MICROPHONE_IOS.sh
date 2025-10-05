#!/bin/bash

# iOS Microphone Permission Test Script
# Bu script iOS'da microphone permission to'g'ri sozlanganligini tekshiradi

echo "🎤 iOS Microphone Permission Test"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found${NC}"
    echo "Please run this script from the project root."
    exit 1
fi

echo -e "${GREEN}✅ Project root directory confirmed${NC}"
echo ""

# Step 1: Check Info.plist
echo -e "${BLUE}📱 Step 1: Checking Info.plist...${NC}"
if grep -q "NSMicrophoneUsageDescription" ios/Runner/Info.plist; then
    echo -e "${GREEN}✅ NSMicrophoneUsageDescription found in Info.plist${NC}"
    # Show the description
    desc=$(grep -A 1 "NSMicrophoneUsageDescription" ios/Runner/Info.plist | tail -1 | sed 's/<[^>]*>//g' | xargs)
    echo -e "${BLUE}   Description: $desc${NC}"
else
    echo -e "${RED}❌ NSMicrophoneUsageDescription NOT found in Info.plist${NC}"
    echo -e "${YELLOW}   This is REQUIRED for iOS microphone permission!${NC}"
    exit 1
fi
echo ""

# Step 2: Check Podfile
echo -e "${BLUE}📦 Step 2: Checking Podfile...${NC}"
if grep -q "PERMISSION_MICROPHONE=1" ios/Podfile; then
    echo -e "${GREEN}✅ PERMISSION_MICROPHONE=1 found in Podfile${NC}"
else
    echo -e "${RED}❌ PERMISSION_MICROPHONE=1 NOT found in Podfile${NC}"
    echo -e "${YELLOW}   This is REQUIRED for permission_handler to work!${NC}"
    exit 1
fi
echo ""

# Step 3: Check if Pods are installed
echo -e "${BLUE}🔧 Step 3: Checking Pods installation...${NC}"
if [ -d "ios/Pods" ]; then
    echo -e "${GREEN}✅ Pods directory exists${NC}"
    
    # Check if permission_handler_apple is installed
    if [ -d "ios/Pods/permission_handler_apple" ]; then
        echo -e "${GREEN}✅ permission_handler_apple pod installed${NC}"
    else
        echo -e "${YELLOW}⚠️  permission_handler_apple pod NOT found${NC}"
        echo -e "${YELLOW}   Run: cd ios && pod install${NC}"
    fi
else
    echo -e "${RED}❌ Pods directory NOT found${NC}"
    echo -e "${YELLOW}   Run: cd ios && pod install${NC}"
    exit 1
fi
echo ""

# Step 4: Check permission request code
echo -e "${BLUE}💻 Step 4: Checking permission request code...${NC}"
if grep -q "PermissionRequestHelper.requestMicrophonePermission" lib/pages/home_page/home_page_widget.dart; then
    echo -e "${GREEN}✅ Permission request found in HomePage${NC}"
else
    echo -e "${RED}❌ Permission request NOT found in HomePage${NC}"
    echo -e "${YELLOW}   Permission should be requested when HomePage loads${NC}"
    exit 1
fi
echo ""

# Step 5: Check permission helper
echo -e "${BLUE}🛠️  Step 5: Checking permission helper...${NC}"
if [ -f "lib/flutter_flow/permission_request_helper.dart" ]; then
    echo -e "${GREEN}✅ permission_request_helper.dart exists${NC}"
else
    echo -e "${RED}❌ permission_request_helper.dart NOT found${NC}"
    exit 1
fi
echo ""

# Summary
echo -e "${BLUE}📊 Summary${NC}"
echo "=========="
echo ""
echo -e "${GREEN}✅ All checks passed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Clean and rebuild:"
echo "   ${BLUE}flutter clean${NC}"
echo "   ${BLUE}flutter pub get${NC}"
echo "   ${BLUE}cd ios && pod install && cd ..${NC}"
echo ""
echo "2. Uninstall app from device (important!)"
echo ""
echo "3. Run on REAL iOS device (not simulator):"
echo "   ${BLUE}flutter run${NC}"
echo ""
echo "4. When app opens, permission dialog should appear:"
echo "   ${GREEN}\"RS ota-onalar\" Would Like to Access the Microphone${NC}"
echo ""
echo "5. Tap ${GREEN}OK${NC}"
echo ""
echo "6. Check Settings → RS ota-onalar → Microphone toggle should appear!"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "   - Microphone toggle in Settings appears ONLY AFTER"
echo "     the app requests permission for the first time!"
echo "   - Test on REAL device, not simulator"
echo "   - If dialog doesn't appear, check logs with:"
echo "     ${BLUE}flutter run --verbose${NC}"
echo ""
echo -e "${GREEN}🎉 Setup is complete! Ready to test!${NC}"
echo ""

