# Aftermarket Goodix GT9896 panel: 8x coordinate range

Applies to `sweet` (Redmi Note 10 Pro) kernels built by this repo when the
phone has an **aftermarket touch panel**. It is a DTBO fix, not a kernel fix.

## Symptom

Touch only responds in the top-left 1/8 of the display; everywhere else the
pointer sticks to the right/bottom edge. `getevent -p` shows:

```
ABS_MT_POSITION_X : min 0, max 1079
ABS_MT_POSITION_Y : min 0, max 2399
```

while raw coordinates from the IC reach `8632` and `19192`.

## Root cause

`send_config` is skipped on purpose for aftermarket panels (sending the OEM
`goodix_gt9896_cfg.bin` can brick the IC). Without it the IC runs its
default/NVM configuration, which reports coordinates in **Q3 fixed point**:
3 fractional bits, i.e. 1/8 px.

```
X: 1079 px * 8 = 8632
Y: 2399 px * 8 = 19192
```

Every sample observed was a multiple of 8, and the observed maxima were exactly
`8 * (width-1)` and `8 * (height-1)`.

`goodix_ts_core.c` calls `input_set_abs_params()` with `goodix,panel-max-x/y`
from the DTB. With those left at 1079/2399, Android's `TouchInputMapper`
clamps every real touch into the first eighth of the range. The IC is fine; the
declared range is wrong.

Note: `goodix,input-max-x/y` in the DTS is **not parsed by this driver**.
Changing it does nothing.

## Fix

Declare the real IC range in the `gt9896@5d` DT node:

```
goodix,panel-max-x = <8639>;   /* 8 * 1080 - 1 */
goodix,panel-max-y = <19199>;  /* 8 * 2400 - 1 */
```

Android then computes `XScale = 1080 / 8640 = 0.125` and maps raw -> display
1:1. No driver scaling is needed or wanted.

The node lives in the **dtbo partition** (`/dev/block/by-name/dtbo`), not in
`boot.img`. This repo builds kernels with `"dtbo": ""` in `devices/*.json`, so
the kernel zip does not ship or flash a dtbo. Patch the partition once and it
survives kernel updates, reboots and hard resets.

### Kernel-side fallback (stock dtbo also works)

`scripts/fix_goodix_aftermarket.patch` widens the declared range at runtime in
`goodix_ts_set_input_params()` when the DT still carries the native panel size:

```c
if (ts_bdata->panel_max_x && ts_bdata->panel_max_x < 4000)
	ts_bdata->panel_max_x = ts_bdata->panel_max_x * 8 + 7;
if (ts_bdata->panel_max_y && ts_bdata->panel_max_y < 4000)
	ts_bdata->panel_max_y = ts_bdata->panel_max_y * 8 + 7;
```

With a stock DT (1079/2399) the evdev range becomes 8639/19199, exactly as if
the dtbo had been patched. With an already-patched dtbo the guard skips the
change, so both can coexist.

Result: **flashing the kernel zip alone is enough**. The dtbo patch below is
still useful for kernels built without this change, or if you want the fix
without waiting for a new kernel build.

Caveat: this assumes an aftermarket panel that reports 8x. On a stock panel
(native coordinates) the widening would be wrong, so do not use this build on
an original touch panel.


## Why earlier driver-side attempts failed

| Commit | Assumption | Result |
|---|---|---|
| `e10a131` | real touches are within 1079x2399, larger values are ghost | `x > panel_max_x` rejected almost every real touch -> only top-left 1/8 |
| `ec48f27` | IC native range is ~3800 | hardcoded `input_set_abs_params(0, 3800)` -> 56% of the panel clamped to the edge |
| `a1530cc` | 2.5x matrix (2700x6000) | `x * 2 / 5`, then clamped to 1079 -> collapsed |
| `3b457cb` | 5x matrix (5400x12000) | `x / 5` still exceeds 1079 -> clamped; `> 15000` filter also killed the bottom 22% |
| `7fb3fc9` | "native" coordinates | removed all scaling, but abs-max stayed 1079 -> Android clamps everything into 1/8 |

The common mistakes: guessing the factor instead of measuring it, and
correcting the reported value while the declared range stayed wrong. Any
division is still clamped by `panel_max_x`.

## Procedure

```
adb shell su -c "dd if=/dev/block/by-name/dtbo of=/sdcard/dtbo_now.img bs=4096"
adb pull /sdcard/dtbo_now.img dtbo_before_fix.img

python scripts/patch_dtbo.py -i dtbo_before_fix.img -o dtbo_fixed.img

adb reboot bootloader
fastboot flash dtbo dtbo_fixed.img
fastboot reboot
```

The tool finds the properties by name, so it is safe to run on a dtbo that
changed after an OTA. It aborts without writing if the node or properties are
missing.

## Verify

```
adb shell getevent -p /dev/input/event4 | grep -E "0035|0036"
#   0035 : ... max 8639
#   0036 : ... max 19199

adb shell dumpsys input | grep Scale
#   XScale: 0.125
#   YScale: 0.125
```

Then touch all four corners and the center; the pointer must sit under the
finger.

## Revert

```
adb reboot bootloader
fastboot flash dtbo dtbo_before_fix.img
fastboot reboot
```

## Caveats

- The dtbo partition is a single 32 MB slot on `sweet`; `dd` the whole device.
- A full stock ROM / `flash_all.bat` overwrites dtbo and the bug comes back.
  Re-run the procedure afterwards.
- Do not flash a `dtbo.img` produced by another kernel tree; only patch the
  image dumped from the phone itself.
