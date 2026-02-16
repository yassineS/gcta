#!/bin/bash
# build_gcta_linux_arm64.sh
# Builds GCTA static binary on Linux ARM64 (aarch64)

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

echo -e "${BLUE}Building GCTA static binary for Linux ARM64 (aarch64)${NC}"
echo "GCTA source: $GCTA_SRC"
echo "Build root: $GCTA_BUILD_ROOT"

# Verify environment
if [ -z "$OPENBLAS" ]; then
    echo "ERROR: OPENBLAS not set"
    echo "Solution: Run build_deps_linux_arm64.sh first"
    exit 1
fi

# Set environment variables
export OPENBLAS=$GCTA_BUILD_ROOT/openblas_pkg
export EIGEN3_INCLUDE_DIR=$GCTA_BUILD_ROOT/dependencies/eigen-3.3.7
export SPECTRA_LIB=$GCTA_BUILD_ROOT/dependencies/spectra-v1.2.0/include
export BOOST_LIB=$GCTA_BUILD_ROOT/boost_pkg/include

export LIBRARY_PATH=$GCTA_BUILD_ROOT/zlib_pkg/lib:$GCTA_BUILD_ROOT/zstd_pkg/lib:$GCTA_BUILD_ROOT/gsl_pkg/lib:$GCTA_BUILD_ROOT/sqlite_pkg/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$GCTA_BUILD_ROOT/zlib_pkg/lib:$GCTA_BUILD_ROOT/zstd_pkg/lib:$GCTA_BUILD_ROOT/gsl_pkg/lib:$GCTA_BUILD_ROOT/sqlite_pkg/lib:$LD_LIBRARY_PATH

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
BUILD_DIR="$GCTA_SRC/build_linux_arm64"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo -e "${BLUE}Configuring GCTA with CMake...${NC}"
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-march=native -static-libgcc -static-libstdc++" \
      -DCMAKE_C_FLAGS="-march=native" \
      .. > /dev/null 2>&1

echo -e "${BLUE}Building GCTA (this may take several minutes)...${NC}"
make -j$(nproc) 2>&1 | tail -20

if [ -f "./gcta64" ]; then
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    echo "Binary location: $(pwd)/gcta64"
    echo ""
    echo "Binary information:"
    file ./gcta64
    echo ""
    echo "Checking dependencies:"
    ldd ./gcta64 | head -20
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
