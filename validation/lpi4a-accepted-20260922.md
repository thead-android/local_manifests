# LPi4A accepted-source checkpoint — 2026-09-22

This checkpoint freezes the existing vendor-stack source pins after the September
21–22 performance trials. It does not claim that all performance problems are
fixed, or that a newly assembled image has passed a cold-boot test.

## Accepted inputs

| Project | Revision | Purpose |
| --- | --- | --- |
| frameworks/base | ef88c6b9e25213ea3295b2342c7d05e871671082 | Accepted framework; no short-wait experiment |
| frameworks/native | 694264c91e0404da0dabd549df867305e30917b6 | Vendor WSI, destination-surface fence and cursor negotiation |
| external/skia | 1ca4bc73fb101a0e667c422f2b69e18ca40ef1a8 | Partial-circular clip roundoff fix |
| external/libdrm | c10deed0cbdbc47595975705a763409cd47e6fc7 | etnaviv stream lifetime and failed-submit ownership |
| external/drm_hwcomposer | b9149888edc187ba78e280c0df15f6678c52bc8d | Accepted composer/FD handling |
| external/v4l2_codec2 | d054993d156673649e3cd86d34e1412d0d24e223 | Vendor-gralloc hardware encoding integration |
| device/thead/th1520 | df63c7927ecb11fabd850802b92a52866efc0b36 | Accepted device integration |
| device/thead/th1520/lichee_pi_4a | 56944f58554cc457911c182862ad43dda15f82c3 | Accepted board configuration |
| kernel/common | 449ab929ce6fc7295b0e21062a37e623d237d95b | Reservation-safe lazy DMA mapping for CPU metadata |
| prebuilts/thead | 0d6926e5ea7965d0e7419c707d0bafae4fdf4822 | Archived Clang/Rust and corrected simpleperf readelf runtime |

The frozen component image must include the libraries, not just these source
pins. Qualified component hashes:

- libhwui.so: e51ef7fc50d176049274d2c75cc03a9207a5daddfda4596d8696a0e50f4e1f56
- simpleperf: 9a63247f4c34c99fd5e9661eaa926b390e97c397f3c926d8918144062915e317
- vendor/lib64/libdrm_etnaviv.so: d01fe5a3b769bd5cd8a1ae949c553560ef8ff71d6bf24388f26ead100309ef26
- pvrsrvkm.ko: 2bfeedd8a0b3ac5945ba0f8f9f2e18170ee948fb1803056ee76416129738c724

The etnaviv library is a separate payload: replacing libth1520_g2d alone does
not include the accepted ownership/leak fixes. Component assembly now checks
its hash explicitly. The image excludes obsolete diagnostic executables and
retains the existing AVB chain/rollback values, kernel and bootloader policy.

## Rejected candidates — do not apply

- Short-wait accumulation in Choreographer, experimental2734826af: same-process
  off/on/off physical latency p50 stays about51.8ms; long update intervals grow
  from roughly8–9% to10–13%. The small mean-latency benefit is not a smoothness win.
- Fixed-total app24ms/SF10.587906ms allocation: physical p50 regresses to65–66ms.
- Previously rejected G2D prefix/batch/hold policies, timing sweeps and the
  SystemUI-specific scene-layer prototype remain unpromoted.

No experimental recovery or SF timing properties are made defaults. Temporary
framework, app-AOT and timing overrides were removed. Existing accepted HWUI
and simpleperf repairs were preserved. Final restored physical p50 is51.838ms.

## Known limits

- The remaining UI latency is not solved by this checkpoint.
- Kernel perf guest/static-call CFI issue remains: explicit host-only `H` is
  required in current simpleperf captures.
- On-board ART service compilation hit a ClassLinker lock assertion. An isolated
  single-thread/fresh-vdex compile succeeded; the independent fault is not yet
  attributed to a compiler or fixed.
- This system currently lacks a riscv64 WebView provider. Browser2 is only a
  shell; the legacy Chromium93 browser is not a replacement provider. WebView
  integration is a separate follow-up, not claimed by this checkpoint.

The source changes are already applied and committed with LoveSy
<shana@zju.edu.cn>; no loose patch replay is required. Use immutable manifest
revisions rather than searching historical experiment folders for patches.
