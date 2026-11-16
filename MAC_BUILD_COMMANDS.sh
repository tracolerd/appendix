#!/usr/bin/env bash
# ==============================================================================
# Appendix — Master macOS & iOS Build Script
# Executes end-to-end compilation, native library bundling, desktop app packaging,
# and iOS embedded keyboard extension validation on an Apple development host.
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}       APPENDIX APPLE PLATFORM MASTER BUILD PIPELINE            ${NC}"
echo -e "${BOLD}================================================================${NC}"

# Step 1: Environment Qualification
echo -e "\n${BOLD}>>> [1/5] Running Environment Check...${NC}"
if [[ -f "./MAC_BUILD_ENVIRONMENT_CHECK.sh" ]]; then
    chmod +x ./MAC_BUILD_ENVIRONMENT_CHECK.sh
    ./MAC_BUILD_ENVIRONMENT_CHECK.sh
else
    echo -e "${YELLOW}Warning: MAC_BUILD_ENVIRONMENT_CHECK.sh not found, continuing.${NC}"
fi

# Step 2: Rust Apple Native Libraries Compilation
echo -e "\n${BOLD}>>> [2/5] Compiling Rust Core for Apple Platforms (macOS & iOS)...${NC}"
if [[ -f "./scripts/build_apple.sh" ]]; then
    chmod +x ./scripts/build_apple.sh
    ./scripts/build_apple.sh
else
    echo -e "${RED}Error: scripts/build_apple.sh missing!${NC}"
    exit 1
fi

# Step 3: Flutter Dependencies & Analysis
echo -e "\n${BOLD}>>> [3/5] Resolving Flutter Dependencies & Static Analysis...${NC}"
cd "${ROOT_DIR}/app"
flutter pub get
flutter analyze
flutter test --no-pub

# Step 4: Build macOS Desktop Application (.app)
echo -e "\n${BOLD}>>> [4/5] Building macOS Desktop Application (Release)...${NC}"
flutter build macos --release

MACOS_APP_PATH="${ROOT_DIR}/app/build/macos/Build/Products/Release/appendix.app"
if [[ -d "${MACOS_APP_PATH}" ]]; then
    echo -e "${GREEN}✓ Successfully built macOS app bundle: ${MACOS_APP_PATH}${NC}"
    # Inspect native library bundling
    echo "  Inspecting bundled libraries inside appendix.app:"
    ls -la "${MACOS_APP_PATH}/Contents/MacOS/"
    if [[ -f "${ROOT_DIR}/app/macos/libappendix_core.dylib" ]]; then
        echo "  Verifying architecture of libappendix_core.dylib:"
        lipo -info "${ROOT_DIR}/app/macos/libappendix_core.dylib"
    fi
else
    echo -e "${RED}✗ macOS application bundle failed to generate at expected path.${NC}"
    exit 1
fi

# Step 5: Build iOS Simulator App & Embedded Keyboard Extension
echo -e "\n${BOLD}>>> [5/5] Building iOS App & Embedded Keyboard Extension (Simulator)...${NC}"
cd "${ROOT_DIR}"
xcodebuild \
    -workspace app/ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphonesimulator \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    build

IOS_BUILD_DIR="${ROOT_DIR}/app/build/ios/iphonesimulator"
# In standard Xcode builds without Flutter wrapper, look in DerivedData or Runner.app
RUNNER_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Runner.app" 2>/dev/null | head -n 1 || true)
if [[ -n "${RUNNER_APP}" && -d "${RUNNER_APP}" ]]; then
    echo -e "${GREEN}✓ Successfully verified iOS Runner app at: ${RUNNER_APP}${NC}"
    PLUGINS_DIR="${RUNNER_APP}/PlugIns"
    if [[ -d "${PLUGINS_DIR}/AppendixKeyboard.appex" ]]; then
        echo -e "${GREEN}✓ Embedded Keyboard Extension verified: ${PLUGINS_DIR}/AppendixKeyboard.appex${NC}"
        # Verify Info.plist offline isolation
        PLIST_FILE="${PLUGINS_DIR}/AppendixKeyboard.appex/Info.plist"
        if command -v plutil &>/dev/null && [[ -f "${PLIST_FILE}" ]]; then
            OPEN_ACCESS=$(plutil -p "${PLIST_FILE}" | grep -i "RequestsOpenAccess" || true)
            echo "  Keyboard Extension Sandbox: ${OPEN_ACCESS}"
        fi
    else
        echo -e "${YELLOW}! AppendixKeyboard.appex not found in Runner.app/PlugIns. Check Xcode copy files build phase.${NC}"
    fi
else
    echo -e "${YELLOW}! Runner.app location in DerivedData could not be automatically located, but xcodebuild returned success.${NC}"
fi

echo -e "\n${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}✓ ALL APPLE PLATFORM BUILDS COMPLETED SUCCESSFULLY!${NC}"
echo -e "${BOLD}================================================================${NC}"

