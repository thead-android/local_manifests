#!/usr/bin/env bash
# Build only the Android-sync DDK against an already prepared matching kernel.
set -euo pipefail
if [[ $# != 3 ]]; then
    echo "usage: $0 KERNEL_COMMON KERNEL_OUT KERNEL_DIST" >&2
    exit 2
fi
source_dir=$(realpath "$1")
output_dir=$(realpath "$2")
dist_dir=$(realpath "$3")
module_dir=$source_dir/drivers/gpu/drm/img-rogue
test -s "$output_dir/Module.symvers"
test -s "$output_dir/.config"
test -s "$module_dir/pvr_sync_ioctl_dev.c"
release=$(sed -n 's/^#define UTS_RELEASE "\(.*\)"$/\1/p' "$output_dir/include/generated/utsrelease.h")
test -n "$release"
# Keep the caller's kernel compiler/LLVM setup; never disable CFI or change ISA
# flags to work around a module build failure. KERNEL_CC can include the same
# --gcc-install-dir option used for the matching RISC-V kernel build.
make -C "$source_dir" O="$output_dir" ARCH=riscv LLVM=1 \
    CC="${KERNEL_CC:-clang}" KERNELRELEASE="$release" \
    CONFIG_DRM_POWERVR_ROGUE=m M="$module_dir" -j"${JOBS:-8}" modules
test -s "$module_dir/pvrsrvkm.ko"
install -m 0644 "$module_dir/pvrsrvkm.ko" "$dist_dir/pvrsrvkm.ko"
modinfo "$dist_dir/pvrsrvkm.ko"
sha256sum "$dist_dir/pvrsrvkm.ko"
echo "Check imported-symbol CRCs against this kernel before board validation."
