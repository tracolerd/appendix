#!/usr/bin/env bash
# ==============================================================================
# Appendix — macOS & iOS Development Environment Qualification Script
# Validates host architecture, Apple SDKs, Flutter, Rust, and simulator runtimes.
# ==============================================================================

set -uo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}      APPENDIX APPLE ENVIRONMENT QUALIFICATION AUDIT            ${NC}"
echo -e "${BOLD}================================================================${NC}"

ERRORS=0
WARNINGS=0

# 1. Host Architecture & Kernel
echo -e "\n${BOLD}[1/8] Host System & Hardware Architecture${NC}"
ARCH=$(uname -m 2>/dev/null || echo "Unknown")
echo "  CPU Architecture:  ${ARCH}"

if [[ "${ARCH}" == "arm64" ]]; then
    echo -e "  ${GREEN}✓ Apple Silicon (ARM64) detected — optimal for unified memory & neural acceleration.${NC}"
elif [[ "${ARCH}" == "x86_64" ]]; then
    echo -e "  ${YELLOW}! Intel x86_64 Mac detected — Metal/Accelerate supported, Rosetta not required.${NC}"
else
    echo -e "  ${RED}✗ Unsupported architecture: ${ARCH}${NC}"
    ((ERRORS++))
fi

if command -v sw_vers &>/dev/null; then
    PRODUCT_NAME=$(sw_vers -productName)
    PRODUCT_VER=$(sw_vers -productVersion)
    BUILD_VER=$(sw_vers -buildVersion)
    echo "  Operating System:  ${PRODUCT_NAME} ${PRODUCT_VER} (Build ${BUILD_VER})"
    MAJOR_VER=$(echo "${PRODUCT_VER}" | cut -d. -f1)
    if [[ ${MAJOR_VER} -ge 12 ]]; then
        echo -e "  ${GREEN}✓ macOS version meets requirement (>= 12.0 Monterey).${NC}"
    else
        echo -e "  ${RED}✗ macOS ${PRODUCT_VER} is below minimum requirement (12.0).${NC}"
        ((ERRORS++))
    fi
else
    echo -e "  ${RED}✗ sw_vers not found. Are you running on macOS?${NC}"
    ((ERRORS++))
fi

# 2. Disk Space
echo -e "\n${BOLD}[2/8] Disk Space Evaluation${NC}"
FREE_KB=$(df -k . | awk 'NR==2 {print $4}')
FREE_GB=$((FREE_KB / 1024 / 1024))
echo "  Available Disk Space in Workdir: ${FREE_GB} GB"
if [[ ${FREE_GB} -ge 15 ]]; then
    echo -e "  ${GREEN}✓ Ample disk space available (>= 15 GB).${NC}"
elif [[ ${FREE_GB} -ge 5 ]]; then
    echo -e "  ${YELLOW}! Low disk space (${FREE_GB} GB). Xcode and Flutter builds require >= 5 GB.${NC}"
    ((WARNINGS++))
else
    echo -e "  ${RED}✗ Insufficient disk space (${FREE_GB} GB). Minimum 5 GB required.${NC}"
    ((ERRORS++))
fi

# 3. Xcode Toolchain & CLI Tools
echo -e "\n${BOLD}[3/8] Apple Xcode Development Environment${NC}"
if command -v xcodebuild &>/dev/null; then
    XCODE_INFO=$(xcodebuild -version 2>/dev/null || echo "Error querying xcodebuild")
    echo "${XCODE_INFO}" | sed 's/^/  /'
    XCODE_DEV_DIR=$(xcode-select -p 2>/dev/null || echo "Unknown")
    echo "  Developer Directory: ${XCODE_DEV_DIR}"
    if echo "${XCODE_DEV_DIR}" | grep -q "CommandLineTools"; then
        echo -e "  ${YELLOW}! Active directory is standalone Command Line Tools. Full Xcode app is required for iOS builds.${NC}"
        echo "    Remedy: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        ((WARNINGS++))
    else
        echo -e "  ${GREEN}✓ Xcode installation detected.${NC}"
    fi
else
    echo -e "  ${RED}✗ xcodebuild not found. Install Xcode from the Mac App Store.${NC}"
    ((ERRORS++))
fi

