Prepared by Codex on behalf of Brandon

This PR resolves stale code executing after an embedding host replaces an
already translated RAM function and the guest executes `ISYNC`, when the host
supplies the attached invalidation policy. In the linked
reproducer, the replacement should return 43, but cached execution still returns
42. The correction supplies an optional ISYNC observer through which the host
can invalidate changed executable RAM.

The interpreter currently treats `ISYNC` as a no-op, the predecoder classifies
it as `PD_NOP`, and the JIT can compile across it. An embedding host therefore
cannot apply its translation-coherence policy at that architectural boundary.
Explicit `xtensa_invalidate_code` works, but the guest barrier does not expose
a place to call it. This is separate from host ARM64 instruction-cache flushing.

Add an optional CPU observer and context, call it for `ISYNC` in the canonical
and quick interpreter paths, prevent cached no-op handling and terminate JIT
blocks before the barrier. Preserve the observer across session CPU reset.
Other synchronization instructions retain their current semantics.

The [synthetic regression](repro/tests/test_iram_isync.h) contains both the guest
instruction bytes and a small host invalidation policy. It warms a function
returning 42, replaces it with one returning 43, executes an actual guest
`ISYNC`, then executes the same address again. It covers byte, halfword, word,
backing-copy and interpreted/JIT guest stores, including a translated store
prefix directly before ISYNC, plus first load into predecoded RAM. Explicit
invalidation and null-observer/barrier controls accompany it. No firmware,
ROM image, application or game assets are needed.

The same regression compiles against both APIs. Observer registration and its
callback-count checks are conditional on the new feature macro; expected guest
values are identical.
The embedding host must supply the invalidation policy: installing no observer
does not automatically make all RAM writes coherent. This does not promise
coherence for arbitrary self-modifying code without `ISYNC`, cross-core policy,
or hardware cache timing. Embedders must rebuild for the changed CPU structure.

Validated against master `e2b79fc7a8987b2821f74065e47e70e3e261e45e`
on Linux ARM64, GCC 14.2, Release with LTO/native tuning disabled:

1. New regression with unchanged production code: 3 tests, 118 passing and 12 failing
   assertions, including all seven replacements returning 42 instead of 43.
2. Identical regression with the core hook and example host policy: 3 tests,
   145 passing assertions, 0 failures (15 extra observer-count checks are now available).
3. Integration/JIT/cached-interpreter neighbours: 133 tests, 24,149 passing
   assertions, 0 failures. These are unit checks, not hardware/application acceptance.

Build the normal `xtensa-tests` target, then run:

```bash
./build/xtensa-tests --quiet iram_isync
```

[Reproduction instructions](REPRODUCING.md) explain applying the regression
first, observing assertion failures, then applying the source patch and rerunning.
