#!/bin/bash

# Patcher helper - 1.5
apply_patches() {
    for patch_url in "$@"; do
        echo "-- Applying patch: $(basename "$patch_url")"
        curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_patch.patch
        if [ -s /tmp/temp_patch.patch ]; then
            patch -s -p1 --fuzz=5 < /tmp/temp_patch.patch || { echo "Fatal: Failed to apply patch!"; exit 1; }
        else
            echo "Fatal: Failed to download patch from $patch_url"
            exit 1
        fi
    done
}

# Commit reverter - 1.5
revert_commit() {
    for patch_url in "$@"; do
        echo "-- Reverting commit: $(basename "$patch_url")"
        curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_revert.patch
        if [ -s /tmp/temp_revert.patch ]; then
            patch -R -s -p1 < /tmp/temp_revert.patch || { echo "Fatal: Failed to revert commit!"; exit 1; }
        else
            echo "Fatal: Failed to download revert patch from $patch_url"
            exit 1
        fi
    done
}

# Shared patches for 4.14
LTO_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/fix_lto.patch"
KPATCH_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/kpatch_fix.patch"
DTBO_PATCHES=(
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/e517bc363a19951ead919025a560f843c2c03ad3.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/a62a3b05d0f29aab9c4bf8d15fe786a8c8a32c98.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/4b89948ec7d610f997dd1dab813897f11f403a06.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/fade7df36b01f2b170c78c63eb8fe0d11c613c4a.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/2628183db0d96be8dae38a21f2b09cb10978f423.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/31f4577af3f8255ae503a5b30d8f68906edde85f.patch"
)
DTC_PATCHES=(
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/e207247aa4553fff7190dde5dabb50aec400b513.patch"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/ae58bbd8f7af4c3c290e63ddcd4112559c5fc240.patch"
)
LN8K_COMMON=(
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/ade11a168d80de8552752447edad545851490b35.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/eb4aef5a0b917537ca4cc5357068390a8d2d680b.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/ddedab15a165c5c68737e30e813e40e785b1f921.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/2cc9ab3c0d7f6cdb98b1ee72aca104980c1e4415.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/6d8c5b25168981cb8f7e3ef758872b21f3d8a361.patch"
)
SMB5LIB_COMMON=(
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/ee2627b0cf620f8f5fb59d31f164c2ca91a72523.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/18d91e84dfa2235a37f370b0007dc603f33585e7.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/b4ecd5825986daa2dff4b3783edf50ee15d17e4c.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/509115dbee1e4486481b38f28e2dd789a86bd6ea.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/1e8e5057a05e8d7bbfcdce0394ca8ac112c31905.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/b6fb4a7f3fdc6b868356d4865f4dfaa4d6dfc277.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/db4a6db01697b60ab9a2664cd2eb9e21b839963a.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/f5b7ddef27899943896d1a513c7b42348cf6e84b.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/b9a40caa95d713142064c7b52ab5634ba6d17ef8.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/f499c5d97d5444d8df8519869f4912ebc795a2d2.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/7f03348a4fd273e1623777b32558d6f83e02aa6d.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/521709b3fcd89b1c84b784390523951fdaf21ad9.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/2c6eaf6c957aeb3d11a85476fd0f01f28d85bbcf.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/55abe8f43549cb92d002b76f44c7f678adb28ce1.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/3318d76d02e61a1a7e03e3442a97540bc0056f0a.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/6257f9c3e7ffce612532aca4a98dbd6c8ef4ebf8.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/cf62977aeeee0aed13f4ebfa3771f7cd960703d7.patch"
    "https://github.com/awaken-sweet/android_kernel_xiaomi_sm6150/commit/a52850092fc5a2356ee5cadf4bd5d2b166c1c310.patch"
)