# 4. iOS Simulator Runtimes
echo -e "\n${BOLD}[4/8] iOS Simulator Runtimes${NC}"
if command -v xcrun &>/dev/null; then
    RUNTIMES=$(xcrun simctl list runtimes 2>/dev/null | grep -i "iOS" || true)
    if [[ -n "${RUNTIMES}" ]]; then
        echo "${RUNTIMES}" | sed 's/^/  /'
        echo -e "  ${GREEN}✓ iOS Simulator runtime available.${NC}"
    else
        echo -e "  ${YELLOW}! No iOS Simulator runtimes found.${NC}"
        echo "    Remedy: Xcode -> Settings -> Platforms -> Download iOS Simulator."
        ((WARNINGS++))
    fi
else
    echo -e "  ${RED}✗ xcrun utility not available.${NC}"
    ((ERRORS++))
fi

# 5. Rust Toolchain & Apple Targets
echo -e "\n${BOLD}[5/8] Rust Compiler & Target Architectures${NC}"
if command -v rustc &>/dev/null; then
    echo "  Rust Compiler:     $(rustc --version)"
    echo "  Cargo Package Mgr: $(cargo --version)"
    if command -v rustup &>/dev/null; then
        INSTALLED_TARGETS=$(rustup target list --installed 2>/dev/null)
        echo "  Installed Targets:"
        echo "${INSTALLED_TARGETS}" | sed 's/^/    - /'

        REQUIRED_TARGETS=("aarch64-apple-darwin" "aarch64-apple-ios" "aarch64-apple-ios-sim")
        for T in "${REQUIRED_TARGETS[@]}"; do
            if echo "${INSTALLED_TARGETS}" | grep -q "^${T}$"; then
                echo -e "    ${GREEN}✓ Target ${T} installed.${NC}"
            else
                echo -e "    ${RED}✗ Missing required target: ${T}${NC}"
                echo "      Remedy: rustup target add ${T}"
                ((ERRORS++))
            fi
        done
    else
        echo -e "  ${YELLOW}! rustup not found in PATH.${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "  ${RED}✗ Rust compiler (rustc) not found. Install via https://rustup.rs${NC}"
    ((ERRORS++))
fi

# 6. Flutter SDK
echo -e "\n${BOLD}[6/8] Flutter SDK & Dart Runtime${NC}"
if command -v flutter &>/dev/null; then
    echo "  Flutter SDK: $(flutter --version | head -n 1)"
    echo -e "  ${GREEN}✓ Flutter CLI detected.${NC}"
else
    echo -e "  ${RED}✗ Flutter CLI not found in PATH. Install Flutter 3.50+ from flutter.dev${NC}"
    ((ERRORS++))
fi

# 7. CocoaPods (for iOS plugins if applicable)
echo -e "\n${BOLD}[7/8] CocoaPods Dependency Manager${NC}"
if command -v pod &>/dev/null; then
    echo "  CocoaPods:   $(pod --version)"
    echo -e "  ${GREEN}✓ CocoaPods installed.${NC}"
else
    echo -e "  ${YELLOW}! CocoaPods not found. Install via 'sudo gem install cocoapods' or 'brew install cocoapods'.${NC}"
    ((WARNINGS++))
fi

# 8. Xcode Workspace Verification
echo -e "\n${BOLD}[8/8] Appendix Xcode Workspace Verification${NC}"
if [[ -d "app/ios/Runner.xcworkspace" ]] && command -v xcodebuild &>/dev/null; then
    SCHEMES=$(xcodebuild -list -workspace app/ios/Runner.xcworkspace 2>/dev/null | grep -A 10 "Schemes:" || true)
    if [[ -n "${SCHEMES}" ]]; then
        echo "${SCHEMES}" | sed 's/^/  /'
        echo -e "  ${GREEN}✓ Xcode Workspace and Schemes successfully verified.${NC}"
    else
        echo -e "  ${RED}✗ Failed to list schemes from app/ios/Runner.xcworkspace${NC}"
        ((ERRORS++))
    fi
else
    echo -e "  ${YELLOW}! Skipping workspace scheme check (missing workspace directory or xcodebuild).${NC}"
fi

echo -e "\n----------------------------------------------------------------"
if [[ ${ERRORS} -eq 0 && ${WARNINGS} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}[QUALIFIED] Environment fully qualified for macOS and iOS Appendix builds.${NC}"
    exit 0
elif [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${YELLOW}${BOLD}[QUALIFIED WITH WARNINGS] Environment can build, but check ${WARNINGS} warning(s) above.${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}[UNQUALIFIED] ${ERRORS} critical error(s) detected. Fix prerequisites before building.${NC}"
    exit 1
fi

