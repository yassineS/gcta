#!/bin/bash
# build_deps_macos_intel.sh
# Builds all dependencies for GCTA on macOS Intel (x86_64)

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <build_root_directory>"
    echo "Example: $0 ~/gcta_build"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

BUILD_ROOT="$1"
export GCTA_BUILD_ROOT="$(cd "$1" && pwd)"

echo -e "${BLUE}Building GCTA dependencies for macOS Intel (x86_64)${NC}"
echo "Build root: $GCTA_BUILD_ROOT"

# Check for required tools
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install MKL via Homebrew (easiest approach)
if ! brew list intel-mkl &> /dev/null; then
    echo -e "${BLUE}Installing Intel MKL via Homebrew...${NC}"
    brew install intel-mkl
fi
export MKLROOT=$(brew --prefix intel-mkl)
echo -e "${GREEN}✓ MKL location: $MKLROOT${NC}"

# Install other build tools if needed
echo -e "${BLUE}Checking build tools...${NC}"
brew install gcc boost > /dev/null 2>&1 || true

mkdir -p "$GCTA_BUILD_ROOT/dependencies"
cd "$GCTA_BUILD_ROOT/dependencies"

declare -a DEP_FILES=(
    "eigen-3.3.7.tar.gz"
    "spectra-1.0.0.tar.gz"
    "boost_1_75_0.tar.gz"
    "zlib-1.3.1.tar.gz"
    "zstd-1.5.0.tar.gz"
    "gsl-2.7.tar.gz"
    "sqlite-autoconf-3510200.tar.gz"
)

declare -a DEP_URLS=(
    "https://gitlab.com/libeigen/eigen/-/archive/3.3.7/eigen-3.3.7.tar.gz"
    "https://github.com/yixuan/spectra/archive/v1.0.0.tar.gz"
    "https://boostorg.jfrog.io/artifactory/main/release/1.75.0/source/boost_1_75_0.tar.gz"
    "https://zlib.net/zlib-1.3.1.tar.gz"
    "https://github.com/facebook/zstd/releases/download/v1.5.0/zstd-1.5.0.tar.gz"
    "https://ftpmirror.gnu.org/gsl/gsl-2.7.tar.gz"
    "https://www.sqlite.org/2026/sqlite-autoconf-3510200.tar.gz"
)

echo -e "${BLUE}Downloading dependencies...${NC}"
for i in "${!DEP_FILES[@]}"; do
    file="${DEP_FILES[$i]}"
    url="${DEP_URLS[$i]}"
    if [ ! -f "$file" ]; then
        echo "Downloading $file..."
        curl --retry 3 --retry-delay 5 -L -o "$file" "$url" || {
            echo "Failed to download $file"
            exit 1
        }
    else
        echo "Found cached $file"
    fi
done

# Eigen (header-only)
echo -e "${BLUE}Setting up Eigen...${NC}"
if [ ! -d "eigen-3.3.7" ]; then
    tar -xzf eigen-3.3.7.tar.gz
fi
export EIGEN3_INCLUDE_DIR=$GCTA_BUILD_ROOT/dependencies/eigen-3.3.7
echo -e "${GREEN}✓ Eigen set${NC}"

# Spectra (header-only)
echo -e "${BLUE}Setting up Spectra...${NC}"
if [ ! -d "spectra-v1.2.0" ]; then
    tar -xzf spectra-1.2.0.tar.gz
fi
export SPECTRA_LIB=$GCTA_BUILD_ROOT/dependencies/spectra-v1.2.0/include
echo -e "${GREEN}✓ Spectra set${NC}"

# Boost
echo -e "${BLUE}Building Boost...${NC}"
if [ ! -d "boost_1_75_0" ]; then
    tar -xzf boost_1_75_0.tar.gz
fi
cd boost_1_75_0
if [ ! -f "$GCTA_BUILD_ROOT/boost_pkg/lib/libboost_system.a" ]; then
    ./bootstrap.sh --prefix=$GCTA_BUILD_ROOT/boost_pkg > /dev/null
    ./b2 --prefix=$GCTA_BUILD_ROOT/boost_pkg \
         architecture=x86 \
         address-model=64 \
         link=static \
         threading=multi \
         variant=release \
         cxxflags="-fPIC" \
         -j$(sysctl -n hw.ncpu) \
         install > /dev/null
fi
export BOOST_LIB=$GCTA_BUILD_ROOT/boost_pkg/include
echo -e "${GREEN}✓ Boost built${NC}"
cd ..

# zlib
echo -e "${BLUE}Building zlib...${NC}"
if [ ! -d "zlib-1.3.1" ]; then
    tar -xzf zlib-1.3.1.tar.gz
fi
cd zlib-1.3.1
if [ ! -f "$GCTA_BUILD_ROOT/zlib_pkg/lib/libz.a" ]; then
    ./configure --prefix=$GCTA_BUILD_ROOT/zlib_pkg --static > /dev/null
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
if [ ! -f "$GCTA_BUILD_ROOT/zstd_pkg/lib/libzstd.a" ]; then
    cd zstd-1.5.0/build/cmake
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=$GCTA_BUILD_ROOT/zstd_pkg \
          -DCMAKE_SYSTEM_NAME=Darwin \
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
if [ ! -f "$GCTA_BUILD_ROOT/gsl_pkg/lib/libgsl.a" ]; then
    ./configure --prefix=$GCTA_BUILD_ROOT/gsl_pkg --disable-shared --enable-static > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ GSL built${NC}"
cd ..

# sqlite3
echo -e "${BLUE}Building SQLite3...${NC}"
if [ ! -d "sqlite-autoconf-3510200" ]; then
    tar -xzf sqlite-autoconf-3510200.tar.gz
fi
cd sqlite-autoconf-3510200
if [ ! -f "$GCTA_BUILD_ROOT/sqlite_pkg/lib/libsqlite3.a" ]; then
    ./configure --prefix=$GCTA_BUILD_ROOT/sqlite_pkg --disable-shared --enable-static > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ SQLite3 built${NC}"

echo ""
echo -e "${GREEN}All macOS Intel dependencies built successfully!${NC}"
echo ""
echo "Set these environment variables for building GCTA:"
echo ""
echo "export GCTA_BUILD_ROOT=$GCTA_BUILD_ROOT"
echo "export MKLROOT=$MKLROOT"
echo "export EIGEN3_INCLUDE_DIR=$EIGEN3_INCLUDE_DIR"
echo "export SPECTRA_LIB=$SPECTRA_LIB"
echo "export BOOST_LIB=$BOOST_LIB"
echo ""
echo "Then run: ./build_gcta_macos_intel.sh <gcta_source_dir>"
