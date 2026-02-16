#!/bin/bash
# build_deps_macos_arm64.sh
# Builds all dependencies for GCTA on macOS Apple Silicon (ARM64)
# Note: This should be run on Apple Silicon hardware or with cross-compilation setup

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <build_root_directory>"
    echo "Example: $0 ~/gcta_build"
    echo ""
    echo "NOTE: This script should be run on macOS Apple Silicon hardware"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

BUILD_ROOT="$1"
export GCTA_BUILD_ROOT="$(cd "$1" && pwd)"

# Verify we're on ARM64 macOS
if [ "$(uname -m)" != "arm64" ]; then
    echo -e "${YELLOW}WARNING: This script is designed for Apple Silicon (ARM64)${NC}"
    echo "You are running on: $(uname -m)"
    echo "Cross-compilation support is limited. Proceed at your own risk."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}Building GCTA dependencies for macOS Apple Silicon (ARM64)${NC}"
echo "Build root: $GCTA_BUILD_ROOT"

# Check for required tools
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Note: Intel MKL support for Apple Silicon is limited
# Using OpenBLAS instead
echo -e "${BLUE}Installing build tools via Homebrew...${NC}"
brew install gcc > /dev/null 2>&1 || true

mkdir -p "$GCTA_BUILD_ROOT/dependencies"
cd "$GCTA_BUILD_ROOT/dependencies"

declare -A DEPS=(
    ["eigen-3.3.7.tar.gz"]="https://gitlab.com/libeigen/eigen/-/archive/3.3.7/eigen-3.3.7.tar.gz"
    ["spectra-1.0.0.tar.gz"]="https://github.com/yixuan/spectra/archive/v1.0.0.tar.gz"
    ["boost_1_75_0.tar.gz"]="https://boostorg.jfrog.io/artifactory/main/release/1.75.0/source/boost_1_75_0.tar.gz"
    ["zlib-1.2.11.tar.gz"]="https://zlib.net/zlib-1.2.11.tar.gz"
    ["zstd-1.5.0.tar.gz"]="https://github.com/facebook/zstd/releases/download/v1.5.0/zstd-1.5.0.tar.gz"
    ["gsl-2.7.tar.gz"]="https://ftpmirror.gnu.org/gsl/gsl-2.7.tar.gz"
    ["sqlite-autoconf-3400000.tar.gz"]="https://www.sqlite.org/2023/sqlite-autoconf-3400000.tar.gz"
    ["OpenBLAS-0.3.21.tar.gz"]="https://github.com/xianyi/OpenBLAS/releases/download/v0.3.21/OpenBLAS-0.3.21.tar.gz"
)

echo -e "${BLUE}Downloading dependencies...${NC}"
for file in "${!DEPS[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Downloading $file..."
        curl -L -o "$file" "${DEPS[$file]}" || {
            echo "Failed to download $file"
            exit 1
        }
    else
        echo "Found cached $file"
    fi
done

# Build OpenBLAS for ARM64
echo -e "${BLUE}Building OpenBLAS for ARM64...${NC}"
if [ ! -d "OpenBLAS-0.3.21" ]; then
    tar -xzf OpenBLAS-0.3.21.tar.gz
fi
cd OpenBLAS-0.3.21
if [ ! -f "$GCTA_BUILD_ROOT/openblas_arm64_pkg/lib/libopenblas.a" ]; then
    make BINARY=64 HOSTCC=clang FC=gfortran \
         CFLAGS="-march=native -O3 -fPIC" \
         FFLAGS="-march=native -O3" \
         TARGET=NEOVERSEN1 \
         PREFIX=$GCTA_BUILD_ROOT/openblas_arm64_pkg \
         -j$(sysctl -n hw.ncpu) > /dev/null
    make install PREFIX=$GCTA_BUILD_ROOT/openblas_arm64_pkg > /dev/null
fi
export OPENBLAS=$GCTA_BUILD_ROOT/openblas_arm64_pkg
echo -e "${GREEN}✓ OpenBLAS built${NC}"
cd ..

# Eigen (header-only)
echo -e "${BLUE}Setting up Eigen...${NC}"
if [ ! -d "eigen-3.3.7" ]; then
    tar -xzf eigen-3.3.7.tar.gz
fi
export EIGEN3_INCLUDE_DIR=$GCTA_BUILD_ROOT/dependencies/eigen-3.3.7
echo -e "${GREEN}✓ Eigen set${NC}"

