#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Appendix — Apple Platforms Build Script (macOS Universal + iOS XCFramework)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUST_DIR="${ROOT_DIR}/rust"
INCLUDE_DIR="${ROOT_DIR}/include"
MACOS_OUT_DIR="${ROOT_DIR}/app/macos"
IOS_OUT_DIR="${ROOT_DIR}/app/ios/Frameworks"

echo "=== Building Appendix for Apple Platforms ==="
echo "Project Root: ${ROOT_DIR}"

mkdir -p "${MACOS_OUT_DIR}"
mkdir -p "${IOS_OUT_DIR}"

# 1. macOS Universal Dynamic Library (arm64 + x86_64)
echo "--> Compiling for macOS (Apple Silicon + Intel)..."
cd "${RUST_DIR}"

rustup target add aarch64-apple-darwin x86_64-apple-darwin || true

cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin

echo "--> Creating macOS Universal Binary (lipo)..."
lipo -create \
    "${RUST_DIR}/target/aarch64-apple-darwin/release/libappendix_core.dylib" \
    "${RUST_DIR}/target/x86_64-apple-darwin/release/libappendix_core.dylib" \
    -output "${MACOS_OUT_DIR}/libappendix_core.dylib"

echo "✓ Created Universal dylib: ${MACOS_OUT_DIR}/libappendix_core.dylib"

# 2. iOS Static Libraries & XCFramework
echo "--> Compiling for iOS Devices and Simulators..."
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios || true

cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target x86_64-apple-ios

echo "--> Combining iOS Simulator Binaries..."
mkdir -p "${RUST_DIR}/target/ios-sim-universal/release"
lipo -create \
    "${RUST_DIR}/target/aarch64-apple-ios-sim/release/libappendix_core.a" \
    "${RUST_DIR}/target/x86_64-apple-ios/release/libappendix_core.a" \
    -output "${RUST_DIR}/target/ios-sim-universal/release/libappendix_core.a"

echo "--> Creating AppendixCore.xcframework..."
rm -rf "${IOS_OUT_DIR}/AppendixCore.xcframework"

xcodebuild -create-xcframework \
    -library "${RUST_DIR}/target/aarch64-apple-ios/release/libappendix_core.a" \
    -headers "${INCLUDE_DIR}" \
    -library "${RUST_DIR}/target/ios-sim-universal/release/libappendix_core.a" \
    -headers "${INCLUDE_DIR}" \
    -output "${IOS_OUT_DIR}/AppendixCore.xcframework"

echo "✓ Created XCFramework: ${IOS_OUT_DIR}/AppendixCore.xcframework"
echo "=== Apple Build Complete ==="
