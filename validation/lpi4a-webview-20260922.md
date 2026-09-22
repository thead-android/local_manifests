# LPi4A native WebView153 integration

The board-qualified native riscv64 APK is153.0.8010.52/801005204, SHA256
`69a7a49339e846193506981036178265a4f8b3128394daa7f8cdc94af8c61a4f`.
It is restored by the existing prebuilts installer and installed unmodified,
presigned into `/product/app/webview-c910/webview-c910.apk`.
It no longer depends on a manual APK installation into `/data` after flashing.

Applied Chromium source:17a29e73d6966df2bee5ab3679b3ccc731556c88, inheriting
the complete upstream history through78e5e45d4bb41035e17ea4da2cc257f496416ac9.
DEPS pins FFmpegcd04d2ad98c6841ae182a6faa01af364bb3fefae and
CPUinfo8555372a57ce6c15132d7ab47a0df21e68ff002c.48 source inputs were verified
by Git blob against the qualified build. A separate `webview.xml` avoids mixing
Chromium's LLVM24/Rust1.99 build with the AOSP C910 compiler installation.

The prebuilt filegroup lives in prebuilts/thead; the AndroidAppImport lives in
external/chromium-webview/c910, within AOSP's existing optional-library
visibility boundary. No AdServices visibility or SELinux policy is widened.
The APK has unchanged ZIP alignment, native libraries, dex and signature.

## Passed on the running board

- Native signal/clone/stat/seccomp ABI and all8 baseline-policy variants.
- 47 frame-reporting tests, including the three late-draw/ownership regressions.
- 500+250 offline touch-scroll cycles; no renderer crash or UI stall >2s.
- JS/Canvas/PowerVR shader readback, WebGL2 and HTTPS browser smoke tests.
- 32-/64-bit Crashpad indirect-memory redaction tests and deliberate renderer
  crash callback handling, with the host remaining alive.

The ANR was caused by prematurely moving the provisional no-draw impl-frame
reporter before WebView's late synchronous draw. The fix preserves its lifetime
through submission/replacement/main promotion. DCHECKs, GPU acceleration and
the renderer sandbox stay enabled; no ISA/compiler change masks the defect.

## Image and test boundary

The component-image workflow adds the exact checked APK to the previous
118-entry accepted payload, retaining its existing graphics, encoding,
network, audio, touch, policy and compiler-related fixes. It does not copy a
newly rebuilt OUT tree wholesale or mix new ART/platform-library outputs into
the frozen image. Fresh product builds use the committed module dependencies
normally; no global dexpreopt/optimization change is made.

This is not a full clean AOSP rebuild or full WebView CTS certification.
The new image must be cold-boot/flash-qualified separately. Exceptional
renderer crash collection still takes about5.5s; broader browsing/media stress
and image boot qualification are not claimed by APK-level tests.
No U-Boot/SPL update, userdata erase or implicit board flashing is supplied.
Any factory super is A-populated and must not be mistaken for a B-only update.
