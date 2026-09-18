# LicheePi 4A Android 17 sources

Applied source repositories for TH1520 / C910, organized like the XuanTie Android
BSP: board/vendor projects and modified AOSP components live under
`thead-android`; unmodified dependencies remain on their public upstreams.
Every project in these manifests is pinned to an exact commit. No patch-apply
step is required.

The kernel branch imports the **complete upstream source snapshot** at
`648fd74a4d2eaed87fe242e26506f724619dacff`, followed by 26 separate port commits.
Its final tree is identical to the archived R2 + touch source. Port commit
authors/messages are retained; earlier upstream ancestry is referenced upstream
instead of being reimported into this branch. The original-to-published port
commit mapping is recorded in `provenance/kernel-snapshot-map.json`.

This is an archived development baseline, **not** a CTS-certified or fully
stable release. It retains the verified graphics/media fixes and the newer
TL060FVXS07 touch integration, with the limitations below.

## Fetch

Use a Linux x86-64 build host; the archived toolchains were used on Ubuntu 24.04.
Install AOSP build prerequisites, `repo`, Python 3.12+, Git and `u-boot-tools`.
Allow several hundred GiB for sources, intermediates and toolchains.

```sh
mkdir android17-lpi4a && cd android17-lpi4a
repo init -u https://github.com/thead-android/local_manifests -b android17
repo sync -c -j8
python3 prebuilts/thead/install.py --root "$PWD"
python3 vendor/thead/proprietary/prebuilts/generic/install-archived-apk.py
python3 .repo/manifests/tools/restore-large-assets.py --root "$PWD"
```

Compiler source projects are in the optional `toolchain-src` group:

```sh
repo init -g default,toolchain-src
repo sync -c -j8
```

Clang/LLD and Rust **must** be the matching C910 builds. Ratified RVV 1.0 is not
binary-compatible with the C910's XTheadVector / RVV 0.7.1 implementation. The
installer downloads immutable Release assets and checks their hashes; it never
replaces a different existing toolchain silently.

## Kernel and modules

Use a separate checkout to avoid collisions between Android and Kleaf layouts:

```sh
mkdir ../kernel-lpi4a && cd ../kernel-lpi4a
repo init -u https://github.com/thead-android/local_manifests -b android17 -m kernel.xml
repo sync -c -j8
tools/bazel run //common:lpi4a_dist
bash .repo/manifests/tools/package-kernel.sh ../android17-lpi4a out/lpi4a/dist /usr/bin/mkimage lpi4a-publication
```

Always package Image, DTB and **all** modules from the same build. The device
configuration deliberately fails if the required matching module stage is
missing; it must not fall back to the historical vendor 5.10 modules.

## Android

```sh
cd ../android17-lpi4a
bash .repo/manifests/tools/build-android.sh "$PWD" lpi4a-publication
```

The script selects `lichee_pi_4a-trunk_staging-userdebug`, enables the archived
C910 Clang/Rust toolchains and uses the explicitly staged kernel/modules. A
normal optimized userdebug build is used; this does not globally disable
optimization or vector extensions. ccache is optional, not a correctness input.

The manifest pins source content; a new build's timestamps/build IDs need not be
byte-identical to the old frozen images. Source publication and previous board
validation are not substitutes for a new full clean-build/flash acceptance run.

## Included paths

- Open Mesa PowerVR Vulkan, Android ANGLE GLES and the Skia icon correctness fix.
- RenderEngine destination-surface fence, minigbm and DRM display/wake handling.
- etnaviv GC620 DMA-BUF RGB-to-NV12 conversion and VC8000E hardware encoding.
- Ethernet, HDMI audio integration, AIC8800 Wi-Fi, H4 Bluetooth and USB ADB.
- SELinux enforcing policy, normal FUSE compatibility and SystemUI idle-ripple fix.
- TL060FVXS07 DSI panel, fixed 20% bring-up backlight and S6D6FT0 touch support.
- Complete archived C910 LLVM correctness layers and Rust frontend integration.

The original vendor prebuilt repositories have their own licenses/notices;
publishing board configuration does not relicense those binaries. This baseline
does not claim every peripheral or userspace component is open source.

The legacy vendor Chromium APK exceeds GitHub's ordinary-Git size limit. Its
exact payload and unaltered original Git bundle are Release assets, with a
checksum-checking installer. That repository documents its Git history storage
exception in `ARCHIVE-PROVENANCE.md`; no source fix is replaced with a patch file.
The same storage split is used for an upstream Virtualization test fixture and
display-safety design assets. `large-assets.json` records their original byte
hashes. Restored data files may appear as untracked files; they are not source
modifications. A few obsolete oversized binaries were removed only from Git
history, with original revisions retained in the provenance records.

## Known limitations

- Notification-shade animation still misses deadlines. The new RevyOS/AOSP
  comparison demonstrates substantial stack overhead; it is not a new fix or
  a claim of zero-jank / 60 fps.
- scrcpy does not sustain 1080p60. The fence/cursor/hardware-encoding fixes are
  retained, but capture performance remains separate from panel frame rate.
- Wi-Fi SAE/WPA3 interoperability is intermittent with some Mesh/MLO APs.
- Long-term whole-system stalls / full CTS acceptance remain unresolved. Touch
  works in the archived board tests but does not certify whole-system stability.
- The archived clean-data configuration can enable an incompatible UWB service;
  the running test board uses the documented UWB-disabled data setting. It is
  not silently fixed by publishing this source snapshot.
- Display-specific configuration targets the tested TL060 panel. Do not assume
  it is a generic panel or brightness-control implementation.

## Flashing boundary

Use the existing [mainline U-Boot port](https://github.com/thead-android/u-boot)
and its matching partition layout, not RevyOS/vendor flashing instructions.
Boot, vendor_boot, vbmeta and logical partitions must refer to the **same slot**.
There is one dynamic `super` container holding slot-specific logical partitions.
A whole-super flash can overwrite the other slot; it is not a B-only update.
This repository supplies no automatic bootloader overwrite or userdata erase.

Preserve upstream authorship; local port commits use LoveSy <shana@zju.edu.cn>.
The source lock/provenance files record the exact published revisions and their
archive verification basis.
