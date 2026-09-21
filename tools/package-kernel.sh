#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 AOSP_ROOT LPI4A_KERNEL_DIST MKIMAGE [STAGE_NAME]" >&2
  exit 2
}

[[ $# -ge 3 && $# -le 4 ]] || usage

aosp_root=$(realpath "$1")
kernel_dist=$(realpath "$2")
mkimage=$(realpath "$3")
stage_name=${4:-lpi4a-gki}

[[ "$stage_name" != */* && "$stage_name" != .* ]] || {
  echo "invalid stage name: $stage_name" >&2
  exit 2
}

image="$kernel_dist/Image"
dtb="$kernel_dist/th1520-lichee-pi-4a.dtb"
stage_parent="$aosp_root/_prebuilts"
stage="$stage_parent/$stage_name"

[[ -f "$image" ]] || { echo "missing $image" >&2; exit 1; }
[[ -f "$dtb" ]] || { echo "missing $dtb" >&2; exit 1; }
[[ -x "$mkimage" ]] || { echo "mkimage is not executable: $mkimage" >&2; exit 1; }
[[ ! -e "$stage" ]] || {
  echo "refusing to overwrite existing stage: $stage" >&2
  exit 1
}

mkdir -p "$stage_parent"
tmp=$(mktemp -d "$stage_parent/.${stage_name}.XXXXXX")
cleanup() {
  if [[ -d "$tmp" ]]; then
    rm -rf -- "$tmp"
  fi
}
trap cleanup EXIT

mkdir -p "$tmp/modules"
install -m 0644 "$image" "$tmp/Image"
install -m 0644 "$dtb" "$tmp/th1520-lichee-pi-4a.dtb"

module_count=0
while IFS= read -r -d '' module; do
  install -m 0644 "$module" "$tmp/modules/"
  ((module_count += 1))
done < <(find "$kernel_dist" -maxdepth 1 -type f -name '*.ko' -print0 | sort -z)

((module_count > 0)) || {
  echo "no kernel modules found in $kernel_dist" >&2
  exit 1
}

gzip -n -9 -c "$tmp/Image" > "$tmp/Image.gz"
"$mkimage" \
  -A riscv -O linux -T kernel -C gzip \
  -a 0x04000000 -e 0x04000000 \
  -n 'Linux 7.1 GKI LPI4A' \
  -d "$tmp/Image.gz" "$tmp/uImage"

mv "$tmp" "$stage"
trap - EXIT

echo "staged $module_count modules in $stage"
sha256sum "$stage/Image" "$stage/th1520-lichee-pi-4a.dtb" "$stage/uImage"

cat <<EOF

Build with:
  export OUT_DIR=out-lpi4a
  export LLVM_PREBUILTS_VERSION=clang-c910-llvm22-mesa-readelf-20260921
  export RUST_PREBUILTS_VERSION=1.93.1-c910-llvm22
  export TARGET_PREBUILT_KERNEL=_prebuilts/$stage_name/uImage
  export TARGET_PREBUILT_DTB=_prebuilts/$stage_name/th1520-lichee-pi-4a.dtb
  export TARGET_PREBUILT_KERNEL_MODULES=_prebuilts/$stage_name/modules
  source build/envsetup.sh
  lunch lichee_pi_4a-trunk_staging-userdebug
  m -j48 bootimage vendorbootimage dtbimage vendorimage superimage vbmetaimage

The C910 LLVM/Rust toolchains are required for this archived LPi4A build.
Install and verify them with prebuilts/thead/install.py. Source changes are
already applied in the pinned repositories; no patch application is needed.
EOF
