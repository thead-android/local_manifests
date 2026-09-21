# Partial circular clip roundoff

Skia1ca4bc73fb101a0e667c422f2b69e18ca40ef1a8, parent6c5878a,
author LoveSy <shana@zju.edu.cn>. No SystemUI-specific code, disabled AA,
compiler/ISA/fence/refresh-rate workaround or new shader is included.

Device-space corner radii differing by about0.00003–0.00005 px failed exact
equality in the complex tab-circle FP, unlike the existing simple-circle path.
The accepted change uses the same absolute near-equality tolerance and a private
normalized radius copy for single/adjacent circular corners. Non-simple
four-corner shapes retain their general path, including elliptical nine-patch.

Validation on TH1520/C910 with the vendor Vulkan stack:

- Recompiled one TU using the exact archived build inputs; control HWUI reproduces
  live SHA b00bf3985a89fe8a4d98cd1661a868a838c0cf1cf25c5768f13d23e9676e9fce.
- Accepted HWUI SHA e51ef7fc50d176049274d2c75cc03a9207a5daddfda4596d8696a0e50f4e1f56.
-33 isolated app_process/ImageReader GPU pixel cases:20 unchanged controls
  pixel-exact;13 near-circle cases within1 channel of existing analytic-circle
  references. Old SW-AA boundary is not bit-exact: captured cases change9–72
  edge pixels, max channel delta5–11, no changes outside a1px AA boundary.
- Initial extension to all four corners was rejected by a strict pixel gate;
  it is not in this commit.
- New GrClipStack regression compiles; full Skia suite is not claimed run.
- SystemUI six-workload A/B/A (two repeats per stage), same app/driver/clock and
  physical-presentation metric. Two-cycle upload diagnostics: original12 large
  masks/uploads (~27.9MB A8), fixed0, restored10 (~23.3MB). No lost trace records.
- Physical frame-start→present means: original59.05/58.50ms, fixed57.50/57.55ms,
  restored60.10/59.24ms. p50 remains~52ms; tail/jank improve modestly, not60fps.

This pins applied source. Runtime tests reused the frozen HWUI toolchain/objects
to isolate the change. A complete new image built with all current manifest
toolchain updates has not been qualified by these tests. No image flash is
implied. Existing compiler/kernel/perf and whole-board stability limits remain.
