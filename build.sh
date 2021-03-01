#!/bin/bash

# kernel build script (kanged from somewhere i forgot)

# fill the vars yourself
SAUCE="https://github.com/JamieHoSzeYui/dream -b ten-oc" 
DEFCONFIG=lancelot_defconfig
AK=https://github.com/he
KNAME=Nightmare
ZIPNAME="Nightmare-lancelot-JustTheTwoOfUs-BETA"

echo "Cloning dependencies"
git clone --depth=1 --single-branch $SAUCE build 

cd build 
git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-5484270 -b 9.0 clang
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 gcc
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 gcc32
git clone $AK --depth=1 AnyKernel

echo "Done"
KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
TANGGAL=$(date +"%Y%m%d-%H")
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_USER=henlo
export KBUILD_BUILD_HOST=Drone

make O=out ARCH=arm64 $DEFCONFIG

# Compile plox
compile() {
    make -j8 O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi-
}

module() {
[ -d "modules" ] && rm -rf modules || mkdir -p modules

compile \
INSTALL_MOD_PATH=../modules \
INSTALL_MOD_STRIP=1 \
modules_install
}

ls out/arch/arm64/boot 

ls AnyKernel/

# Zipping
zipping() {
    cd AnyKernel || exit 1
    cp ../out/arch/arm64/boot/Image.gz-dtb .
    zip -r9 $ZIPNAME-${TANGGAL}.zip *
    cd ..
}

function start() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• $KNAME •</b>%0ABuild started on <code>Travis CI</code>%0A <b>For device</b> <i>$DEVICE</i>%0A<b>branch:-</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0A<b>Under commit</b> <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0A<b>Using compiler:- </b> <code>Clang 5484270</code>%0A<b>Started on:- </b> <code>$(date)</code>%0A<b>Build Status:</b> #$STATUS"
}
# Push kernel to channel

function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build finished on $(date) | For <b>$DEVICE</b> | @mango_ci "
}
# Fin Error

function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

start
compile
module
zipping
if [[ -f AnyKernel/Image.gz-dtb ]]; then 
    push
else
    finerr
fi 
exit 
