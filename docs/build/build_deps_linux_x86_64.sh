#!/bin/bash
# build_deps_linux_x86_64.sh
# Builds all dependencies for GCTA on Linux x86_64 with Intel MKL

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}Building GCTA dependencies for Linux x86_64 with Intel MKL${NC}"
echo "Build root: $GCTA_BUILD_ROOT"

# Verify MKL is available
if [ -z "$MKLROOT" ]; then
    echo "ERROR: MKLROOT environment variable not set"
    echo "Please set MKLROOT to your Intel MKL installation directory"
    echo "Example: export MKLROOT=/opt/intel/oneapi/mkl/latest"
    exit 1
fi

mkdir -p "$GCTA_BUILD_ROOT/dependencies"
cd "$GCTA_BUILD_ROOT/dependencies"

# List of dependencies to download (if not already present)
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
        wget -q --show-progress --retry-connrefused --waitretry=5 -t 3 "$url" || {
            echo "Failed to download $file from $url"
            echo "You may need to download manually and place in $GCTA_BUILD_ROOT/dependencies/"
            exit 1
        }
    else
        echo "Found cached $file"
    fi
done

# Build Eigen (header-only, just extract)
echo -e "${BLUE}Setting up Eigen...${NC}"
if [ ! -d "eigen-3.3.7" ]; then
    tar -xzf eigen-3.3.7.tar.gz
fi
export EIGEN3_INCLUDE_DIR=$GCTA_BUILD_ROOT/dependencies/eigen-3.3.7
echo -e "${GREEN}✓ Eigen path: $EIGEN3_INCLUDE_DIR${NC}"

# Build Spectra (header-only, just extract)
echo -e "${BLUE}Setting up Spectra...${NC}"
if [ ! -d "spectra-v1.2.0" ]; then
    tar -xzf spectra-1.2.0.tar.gz
fi
export SPECTRA_LIB=$GCTA_BUILD_ROOT/dependencies/spectra-v1.2.0/include
echo -e "${GREEN}✓ Spectra path: $SPECTRA_LIB${NC}"

# Build Boost
echo -e "${BLUE}Building Boost...${NC}"
if [ ! -d "boost_1_75_0" ]; then
    tar -xzf boost_1_75_0.tar.gz
fi
cd boost_1_75_0
if [ ! -f "$GCTA_BUILD_ROOT/boost_pkg/lib/libboost_system.a" ]; then
    ./bootstrap.sh --prefix=$GCTA_BUILD_ROOT/boost_pkg > /dev/null
    ./b2 --prefix=$GCTA_BUILD_ROOT/boost_pkg \
         --with-system \
         --with-filesystem \
         link=static \
         threading=multi \
         variant=release \
         cxxflags="-fPIC" \
         -j$(nproc) \
         install > /dev/null
fi
export BOOST_LIB=$GCTA_BUILD_ROOT/boost_pkg/include
echo -e "${GREEN}✓ Boost built${NC}"
cd ..

# Build zlib
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

# Build zstd
echo -e "${BLUE}Building zstd...${NC}"
if [ ! -d "zstd-1.5.0" ]; then
    tar -xzf zstd-1.5.0.tar.gz
fi
if [ ! -f "$GCTA_BUILD_ROOT/zstd_pkg/lib/libzstd.a" ]; then
    cd zstd-1.5.0/build/cmake
    mkdir -p build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=$GCTA_BUILD_ROOT/zstd_pkg \
          -DZSTD_BUILD_SHARED=OFF \
          -DZSTD_BUILD_STATIC=ON \
          .. > /dev/null
    make > /dev/null
    make install > /dev/null
fi
echo -e "${GREEN}✓ zstd built${NC}"
cd $GCTA_BUILD_ROOT/dependencies

# Build gsl
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

# Build sqlite3
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
echo -e "${GREEN}All dependencies built successfully!${NC}"
echo ""
echo "Set these environment variables for building GCTA:"
echo ""
echo "export GCTA_BUILD_ROOT=$GCTA_BUILD_ROOT"
echo "export MKLROOT=$MKLROOT"
echo "export EIGEN3_INCLUDE_DIR=$EIGEN3_INCLUDE_DIR"
echo "export SPECTRA_LIB=$SPECTRA_LIB"
echo "export BOOST_LIB=$BOOST_LIB"
echo ""
echo "Then run: ./build_gcta_linux_x86_64.sh <gcta_source_dir>"