# Patcher - 1.5
echo "- Patching kernel source for $DEVICE_IMPORT..."
case "$DEVICE_IMPORT" in
    # LineageOS
    sweet-lineage|davinci-lineage|tucana-lineage|violet-lineage|toco-lineage)
        echo "-- Applying LTO patch..."
        apply_patches "$LTO_PATCH"
        echo "-- Applying DTB patches..."
        apply_patches "${DTBO_PATCHES[@]}"
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    ginkgo-lineage|laurel_sprout-lineage)
        echo "-- Applying DTC patches..."
        apply_patches "${DTC_PATCHES[@]}"
        echo "-- Applying DTB patches..."
        apply_patches "${DTBO_PATCHES[@]}"
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    gta4l-lineage)
        echo "-- Fixing scripts/dtc/livetree.c..."
        sed -i '/assert(generate_fixups);/d' scripts/dtc/livetree.c
        echo "-- Setting up extra drivers as built-in for gta4l..."
        sed -i 's/^CONFIG_QCA_CLD_WLAN=m$/CONFIG_QCA_CLD_WLAN=y/' arch/arm64/configs/$DEVICE_DEFCONFIG
        find techpack/data -name "Makefile" -exec sed -i 's/obj-m/obj-y/g' {} +
        find techpack/audio/config -name "*.conf" -exec sed -i 's/=m/=y/g' {} +
        find techpack/audio -name "Makefile*" -exec sed -i 's/obj-m/obj-y/g' {} +
        find techpack/audio -name "Kbuild*" -exec sed -i 's/obj-m/obj-y/g' {} +
        echo "CONFIG_SENSORS_SSC=y" >> $MAIN_DEFCONFIG
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    # CrDroid
    sweet-crdroid|davinci-crdroid|tucana-crdroid)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 78088ffb401b570b8de9408662c8fc931e9cf1a5 &> /dev/null
        if [[ "$DEVICE_IMPORT" == "tucana-crdroid" ]]; then
            echo "-- Fixing goodix driver..."
            sed -i 's/static void gtp_set_edge_filter_normal()/static void gtp_set_edge_filter_normal(void)/g' drivers/input/touchscreen/f4_goodix_driver_gt9886/goodix_ts_core.c
            sed -i 's/static int gtp_send_cur_cmd()/static int gtp_send_cur_cmd(void)/g' drivers/input/touchscreen/f4_goodix_driver_gt9886/goodix_ts_core.c
            echo "-- Fixing fts driver..."
            sed -i 's/"%100s %d %d"/"%99s %d %d"/g' drivers/input/touchscreen/fts_521/fts.c
            sed -i 's/"%100s"/"%99s"/g' drivers/input/touchscreen/fts_521/fts_proc.c
            sed -i 's/struct device \*getDev()/struct device \*getDev(void)/g' drivers/input/touchscreen/fts_521/fts_lib/ftsIO.c
            sed -i 's/struct i2c_client \*getClient()/struct i2c_client \*getClient(void)/g' drivers/input/touchscreen/fts_521/fts_lib/ftsIO.c
            echo "ccflags-y += -Wno-strict-prototypes" >> drivers/input/touchscreen/fts_521/Makefile
        fi
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_FRAME_WARN=4096" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    surya-crdroid)
        echo "-- Reverting SUSFS commits..."
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/47140d7ff95d7c86fa1a41da8f3db26aa3659c3e.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/428375f331cf3bbcd6512e825686e239f2c28742.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/84ebf21d3fd0ffda7db1e0cd999ea0edba548253.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/13a80e7aa5c642e6bc64f199ce7feb0d2caa30e4.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/d75fcba752e5925218015f53f650b05b68eec17c.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/42125145f25bd1d8809720870764b934f151e273.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/f3993c906b1c6e0f912e3fc574f2b47946218804.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/f9cf0fd520a72dd19a9b07e5b5f50b6fee7e2091.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/7270786ff109269cfa4680624440bc142074058a.patch"
        echo "-- Reverting KSU commits..."
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/df304eed2cde9410c37d0f159f35cf615dbfbc93.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/7e0e3e2f6a586bf9e453ef2a8a9d1d2dc23f172d.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/6046a6ed077ae25526da535e39e66a4a586c4721.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/ef98668e687ef6c8d3ee873d77bd97a6c91a7a68.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/3676095dd4139a6ae4ae880062bf3d930024af44.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/906c6a6987bb3d50aa2c4c947282c41f3d2a26a3.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/340e3b3a4662d51dd743b087d440a2538534d576.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/80652cb8b40fd63da65ea046f39ecb86de5dc648.patch"
        revert_commit "https://github.com/crdroidandroid/android_kernel_xiaomi_surya/commit/3c8c1cd917d6b986bdbe88d66571b91a804d8add.patch"
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    sweet-crdroid-droidspaces)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 78088ffb401b570b8de9408662c8fc931e9cf1a5 &> /dev/null
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_FRAME_WARN=4096" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    # PixelOS
    sweet-pixelos|davinci-pixelos|toco-pixelos)
        if [[ $DEVICE_IMPORT == "sweet-pixelos" ]]; then
            echo "-- Applying SMB5LIB patches..."
            apply_patches "${SMB5LIB_COMMON[@]}"
            echo "-- Applying LN8K patches..."
            apply_patches "${LN8K_COMMON[@]}"
            echo "CONFIG_CHARGER_LN8000=y" >> $MAIN_DEFCONFIG
        fi
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    # Awaken
    sweet-awaken)
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    # Mi-Thorium
    mi89x7-playground)
        echo "-- Reverting KSU commit..."
        revert_commit "https://github.com/Mi-Thorium/kernel_msm-4.19/commit/624875e8edc36ae280b1f8efc1d3c48a28da64ea.patch"
        if [[ $CLANG_STRAT == "1" ]]; then
            echo "-- Tuning CPU flags..."
            sed -i '/export KBUILD_CFLAGS/i \
            KBUILD_CFLAGS += -march=armv8-a+crypto+crc -mcpu=cortex-a53' Makefile
        fi
        echo "-- Fixing HW key for riva..."
        sed -i 's/#define FTS_POINT_REPORT_CHECK_EN[[:space:]]*0/#define FTS_POINT_REPORT_CHECK_EN               1/g' techpack/xiaomi-msm8937/touchscreen/focaltech_touch/focaltech_common.h
        sed -i '/input_report_key(input_dev, BTN_TOUCH, 0);/a \
            if (ts_data->key_state) {\
                struct fts_ts_platform_data *pdata = ts_data->pdata;\
                int key_idx;\
                int num_keys = 0;\
                u32 *keycodes = NULL;\
        \
            if (pdata->key_is_vkeys && pdata->vkeys_pdata) {\
                    num_keys = pdata->vkeys_pdata->num_keys;\
                    keycodes = pdata->vkeys_pdata->keycodes;\
            } else if (!pdata->key_is_vkeys) {\
                    num_keys = pdata->key_number;\
                    keycodes = pdata->keys;\
            }\
        \
            if (keycodes) {\
                    for (key_idx = 0; key_idx < num_keys; key_idx++) {\
                            if (ts_data->key_state & (1 << key_idx))\
                                    input_report_key(input_dev, keycodes[key_idx], 0);\
                    }\
            }\
            ts_data->key_state = 0;\
        }' techpack/xiaomi-msm8937/touchscreen/focaltech_touch/focaltech_point_report_check.c
        echo "-- Disabling modversions..."
        sed -i 's/^CONFIG_MODVERSIONS=y/# CONFIG_MODVERSIONS is not set/' $MAIN_DEFCONFIG
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
    ;;
    # Spiteful MIUI Buildout
    spiteful-sweet-miui-buildout)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 1c950660849776c0105ae268270acb590d1df308 &> /dev/null
        # echo "-- Completely disabling LTO..."
        # sed -i \
        #     -e 's/^CONFIG_LTO=y/# CONFIG_LTO is not set/' \
        #     -e 's/^CONFIG_THINLTO=y/# CONFIG_THINLTO is not set/' \
        #     -e 's/^CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/' \
        #     -e 's/^CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/' \
        #     -e 's/^# CONFIG_CC_STACKPROTECTOR_NONE is not set/CONFIG_CC_STACKPROTECTOR_NONE=y/' \
        #     -e 's/^# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/' \
        #     $MAIN_DEFCONFIG
        # echo "-- Removing regalloc advisor..."
        # sed -i '/-regalloc-enable-advisor=release/d' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    # Spiteful AOSP Buildout
    spiteful-sweet-aosp-buildout)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 1b133f3054948bee6c59332c83699ff2b95d7978 &> /dev/null
        # echo "-- Completely disabling LTO..."
        # sed -i \
        #     -e 's/^CONFIG_LTO=y/# CONFIG_LTO is not set/' \
        #     -e 's/^CONFIG_THINLTO=y/# CONFIG_THINLTO is not set/' \
        #     -e 's/^CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/' \
        #     -e 's/^# CONFIG_CC_STACKPROTECTOR_NONE is not set/CONFIG_CC_STACKPROTECTOR_NONE=y/' \
        #     -e 's/^CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/' \
        #     -e 's/^# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/' \
        #     $MAIN_DEFCONFIG
        # echo "-- Removing regalloc advisor..."
        # sed -i '/-regalloc-enable-advisor=release/d' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_MODULE_REL_CRCS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_CRYPT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_DEFAULT_KEY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_SNAPSHOT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_UEVENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_VERITY_FEC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_DM_BOW=y" >> $MAIN_DEFCONFIG
    ;;
    # Titan Kernel
    a9y18qlte-titan-aosp)
        echo "-- Nuking pre-built KSU..."
        sed -i '/kernelsu/d' drivers/Kconfig
        sed -i '/kernelsu/d' drivers/Makefile
        rm -rf drivers/kernelsu
        rm -rf KernelSU
        OPENSSL_DIR="$(pwd)/.openssl1.1"
        echo "-- Installing openssl 1.1 at: '$OPENSSL_DIR'"
        if [[ "$OPENSSL_DIR" != /* ]]; then
            echo "--  OPENSSL_DIR is empty or not absolute! Check your shell environment."
            ls -alhZ $OPENSSL_DIR
            ls -alhZ $OPENSSL_DIR/../
            exit 1
        fi
        if [ ! -d "$OPENSSL_DIR" ]; then
            wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz -O openssl-1.1.1w.tar.gz &> /dev/null || { echo "Fatal: openssl source code failed to download!"; exit 1; }
            tar -xf openssl-1.1.1w.tar.gz &> /dev/null
            cd openssl-1.1.1w
            ./config --prefix="$OPENSSL_DIR" --openssldir="$OPENSSL_DIR" &> /dev/null
            make -s -j$(nproc) &> /dev/null
            make -s install &> /dev/null
            cd ..
            rm -rf openssl-1.1.1w*
        fi
        export HOSTCFLAGS="-I$OPENSSL_DIR/include"
        export HOSTLDFLAGS="-L$OPENSSL_DIR/lib -Wl,-rpath,$OPENSSL_DIR/lib"
        export LD_LIBRARY_PATH="$OPENSSL_DIR/lib:$LD_LIBRARY_PATH"
        export MY_OPENSSL_DIR="$OPENSSL_DIR"
        echo "-- Overriding MAKE_ARGS..."
        export MAKE_ARGS=(
            ARCH=arm64 CC=aarch64-linux-android-gcc LD=aarch64-linux-android-ld.bfd
            AR=aarch64-linux-android-ar AS=aarch64-linux-android-as NM=aarch64-linux-android-nm
            OBJCOPY=aarch64-linux-android-objcopy OBJDUMP=aarch64-linux-android-objdump
            STRIP=aarch64-linux-android-strip CROSS_COMPILE=aarch64-linux-android- 
            HOSTCFLAGS="$HOSTCFLAGS" HOSTLDFLAGS="$HOSTLDFLAGS" OPENSSL="$MY_OPENSSL_DIR/bin/openssl"
        )
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SYSTEM_TRUSTED_KEYS=.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SYSTEM_REVOCATION_KEYS=.*/CONFIG_SYSTEM_REVOCATION_KEYS=""/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MODULE_SIG=y/# CONFIG_MODULE_SIG is not set/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MODULE_SIG_ALL=y/# CONFIG_MODULE_SIG_ALL is not set/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MODULE_SIG_FORCE=y/# CONFIG_MODULE_SIG_FORCE is not set/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SYSTEM_TRUSTED_KEYRING=y/# CONFIG_SYSTEM_TRUSTED_KEYRING is not set/g' $MAIN_DEFCONFIG
    ;;
    *)
        echo "No specific patches to apply for $DEVICE_IMPORT."
    ;;
esac

if [[ "$CLANG_STRAT" == "1" ]]; then
    echo "- Variable clang_strat is set to 1! applying extra patches..."
    echo "-- Allowing to compile on new AOSP clang..."
    sed -i 's/-Wno-format-security/-Wno-format-security -Wno-enum-conversion -Wno-default-const-init-var-unsafe -Wno-default-const-init-field-unsafe -Wno-misleading-indentation -Wno-unsequenced -Wno-sizeof-pointer-memaccess -Wno-implicit-function-declaration -Wno-implicit-enum-enum-cast/g' Makefile
    echo "-- Setting up -O3 flags..."
    sed -i 's/KBUILD_CFLAGS.*+= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
    if [[ $DEVICE_IMPORT == "spiteful-sweet-aosp-buildout" || $DEVICE_IMPORT == "spiteful-sweet-miui-buildout" ]]; then
        echo "-- Default clang tweaks skipped."
    else
        echo "-- Adding default clang tweaks..."
        sed -i '/export KBUILD_CFLAGS/i \
        KBUILD_CFLAGS += -mllvm -polly -mllvm -enable-gvn-hoist -Wno-unused-command-line-argument' Makefile
    fi
fi

if [[ "$CLANG_STRAT" == "2" ]]; then
    echo "- Variable clang_strat is set to 2! applying extra patches..."
    echo "-- Setting up -O3 flags..."
    sed -i 's/KBUILD_CFLAGS.*+= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
fi

if [[ "$CLANG_STRAT" == "3" ]]; then
    echo "- Variable clang_strat is set to 3! applying extra patches..."
    echo "-- Setting up -O3 flags..."
    sed -i 's/KBUILD_CFLAGS.*+= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
fi

if [[ "$CLANG_STRAT" == "0" ]]; then
    if [[ $DEVICE_IMPORT != "a9y18qlte-titan-aosp" ]]; then
        echo "- Variable clang_strat is set to 0! applying extra patches..."
        echo "-- Setting up -O3 flags..."
        sed -i 's/KBUILD_CFLAGS.*+= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
    fi
fi