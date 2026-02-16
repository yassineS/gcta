#!/bin/bash
# build_gcta_macos_arm64.sh
# Builds GCTA static binary on macOS Apple Silicon (ARM64)

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <gcta_source_directory> <build_root_directory>"
    echo "Example: $0 ~/gcta ~/gcta_build"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

GCTA_SRC="$(cd "$1" && pwd)"
GCTA_BUILD_ROOT="$(cd "$2" && pwd)"

echo -e "${BLUE}Building GCTA static binary for macOS Apple Silicon (ARM64)${NC}"
echo "GCTA source: $GCTA_SRC"
echo "Build root: $GCTA_BUILD_ROOT"

# Set environment variables
export OPENBLAS=$GCTA_BUILD_ROOT/openblas_arm64_pkg
export EIGEN3_INCLUDE_DIR=$GCTA_BUILD_ROOT/dependencies/eigen-3.3.7
export SPECTRA_LIB=$GCTA_BUILD_ROOT/dependencies/spectra-v1.2.0/include
export BOOST_LIB=$GCTA_BUILD_ROOT/boost_pkg_arm64/include

export LIBRARY_PATH=$GCTA_BUILD_ROOT/zlib_pkg_arm64/lib:$GCTA_BUILD_ROOT/zstd_pkg_arm64/lib:$GCTA_BUILD_ROOT/gsl_pkg_arm64/lib:$GCTA_BUILD_ROOT/sqlite_pkg_arm64/lib:$LIBRARY_PATH

# Setup GCTA source if needed
if [ ! -d "$GCTA_SRC/.git" ]; then
    echo -e "${BLUE}Cloning GCTA...${NC}"
    git clone https://github.com/jianyangqt/gcta.git "$GCTA_SRC"
fi

cd "$GCTA_SRC"

# Update submodules
echo -e "${BLUE}Updating submodules...${NC}"
git submodule update --init --recursive > /dev/null

# Create build directory
BUILD_DIR="$GCTA_SRC/build_macos_arm64"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo -e "${BLUE}Configuring GCTA with CMake for macOS ARM64...${NC}"
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_SYSTEM_NAME=Darwin \
      -DCMAKE_SYSTEM_PROCESSOR=arm64 \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_CXX_FLAGS="-mmacosx-version-min=11.0" \
      -DCMAKE_C_FLAGS="-mmacosx-version-min=11.0" \
      .. > /dev/null 2>&1

echo -e "${BLUE}Building GCTA (this may take several minutes)...${NC}"
make -j$(sysctl -n hw.ncpu) 2>&1 | tail -20

if [ -f "./gcta64" ]; then
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    echo "Binary location: $(pwd)/gcta64"
    echo ""
    echo "Binary information:"
    file ./gcta64
    echo ""
    echo "Linked libraries (excluding system):"
    otool -L ./gcta64 | grep -v "/usr/lib" | grep -v "@" | head -15
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
