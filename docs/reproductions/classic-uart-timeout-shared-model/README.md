# Classic ESP32 UART timeout regression

The unmodified Flexe base reports assertion failures for this regression.
Applying the source correction makes the same four tests pass: 673 assertions,
zero failures. The correction uses the common UART timeout model and retains
an asserted timeout until the receive FIFO is drained and acknowledged.

Use a local clone of [Flexe](https://github.com/levkropp/flexe) that contains
commit 9372d98c30289d3f3576e720d645553f2133747e. If necessary fetch that commit
from upstream first. Requirements are the normal Linux native unit-test build
prerequisites: Git, patch, CMake, C17 compiler, OpenSSL/zlib development libraries
and an x86_64 or ARM64 JIT-capable host. This revision was qualified on Linux
x86_64 with GCC 15.2. No firmware, ROM, game assets or display are needed.

From this packet directory, set source_repo to your clone and prepare an
isolated export; the clone itself is unchanged:

```bash
source_repo=/path/to/flexe
case_dir="$(mktemp -d)"
mkdir "$case_dir/source"
git -C "$source_repo" archive 9372d98c30289d3f3576e720d645553f2133747e | tar -x -C "$case_dir/source"
patch --batch -d "$case_dir/source" -p1 < regression.patch
cmake -S "$case_dir/source" -B "$case_dir/build" -DCMAKE_BUILD_TYPE=Release -DNATIVE_ARCH=OFF -DFLEXE_LTO=OFF -DFLEXE_CCACHE=OFF
cmake --build "$case_dir/build" --target xtensa-tests --parallel 2
"$case_dir/build/xtensa-tests" --quiet classic_uart_timeout_ shared_uart_timeout_reset_cancels_pending
```

The last command is the negative control: expect assertion failures, exit 1.
A compiler error, signal or crash is not that expected result. Next apply only
the production correction and run the identical tests again:

```bash
patch --batch -d "$case_dir/source" -p1 < source.patch
cmake --build "$case_dir/build" --target xtensa-tests --parallel 2
"$case_dir/build/xtensa-tests" --quiet classic_uart_timeout_ shared_uart_timeout_reset_cancels_pending
```

The corrected run must report four passing tests, 673 assertions and exit 0.
The test header is included for direct inspection. regression.patch also wires
it into the existing test runner and updates older immediate-timeout assumptions.
upstream-pr.patch combines that test patch with source.patch for normal review.
New contribution code is MIT-licensed; existing upstream notices remain intact.
