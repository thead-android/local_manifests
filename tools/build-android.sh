#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "usage: $0 AOSP_ROOT [KERNEL_STAGE_NAME]" >&2
    exit 2
fi
root=$(realpath "$1")
stage=${2:-lpi4a-publication}
[[ "$stage" != */* && "$stage" != .* ]] || exit 2
cd "$root"
python3 prebuilts/thead/install.py --root "$root" --verify-only
python3 vendor/thead/proprietary/prebuilts/generic/install-archived-apk.py --verify-only
python3 .repo/manifests/tools/restore-large-assets.py --root "$root" --verify-only
for input in uImage th1520-lichee-pi-4a.dtb modules/powervr.ko modules/etnaviv.ko modules/hantro-vpu.ko modules/s6d6ft0.ko; do
    [[ -s "_prebuilts/$stage/$input" ]] || { echo "missing matching kernel input: $input" >&2; exit 1; }
done
export OUT_DIR=${OUT_DIR:-out-lpi4a}
export LLVM_PREBUILTS_VERSION=clang-c910-llvm22-cubic-store-fix
export RUST_PREBUILTS_VERSION=1.93.1-c910-llvm22
export TARGET_PREBUILT_KERNEL="_prebuilts/$stage/uImage"
export TARGET_PREBUILT_DTB="_prebuilts/$stage/th1520-lichee-pi-4a.dtb"
export TARGET_PREBUILT_KERNEL_MODULES="_prebuilts/$stage/modules"
export BUILD_NUMBER=${BUILD_NUMBER:-lpi4a.20260918.archive}
source build/envsetup.sh
lunch lichee_pi_4a-trunk_staging-userdebug
m -j"${JOBS:-8}"
