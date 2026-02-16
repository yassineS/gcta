#!/bin/bash
# build_all_platforms.sh
# Master build script - builds static GCTA binaries for all supported platforms
# Usage: ./build_all_platforms.sh <platform> | ./build_all_platforms.sh all

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${BUILD_ROOT:-$HOME/gcta_build}"

print_usage() {
    echo -e "${BLUE}GCTA Static Binary Build Master Script${NC}"
    echo ""
    echo "Usage: $0 [PLATFORM] [BUILD_ROOT]"
    echo ""
    echo "Platforms:"
    echo "  linux-x86_64          Build for Linux x86_64 (Intel/AMD)"
    echo "  linux-arm64           Build for Linux ARM64 (Graviton, etc)"
    echo "  macos-intel           Build for macOS Intel (x86_64)"
    echo "  macos-arm64           Build for macOS Apple Silicon (ARM64)"
    echo "  all                   Build all platforms sequentially"
    echo ""
    echo "Optional:"
    echo "  BUILD_ROOT            Base directory for dependencies (default: ~/gcta_build)"
    echo ""
    echo "Examples:"
    echo "  $0 linux-x86_64                    # Build Linux x86_64 in ~/gcta_build"
    echo "  $0 all ~/custom_build              # Build all platforms in ~/custom_build"
    echo "  BUILD_ROOT=/opt/gcta $0 macos-arm64  # Build macOS ARM64 in /opt/gcta"
}

print_platform_info() {
    local platform=$1
    
    case $platform in
        linux-x86_64)
            echo -e "${BLUE}Platform: Linux x86_64 (Intel MKL)${NC}"
            echo "  BLAS/LAPACK: Intel MKL"
            echo "  Compiler: GCC >= 6.1"
            echo "  Linker: Static for all dependencies"
            ;;
        linux-arm64)
            echo -e "${BLUE}Platform: Linux ARM64 (OpenBLAS)${NC}"
            echo "  BLAS/LAPACK: OpenBLAS"
            echo "  Compiler: GCC >= 6.1"
            echo "  Linker: Static for all dependencies"
            ;;
        macos-intel)
            echo -e "${BLUE}Platform: macOS Intel (Intel MKL)${NC}"
            echo "  BLAS/LAPACK: Intel MKL"
            echo "  Compiler: Clang (Xcode)"
            echo "  Linker: Static for dependencies, dynamic for system libs"
            echo "  macOS: >= 10.13"
            ;;
        macos-arm64)
            echo -e "${BLUE}Platform: macOS Apple Silicon (OpenBLAS)${NC}"
            echo "  BLAS/LAPACK: OpenBLAS"
            echo "  Compiler: Clang (Apple Silicon native)"
            echo "  Linker: Static for dependencies, dynamic for system libs"
            echo "  macOS: >= 11.0 (Big Sur)"
            ;;
    esac
}

build_platform() {
    local platform=$1
    local build_root=$2
    
    print_platform_info "$platform"
    
    case $platform in
        linux-x86_64)
            echo -e "${BLUE}Step 1/2: Building dependencies...${NC}"
            "$SCRIPT_DIR/build_deps_linux_x86_64.sh" "$build_root"
            
            echo ""
            echo -e "${BLUE}Step 2/2: Building GCTA...${NC}"
            "$SCRIPT_DIR/build_gcta_linux_x86_64.sh" "$build_root/gcta" "$build_root"
            ;;
            
        linux-arm64)
            echo -e "${BLUE}Step 1/2: Building dependencies...${NC}"
            "$SCRIPT_DIR/build_deps_linux_arm64.sh" "$build_root"
            
            echo ""
            echo -e "${BLUE}Step 2/2: Building GCTA...${NC}"
            "$SCRIPT_DIR/build_gcta_linux_arm64.sh" "$build_root/gcta" "$build_root"
            ;;
            
        macos-intel)
            echo -e "${BLUE}Step 1/2: Building dependencies...${NC}"
            "$SCRIPT_DIR/build_deps_macos_intel.sh" "$build_root"
            
            echo ""
            echo -e "${BLUE}Step 2/2: Building GCTA...${NC}"
            "$SCRIPT_DIR/build_gcta_macos_intel.sh" "$build_root/gcta" "$build_root"
            ;;
            
        macos-arm64)
            echo -e "${BLUE}Step 1/2: Building dependencies...${NC}"
            "$SCRIPT_DIR/build_deps_macos_arm64.sh" "$build_root"
            
            echo ""
            echo -e "${BLUE}Step 2/2: Building GCTA...${NC}"
            "$SCRIPT_DIR/build_gcta_macos_arm64.sh" "$build_root/gcta" "$build_root"
            ;;
            
        *)
            echo -e "${RED}Unknown platform: $platform${NC}"
            exit 1
            ;;
    esac
}

# Parse arguments
PLATFORM="${1:-}"
if [ -n "$2" ]; then
    BUILD_ROOT="$(mkdir -p "$2" && cd "$2" && pwd)"
fi

case "$PLATFORM" in
    ""|"-h"|"--help"|"help")
        print_usage
        exit 0
        ;;
    all)
        echo -e "${BLUE}Building all supported platforms${NC}"
        echo "Build root: $BUILD_ROOT"
        echo ""
        
        platforms=("linux-x86_64" "linux-arm64" "macos-intel" "macos-arm64")
        
        for plat in "${platforms[@]}"; do
            echo "=================================================="
            echo ""
            build_platform "$plat" "$BUILD_ROOT"
            echo ""
            echo -e "${GREEN}✓ $plat build completed${NC}"
            echo ""
        done
        
        echo "=================================================="
        echo -e "${GREEN}All platforms built successfully!${NC}"
        echo ""
        echo "Binaries location:"
        echo "  Linux x86_64: $BUILD_ROOT/gcta/build_linux_x86_64/gcta64"
        echo "  Linux ARM64:  $BUILD_ROOT/gcta/build_linux_arm64/gcta64"
        echo "  macOS Intel:  $BUILD_ROOT/gcta/build_macos_intel/gcta64"
        echo "  macOS ARM64:  $BUILD_ROOT/gcta/build_macos_arm64/gcta64"
        ;;
    linux-x86_64|linux-arm64|macos-intel|macos-arm64)
        echo ""
        build_platform "$PLATFORM" "$BUILD_ROOT"
        
        case "$PLATFORM" in
            linux-x86_64)
                BINARY_PATH="$BUILD_ROOT/gcta/build_linux_x86_64/gcta64"
                ;;
            linux-arm64)
                BINARY_PATH="$BUILD_ROOT/gcta/build_linux_arm64/gcta64"
                ;;
            macos-intel)
                BINARY_PATH="$BUILD_ROOT/gcta/build_macos_intel/gcta64"
                ;;
            macos-arm64)
                BINARY_PATH="$BUILD_ROOT/gcta/build_macos_arm64/gcta64"
                ;;
        esac
        
        echo ""
        echo -e "${GREEN}Build completed successfully!${NC}"
        echo "Binary: $BINARY_PATH"
        ;;
    *)
        echo -e "${RED}Unknown platform: $PLATFORM${NC}"
        print_usage
        exit 1
        ;;
esac

echo ""
