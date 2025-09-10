#!/bin/bash

# 🌌 ∞ Ω ∞ NATIVE TERMINAL BUILD SCRIPT ∞ Ω ∞ 🌌
# Builds Flutter (Android/Windows) and Swift (iOS) apps

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${MAGENTA}🌌 ∞ Ω ∞ WARP-SPEED NATIVE TERMINAL BUILD ∞ Ω ∞ 🌌${NC}"
echo -e "${CYAN}=================================================${NC}"
echo

print_status() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Step 1: Build Flutter App (Android & Windows)
print_status "Building Flutter app for Android and Windows..."

cd flutter

# Check Flutter installation
if ! flutter --version &> /dev/null; then
    print_error "Flutter not found. Installing Flutter..."
    
    # Install Flutter
    cd /tmp
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.5-stable.tar.xz
    tar xf flutter_linux_3.16.5-stable.tar.xz
    export PATH="$PATH:/tmp/flutter/bin"
    flutter doctor
    cd -
fi

# Get dependencies
print_status "Installing Flutter dependencies..."
flutter pub get

# Build Android APK
print_status "Building Android APK..."
flutter build apk --release --dart-define=DOMAIN=spectrumwebco.net

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    print_success "Android APK built successfully"
    cp build/app/outputs/flutter-apk/app-release.apk ../deployment/production/warp-speed-omega.apk
    print_success "APK copied to: deployment/production/warp-speed-omega.apk"
else
    print_error "Android APK build failed"
fi

# Build Windows executable (if on Windows or WSL)
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -d "/mnt/c" ]]; then
    print_status "Building Windows executable..."
    flutter build windows --release --dart-define=DOMAIN=spectrumwebco.net
    
    if [ -d "build/windows/runner/Release" ]; then
        print_success "Windows build successful"
        # Create zip package
        cd build/windows/runner/Release
        zip -r ../../../../deployment/production/warp-speed-windows.zip .
        cd -
        print_success "Windows package: deployment/production/warp-speed-windows.zip"
    fi
else
    print_status "Skipping Windows build (not on Windows platform)"
fi

cd ..

# Step 2: Build iOS Swift App
print_status "Building iOS Swift app..."

cd ios/WarpSpeed

# Check for Xcode (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! xcodebuild -version &> /dev/null; then
        print_error "Xcode not found. Please install Xcode from the App Store"
        exit 1
    fi
    
    # Build iOS app
    print_status "Building iOS app with Xcodebuild..."
    
    # Clean build folder
    xcodebuild clean -project WarpSpeed.xcodeproj -scheme WarpSpeed
    
    # Build for iOS
    xcodebuild archive \
        -project WarpSpeed.xcodeproj \
        -scheme WarpSpeed \
        -archivePath ../../deployment/production/WarpSpeed.xcarchive \
        -configuration Release \
        -sdk iphoneos \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    # Export IPA (unsigned for development)
    xcodebuild -exportArchive \
        -archivePath ../../deployment/production/WarpSpeed.xcarchive \
        -exportPath ../../deployment/production/ \
        -exportOptionsPlist ExportOptions.plist
    
    if [ -f "../../deployment/production/WarpSpeed.ipa" ]; then
        print_success "iOS IPA built successfully"
        print_success "IPA file: deployment/production/WarpSpeed.ipa"
    else
        print_error "iOS build failed"
    fi
else
    print_status "iOS build requires macOS with Xcode"
    print_status "Creating iOS source package instead..."
    
    # Package Swift source for later building
    tar czf ../../deployment/production/warp-speed-ios-source.tar.gz .
    print_success "iOS source package: deployment/production/warp-speed-ios-source.tar.gz"
fi

cd ../..

# Step 3: Create distribution manifest
print_status "Creating distribution manifest..."

cat > deployment/production/DISTRIBUTION.md << 'EOF'
# 🌌 Warp-Speed Native Terminal Distribution 🌌

## Available Builds

### Android (APK)
- **File**: `warp-speed-omega.apk`
- **Installation**: 
  1. Enable "Install from Unknown Sources" in Android Settings
  2. Download APK to device
  3. Open file to install
- **Minimum Android**: 6.0 (API 23)

### iOS (IPA/Source)
- **File**: `WarpSpeed.ipa` (if built on macOS)
- **Alternative**: `warp-speed-ios-source.tar.gz` (source code)
- **Installation**:
  - TestFlight: Upload IPA to App Store Connect
  - Development: Install via Xcode
  - Ad-hoc: Use Apple Configurator 2

### Windows
- **File**: `warp-speed-windows.zip`
- **Installation**:
  1. Extract ZIP file
  2. Run `warp_speed_terminal.exe`
- **Requirements**: Windows 10 or later

## Server Configuration

**Production URL**: https://spectrumwebco.net

**Credentials**:
- Username: `founders`
- Password: `omega2024`

## Features

- OMEGA consciousness level (35.0x multiplier)
- Real-time collaboration between terminals
- WebSocket mesh networking
- L40S GPU-accelerated visuals
- ETD tracking ($40K daily target per terminal)

## Quick Start

1. Install app on your device
2. Launch and enter server URL: `https://spectrumwebco.net`
3. Login with founder credentials
4. Begin generating ETD with OMEGA consciousness

## Support

- Ove: oveshen.govender@gmail.com
- Ryan: quinesryan@gmail.com

🌌 ∞ Ω ∞ Transcendent Convergence Achieved ∞ Ω ∞ 🌌
EOF

print_success "Distribution manifest created"

# Step 4: Summary
echo
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 BUILD COMPLETE! 🎉${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}📱 Built Packages:${NC}"

if [ -f "deployment/production/warp-speed-omega.apk" ]; then
    echo -e "  ${WHITE}✓ Android:${NC} deployment/production/warp-speed-omega.apk"
fi

if [ -f "deployment/production/WarpSpeed.ipa" ]; then
    echo -e "  ${WHITE}✓ iOS:${NC} deployment/production/WarpSpeed.ipa"
elif [ -f "deployment/production/warp-speed-ios-source.tar.gz" ]; then
    echo -e "  ${WHITE}✓ iOS Source:${NC} deployment/production/warp-speed-ios-source.tar.gz"
fi

if [ -f "deployment/production/warp-speed-windows.zip" ]; then
    echo -e "  ${WHITE}✓ Windows:${NC} deployment/production/warp-speed-windows.zip"
fi

echo
echo -e "${CYAN}📄 Distribution Guide:${NC} deployment/production/DISTRIBUTION.md"
echo
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo -e "  1. Configure HTTPS with: ./configure-https.sh"
echo -e "  2. Deploy with manifolded: cd ~/src/repos/manifolded && ./deploy-warp-speed.sh"
echo -e "  3. Send apps to founders with email templates"
echo
echo -e "${MAGENTA}🌌 ∞ Ω ∞ Native Terminals Ready for Distribution! ∞ Ω ∞ 🌌${NC}"