# Spectra (header-only)
echo -e "${BLUE}Setting up Spectra...${NC}"
if [ ! -d "spectra-1.0.0" ]; then
    tar -xzf spectra-1.0.0.tar.gz
fi
export SPECTRA_LIB=$GCTA_BUILD_ROOT/dependencies/spectra-1.0.0/include
echo -e "${GREEN}✓ Spectra set${NC}"

# Boost
echo -e "${BLUE}Building Boost...${NC}"
if [ ! -d "boost_1_75_0" ]; then
    tar -xzf boost_1_75_0.tar.gz
fi
cd boost_1_75_0
if [ ! -f "$GCTA_BUILD_ROOT/boost_pkg_arm64/lib/libboost_system.a" ]; then
    ./bootstrap.sh --prefix=$GCTA_BUILD_ROOT/boost_pkg_arm64 > /dev/null
    ./b2 --prefix=$GCTA_BUILD_ROOT/boost_pkg_arm64 \
         architecture=arm \
         address-model=64 \
         link=static \
         threading=multi \
         variant=release \
         cxxflags="-fPIC" \
         -j$(sysctl -n hw.ncpu) \
         install > /dev/null
fi
export BOOST_LIB=$GCTA_BUILD_ROOT/boost_pkg_arm64/include
echo -e "${GREEN}✓ Boost built${NC}"
cd ..

# zlib
echo -e "${BLUE}Building zlib...${NC}"
if [ ! -d "zlib-1.2.11" ]; then
    tar -xzf zlib-1.2.11.tar.gz
fi
cd zlib-1.2.11
if [ ! -f "$GCTA_BUILD_ROOT/zlib_pkg_arm64/lib/libz.a" ]; then
    ./configure --prefix=$GCTA_BUILD_ROOT/zlib_pkg_arm64 --static > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ zlib built${NC}"
cd ..

# zstd
echo -e "${BLUE}Building zstd...${NC}"
if [ ! -d "zstd-1.5.0" ]; then
    tar -xzf zstd-1.5.0.tar.gz
fi
if [ ! -f "$GCTA_BUILD_ROOT/zstd_pkg_arm64/lib/libzstd.a" ]; then
    cd zstd-1.5.0/build/cmake
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=$GCTA_BUILD_ROOT/zstd_pkg_arm64 \
          -DCMAKE_SYSTEM_NAME=Darwin \
          -DCMAKE_SYSTEM_PROCESSOR=arm64 \
          -DZSTD_BUILD_SHARED=OFF \
          -DZSTD_BUILD_STATIC=ON \
          .. > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ zstd built${NC}"
cd $GCTA_BUILD_ROOT/dependencies

# gsl
echo -e "${BLUE}Building GSL...${NC}"
if [ ! -d "gsl-2.7" ]; then
    tar -xzf gsl-2.7.tar.gz
fi
cd gsl-2.7
if [ ! -f "$GCTA_BUILD_ROOT/gsl_pkg_arm64/lib/libgsl.a" ]; then
    ./configure --prefix=$GCTA_BUILD_ROOT/gsl_pkg_arm64 --disable-shared --enable-static > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ GSL built${NC}"
cd ..

# sqlite3
echo -e "${BLUE}Building SQLite3...${NC}"
if [ ! -d "sqlite-autoconf-3400000" ]; then
    tar -xzf sqlite-autoconf-3400000.tar.gz
fi
cd sqlite-autoconf-3400000
if [ ! -f "$GCTA_BUILD_ROOT/sqlite_pkg_arm64/lib/libsqlite3.a" ]; then
    ./configure --prefix=$GCTA_BUILD_ROOT/sqlite_pkg_arm64 --disable-shared --enable-static > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ SQLite3 built${NC}"

echo ""
echo -e "${GREEN}All macOS ARM64 dependencies built successfully!${NC}"
echo ""
echo "Set these environment variables for building GCTA:"
echo ""
echo "export GCTA_BUILD_ROOT=$GCTA_BUILD_ROOT"
echo "export OPENBLAS=$OPENBLAS"
echo "export EIGEN3_INCLUDE_DIR=$EIGEN3_INCLUDE_DIR"
echo "export SPECTRA_LIB=$SPECTRA_LIB"
echo "export BOOST_LIB=$BOOST_LIB"
echo ""
echo "Then run: ./build_gcta_macos_arm64.sh <gcta_source_dir>"
