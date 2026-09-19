# DDK + GC620 integration candidate, 2026-09-20

This branch is a **candidate**, not a replacement for the validated default
manifest. A cold reset occurred during an input-method test, without a captured
panic and with an empty pstore after recovery. Its cause is unresolved; USB power
is a hypothesis, not a diagnosis. No stable-release or60fps claim is made.

## Applied source

- Original Android DDK1.17 Vulkan/gralloc/mapper4 and its Android-sync KMD.
- AIDL allocator front end preserves original descriptors and publishes shared
  metadata. The image uses two init-managed services, not a debug child process.
- ION compatibility retains a public system-heap context for driver capability
  queries; only actual allocation in the HAL opens CMA. No coredomain CMA access
  exception or neverallow bypass is shipped.
- Archived upfront Vulkan swapchain allocation is retained. BGRA is not
  importable by this DDK's Vulkan driver; the cursor producer now opts into an
  actual RGBA bitmap and buffer, rather than relabelling BGRA bytes.
- GC620 HWC uses normalized metadata and fences, with direct scanout preferred
  and unsupported scenes falling back. The packaged service has unique paths.
- Codec2 has the capability-cache mutex, a cached standard-mapper import path,
  correct pixel FDs, and aligned NV12 storage. PVR's second FD is metadata, not UV.
- HDMI keeps its1280x720 mode preference but no longer has the forced-enable `e`.

## Evidence and limits

On both GPU stacks, eight real SurfaceControl overlays over Settings were
composed by GC620. Actual1080x2160 CRTC readback matched SF's reference within
one RGB LSB over all2,332,800 pixels, with no larger errors. Sleep/wake passed.

An independent stride matrix isolated the NV12 problem: destination pitch544
corrupted4824/39168 checked luma pixels with either tested source pitch; pitch576
had zero errors for both. Unsupported pitches now fail explicitly. Visible
544x1088 remains unchanged while storage and encoder negotiation use pitch576.

A final30-second UHID/audio recording contained464 valid H.264 frames and1473
Opus packets; decoded frames and cursor were visually checked. Logs recorded
GC620 conversion around3.5ms, without CPU fallback. A minigbm regression recording
also passed. These are bounded Surface-input tests, not full MediaCodec CTS or
guarantees for every client-supplied raw-YUV layout.

The complete component/SELinux build, including neverallow and file-context
checks, passes. Runtime tests used Enforcing. The final public-heap ION change
passed AHB/ANB/native-fence and initial UI tests, but the cold reset interrupted
its longer acceptance run. Full cold-boot/image stability remains outstanding.

## Reproduction

Use this branch consistently for Android and kernel manifests. After building
the matching GKI kernel, build the external DDK against its prepared output:

```sh
# KERNEL_CC and PATH must match the compiler used for this kernel.
bash .repo/manifests/tools/build-pvrsrvkm.sh common "$KERNEL_OUT" out/lpi4a/dist
```

Then package the kernel distribution with the existing package-kernel tool and
build Android. The product refuses a module stage without pvrsrvkm or touch.
Do not substitute the old DRM-only Linux-sync module.

The integration image is constructed incrementally from the hash-checked
September17 touch image, retaining its tested7.1 kernel and other system files.
It is distinct from a clean full-tree rebuild at these source pins. Kernel source
also retains previously validated DRM backports; their presence in Git is not a
claim that the incremental image rebuilt the entire kernel. U-Boot is unchanged.

Remaining gates: power/stability comparison, cold boot of the assembled image,
HDMI physical insertion/removal, and broader raw-buffer/media/graphics tests.
