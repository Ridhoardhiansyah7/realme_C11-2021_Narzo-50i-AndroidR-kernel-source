#!/bin/bash

# ============================================
# Kernel Build Script - Local Build (Adapted)
# ============================================

# Paths
KERNEL_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
TOOLCHAIN_DIR="${KERNEL_ROOT}/toolchains"
CLANG_PATH="${TOOLCHAIN_DIR}/clang-r383902b"
GCC_PATH="${TOOLCHAIN_DIR}/gcc-14.3"
OUT_DIR="${KERNEL_ROOT}/out"
MODULES_OUT="${KERNEL_ROOT}/modules_out"

# ============================================
# Download Toolchains (if missing)
# ============================================

mkdir -p "$TOOLCHAIN_DIR"

if [ ! -d "$CLANG_PATH" ]; then
    echo "[INFO]: Downloading Clang..."
    mkdir -p "$CLANG_PATH"
    wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0e9e7035bf8ad42437c6156e5950eab13655b26c/clang-r383902b.tar.gz -O /tmp/clang.tar.gz
    tar -xf /tmp/clang.tar.gz -C "$CLANG_PATH" && rm /tmp/clang.tar.gz
fi

if [ ! -d "$GCC_PATH" ]; then
    echo "[INFO]: Downloading GCC 14.3..."
    mkdir -p "$GCC_PATH"
    wget -q https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz -O /tmp/gcc.tar.xz
    tar -xf /tmp/gcc.tar.xz -C "$GCC_PATH" --strip-components=1 && rm /tmp/gcc.tar.xz
fi

chmod +x "$CLANG_PATH/bin/*" "$GCC_PATH/bin/*"

# ============================================
# Environment Setup
# ============================================

export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER='@fanuverse'
export KBUILD_BUILD_HOST='github-actions'

# Compiler and Cross-Compile
export CC="ccache clang"
export LD="ld.lld"
export AR="llvm-ar"
export NM="llvm-nm"
export OBJCOPY="llvm-objcopy"
export OBJDUMP="llvm-objdump"
export STRIP="llvm-strip"

export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE="$GCC_PATH/bin/aarch64-none-linux-gnu-"
export CROSS_COMPILE_ARM32="$GCC_PATH/bin/arm-none-linux-gnueabihf-"
export CLANG_TRIPLE="aarch64-none-linux-gnu-"

# PATH
export PATH="$CLANG_PATH/bin:$GCC_PATH/bin:$PATH"

# ============================================
# UNISOC Board-Specific Properties
# ============================================

export BSP_BUILD_DT_OVERLAY="y"
export BSP_BUILD_ANDROID_OS="y"
export BSP_BUILD_FAMILY="sharkl3"
export BSP_BOARD_NAME="sharkl3"
export BSP_KERNEL_VERSION="kernel4.14"
export TARGET_KERNEL_ARCH="arm64"
export BSP_SYSTEM_VERSION="sharkl3"
export BSP_PRODUCT_NAME="sharkl3"
export TARGET_BOARD="sharkl3"
export TARGET_BOARD_PLATFORM="sharkl3"
export PLATFORM_RELEASE="11"
export PLATFORM_VERSION="11"
export PLATFORM_VERSION_CODENAME="R"
export PLATFORM_CODENAME="R"
export BSP_ROOT_DIR="$KERNEL_ROOT"
export BSP_OUT_PLATFORM="$OUT_DIR"
export BSP_KERNEL_OUT="$OUT_DIR"
export NDK_PLATFORMS_ROOT="$KERNEL_ROOT/prebuilts/ndk/platforms"
export BSP_BOARD_UNISOC_WCN_SOCKET="sipc"
export BSP_BOARD_WLAN_DEVICE="sc2332"
export BSP_BOARD_CAMERA_MODULE_ISP_ADAPT_VERSION="sharkl3"
export BSP_BOARD_CAMERA_MODULE_ISP_VERSION="isp2.6"
export BSP_BOARD_CAMERA_MODULE_CSI_VERSION="receiver_r2p0"
export BSP_BOARD_CAMERA_MODULE_CPP_VERSION="lite_r4p0"

# ============================================
# Build Process
# ============================================

echo "[INFO]: Starting kernel build..."
mkdir -p "$OUT_DIR" "$MODULES_OUT"

# Step 1: Generate defconfig
make -C "$KERNEL_ROOT" O="$OUT_DIR" ARCH=$ARCH RMX3235_defconfig || {
    echo "[ERROR]: Defconfig generation failed!"
    exit 1
}

# Step 2: Build kernel, modules, and dtbs
make -C "$KERNEL_ROOT" \
    O="$OUT_DIR" \
    -j$(nproc) \
    LLVM=1 LLVM_IAS=1 ARCH="$ARCH" \
    CC="$CC" LD="$LD" AR="$AR" NM="$NM" \
    OBJCOPY="$OBJCOPY" OBJDUMP="$OBJDUMP" STRIP="$STRIP" \
    CROSS_COMPILE="$CROSS_COMPILE" CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" \
    CLANG_TRIPLE="$CLANG_TRIPLE" \
    Image modules dtbs || {
        echo "[ERROR]: Kernel build failed!"
        exit 1
    }

echo "[INFO]: Kernel build completed successfully!"
echo "[INFO]: Image location: $OUT_DIR/arch/arm64/boot/Image"
echo "[INFO]: DTBs location: $OUT_DIR/arch/arm64/boot/dts/sprd/"