#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019, 2020, Raphielscape LLC (@raphielscape)
# Copyright (C) 2019, 2020, Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020, Muhammad Fadlyas (@fadlyas07)
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export config_path=$(pwd)/arch/arm64/configs
if [[ -e $config_path/ugglite_defconfig ]]; then
    export device="Xiaomi Redmi Note 5A Lite"
    export config_device1=ugglite_defconfig
elif [[ -e $config_path/rolex_defconfig || $config_path/riva_defconfig ]]; then
    export device="Xiaomi Redmi 4A/5A"
    export config_device1=rolex_defconfig
    export config_device2=riva_defconfig
fi
git clone --depth=1 https://github.com/fadlyas07/anykernel-3
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 https://github.com/crdroidmod/android_prebuilts_clang_host_linux-x86_clang-6317467 cclang
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r57 gcc32
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r57 gcc
mkdir $(pwd)/temp
export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_TOKEN=$token
export pack=$(pwd)/anykernel-3
export product_name=GreenForce
export KBUILD_BUILD_USER=Mhmmdfadlyas
export KBUILD_BUILD_HOST=LucidDreams
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
case $parse_branch in
        *"android"*)
                echo -e "Reset channel id to my id"
                touch $chat_id
                unset chat_id
                export chat_id="784548477"
        ;;
esac
export TELEGRAM_ID=$chat_id
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAACAgUAAxkBAAEYl9pee0jBz-DdWSsy7Rik8lwWE6LARwACmQEAAn1Cwy4FwzpKLPPhXRgE" \
	-d chat_id="$TELEGRAM_ID"
}
tg_channelcast() {
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_ID -d "disable_web_page_preview=true" -d "parse_mode=html" -d text="$(
           for POST in "$@"; do
               echo "$POST"
           done
    )"
}
tg_build() {
PATH=$(pwd)/cclang/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH \
make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-android- \
                CROSS_COMPILE_ARM32=arm-linux-androideabi-
}
build_start=$(date +"%s")
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out "$config_device1" && \
tg_build 2>&1| tee Log-$(TZ=Asia/Jakarta date +'%d%m%y').log
mv *.log $TEMP
if ! [[ -f "$kernel_img" ]]; then
    build_end=$(date +"%s")
    build_diff=$(($build_end - $build_start))
    grep -iE 'not|empty|in file|waiting|crash|error|fail|fatal' "$(echo $TEMP/*.log)" &> "$TEMP/trimmed_log.txt"
    curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
    curl -F document=@$(echo $TEMP/*.txt) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    tg_channelcast "<b>$product_name</b> for <b>$device</b> on branch '<b>$parse_branch</b>' Build errors in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
    exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage && cd $pack
if [[ $device = "Xiaomi Redmi Note 5A Lite" ]]; then
    zip -r9q $product_name-ugglite-$date1.zip * -x .git README.md LICENCE $(echo *.zip)
elif [[ $device = "Xiaomi Redmi 4A/5A" ]]; then
    zip -r9q $product_name-rolex-$date1.zip * -x .git README.md LICENCE $(echo *.zip)
fi
cd ..
if ! [[ $device = "Xiaomi Redmi Note 5A Lite" ]]; then
rm -rf out/ $TEMP/*.log $pack/zImage
date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out "$config_device2" && \
tg_build 2>&1| tee Log-$(TZ=Asia/Jakarta date +'%d%m%y').log
mv *.log $TEMP
if ! [[ -f "$kernel_img" ]]; then
    build_end=$(date +"%s")
    build_diff=$(($build_end - $build_start))
    grep -iE 'not|empty|in file|waiting|crash|error|fail|fatal' "$(echo $TEMP/*.log)" &> "$TEMP/trimmed_log.txt"
    curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
    curl -F document=@$(echo $TEMP/*.txt) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    tg_channelcast "<b>$product_name</b> for <b>$device</b> on branch '<b>$parse_branch</b>' Build errors in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
    exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage && cd $pack
if [[ $device = "Xiaomi Redmi 4A/5A" ]]; then
    zip -r9q $product_name-riva-$date2.zip * -x .git README.md LICENCE $(echo *.zip)
fi
cd ..
fi
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> in <b>Linux $kernel_ver</b> using <b>$toolchain_ver</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b> build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
if [[ $device = "Xiaomi Redmi Note 5A Lite" ]]; then
    curl -F document=@$pack/$product_name-ugglite-$date1.zip "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
elif [[ $device = "Xiaomi Redmi 4A/5A" ]]; then
    curl -F document=@$pack/$product_name-rolex-$date1.zip "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    curl -F document=@$pack/$product_name-riva-$date2.zip "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
fi
