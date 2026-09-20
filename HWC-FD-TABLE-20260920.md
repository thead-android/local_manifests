# HWC startup fdtable reservation

This manifest advances only drm_hwcomposer from b6d2930 to b914988. The change
reserves fdtable capacity before HWC creates worker threads. Temporary /dev/null
descriptors are closed immediately; RLIMIT_NOFILE and GPU/display fences are
unchanged. No G2D scaling, import-cache or overlap experiments are included.

On-board kernel tracing reproduced HWC fcntl duplication taking the
alloc_fd/expand_files/synchronize_rcu path for28.323ms. With startup reservation,
FDSize is1024 but live descriptors remain in the tens, and the corresponding
RCU expansion did not recur in the bounded cold-service/gesture trace. The
production-only version completed two full gesture workloads without process
or board restart. This is a rare latency-tail mitigation, not a claim of60fps
or of a persistent median-frame-time improvement.

The previously flashed image is still tied to manifest9216436; it was not
rebuilt or reflashed as part of this source update. That manifest commit remains
available to reproduce it. Physical-panel black-with-backlight recovery through
display off/on is not a root fix. Full-screen G2D still benchmarks slower than
GPU client composition and remains excluded from this pin.
