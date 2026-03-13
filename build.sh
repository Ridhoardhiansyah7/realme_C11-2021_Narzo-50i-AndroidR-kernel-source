#!/bin/bash

# ============================================
# Kernel Build Script - Local Build
# ============================================

# Paths - ADJUST THESE TO YOUR SYSTEM
KERNEL_ROOT="${GITHUB_WORKSPACE}"
CLANG_PATH="${GITHUB_WORKSPACE}/clang-r383902b"
GCC_PATH="${GITHUB_WORKSPACE}/gcc-14.3"
OUT_DIR="${GITHUB_WORKSPACE}/kernel_out"

# ============================================
# Download Toolchains (GitHub Actions)
# ============================================

if [ ! -d "$CLANG_PATH" ]; then
    echo "[INFO]: Cloning Clang..."
    git clone --depth=1 https://github.com/kdrag0n/proton-clang "$CLANG_PATH"
fi

if [ ! -d "$GCC_PATH" ]; then
    echo "[INFO]: Cloning GCC..."
    git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$GCC_PATH"
fi

# ============================================
# Environment Setup
# ============================================

# Architecture
export ARCH=arm64
export SUBARCH=arm64

# Build User/Host
export KBUILD_BUILD_USER='@fanuverse'
export KBUILD_BUILD_HOST='github-actions'

# Compiler Setup
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# LLVM flags
export LLVM=1
export LLVM_IAS=1

# Cross-compile setup
export CROSS_COMPILE="${GCC_PATH}/bin/aarch64-none-linux-gnu-"
export CROSS_COMPILE_ARM32="${GCC_PATH}/bin/arm-none-linux-gnueabihf-"
export CLANG_TRIPLE="aarch64-none-linux-gnu-"

# PATH setup
export PATH="${CLANG_PATH}/bin:${GCC_PATH}/bin:${PATH}"

# ============================================
# UNISOC Board-Specific Properties
# ============================================

#export BSP_BOARD_ARCH: arm64
export BSP_BUILD_DT_OVERLAY="y"
export BSP_BUILD_ANDROID_OS="y"
export BSP_BUILD_FAMILY="sharkl3"
export BSP_BOARD_NAME="sharkl3"
export BSP_KERNEL_VERSION="kernel4.14"

# PowerVR
export TARGET_KERNEL_ARCH="arm64"
export BSP_SYSTEM_VERSION="sharkl3"
export BSP_PRODUCT_NAME="sharkl3"
export TARGET_BOARD="sharkl3"
export TARGET_BOARD_PLATFORM="sharkl3"
export PLATFORM_RELEASE="11"
export PLATFORM_VERSION="11"
export PLATFORM_VERSION_CODENAME="R"
export PLATFORM_CODENAME="R"
export BSP_ROOT_DIR="${GITHUB_WORKSPACE}"
export BSP_OUT_PLATFORM="${GITHUB_WORKSPACE}/out"
export BSP_KERNEL_OUT="${GITHUB_WORKSPACE}/out"
export NDK_PLATFORMS_ROOT="${GITHUB_WORKSPACE}/prebuilts/ndk/platforms"

# WCN
export BSP_BOARD_UNISOC_WCN_SOCKET="sipc"
export BSP_BOARD_WLAN_DEVICE="sc2332"

# Camera
export BSP_BOARD_CAMERA_MODULE_ISP_ADAPT_VERSION="sharkl3"
export BSP_BOARD_CAMERA_MODULE_ISP_VERSION="isp2.6"
export BSP_BOARD_CAMERA_MODULE_CSI_VERSION="receiver_r2p0"
export BSP_BOARD_CAMERA_MODULE_CPP_VERSION="lite_r4p0"

# ============================================
# Build Process
# ============================================

echo "[INFO]: Starting kernel build..."

# Create output directory
mkdir -p "$OUT_DIR"

# Step 1: Generate defconfig
echo "[INFO]: Generating defconfig..."
make -C "$KERNEL_ROOT" O="$OUT_DIR" ARCH=$ARCH RMX3235_defconfig

if [ $? -ne 0 ]; then
    echo "[ERROR]: Defconfig generation failed!"
    exit 1
fi

# Step 2: Build kernel, modules, and dtbs
echo "[INFO]: Building kernel, modules, and DTBs..."
make -C "$KERNEL_ROOT" \
    O="$OUT_DIR" \
    -j$(nproc) \
    LLVM=1 \
    LLVM_IAS=1 \
    ARCH="$ARCH" \
    CC="$CC" \
    LD="$LD" \
    AR="$AR" \
    NM="$NM" \
    OBJCOPY="$OBJCOPY" \
    OBJDUMP="$OBJDUMP" \
    STRIP="$STRIP" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" \
    CLANG_TRIPLE="$CLANG_TRIPLE" \
    Image modules dtbs

if [ $? -ne 0 ]; then
    echo "[ERROR]: Kernel build failed!"
    exit 1
fi

echo "[INFO]: Kernel build completed successfully!"
echo "[INFO]: Image location: $OUT_DIR/arch/arm64/boot/Image"
echo "[INFO]: DTBs location: $OUT_DIR/arch/arm64/boot/dts/sprd/"