#!/bin/bash

# Apply O3 flags
# echo "-- Applying O3 flags before compiling..."
# sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
# sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile

# Make sure out folder exist
mkdir -p out &> /dev/null

# Common make command array for readability
MAKE_CMD=(make O=out "${MAKE_ARGS[@]}")

# Setup main defconfig
"${MAKE_CMD[@]}" $ACTUAL_MAIN_DEFCONFIG &> /dev/null

# Append additional configs
echo "-- Appending fragments to .config..."
for fragment in $COMMON_DEFCONFIG $DEVICE_DEFCONFIG $FEATURE_DEFCONFIG; do
    if [ -f "arch/arm64/configs/$fragment" ]; then
        echo "   -> Merging $fragment..."
        cat "arch/arm64/configs/$fragment" >> out/.config
    else
        echo "   -> Warning: Fragment arch/arm64/configs/$fragment not found!"
    fi
done

# Set kernel name
echo "-- Appending kernel name..."
echo "CONFIG_LOCALVERSION=\"$KERNEL_NAME\"" >> out/.config
echo "CONFIG_LOCALVERSION_AUTO=n" >> out/.config

# Enable pstore on all kernels
echo "CONFIG_PSTORE=y" >> out/.config
echo "CONFIG_PSTORE_CONSOLE=y" >> out/.config
echo "CONFIG_PSTORE_PMSG=y" >> out/.config
echo "CONFIG_PSTORE_RAM=y" >> out/.config

# Patch Goodix touch driver to prevent forcing firmware downgrade on newer ICs
echo "-- Patching Goodix touchscreen driver to prevent firmware downgrade..."
find drivers/input/touchscreen/ -type f -name "*update*.c" -exec sed -i 's/else if (ret > 0) {/else if (ret > 0) { ts_info("FW on IC is newer, skip update"); return 0; } else if (0) {/g' {} +

# Config generation
echo "-- Executing olddefconfig and syncconfig..."
{ yes "" 2>/dev/null || true; } | "${MAKE_CMD[@]}" olddefconfig &> /dev/null
{ yes "" 2>/dev/null || true; } | "${MAKE_CMD[@]}" syncconfig &> /dev/null

# Warning start banner
echo "-- Starting to compile..."
echo " "
echo "====================================="
echo " COMPILING PROCESS HAVE BEEN STARTED "
echo "====================================="
echo " "

# Compile the kernel
make -j$(nproc --all) O=out "${MAKE_ARGS[@]}"

# Warning finish banner
echo " "
echo "======================================"
echo " COMPILING PROCESS HAVE BEEN FINISHED "
echo "======================================"
echo " "