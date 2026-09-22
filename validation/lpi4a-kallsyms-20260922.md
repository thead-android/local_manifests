# Default RISC-V complete kallsyms - 2026-09-22

Kernel source `3a9a2b928e12e3b7911dd11f0dc39553c76774f6` adds one line to
`arch/riscv/configs/gki_defconfig`: `CONFIG_KALLSYMS_ALL=y`. It is based on
accepted `449ab929ce6fc7295b0e21062a37e623d237d95b`; previous GPU, display,
encoding, network, touch and other fixes remain in the ancestry.

This makes data symbols available for kernel diagnostics and for the in-progress
generic RV64 KernelSU port. It does not change kallsyms address-access policy,
disable CFI, relax module signatures, or automatically install/load KernelSU.

## Validation and boundaries

- Fresh GKI defconfig generation and an olddefconfig round trip retain the
  option. This is a source default, not only a generated `.config` edit.
- The running kernel configuration was byte-compared with its archived output.
- The accepted boot image contains a legacy uImage/gzip wrapper. Its decompressed
  Image hash matches the archived build:
  `db404ddb55b3982ec293084d71e9121a2e438f80745ac0014f451bf457ab561c`.
- An isolated copy of that exact source/output was rebuilt using the unchanged
  accepted kernel compiler, build identity, security settings and optimizations.
  The generated config differs only by `KALLSYMS_ALL n -> y`.
- Test Image hash:
  `c10d1c89e6df5c30312d042c1b9b17811a88950ed8833833657c804824a04e01`.
- `sys_call_table`, `init_mm` and `text_mutex` are present in the new System.map.

The test Image is a configuration-only rebuild of the accepted running Image,
not a claim that all later source-only changes in this manifest were integrated
into a new full image. The previous immutable WebView image/tag remains unchanged.
No flash, reboot, module loading or root-grant test was performed for this change.
KernelSU integration and cold-boot acceptance remain separate gates.
