# Reproducing the failure and correction

This packet targets public Flexe commit
`e2b79fc7a8987b2821f74065e47e70e3e261e45e`. It needs a native JIT-capable
Linux ARM64 or x86-64 host, CMake, a C17 compiler, OpenSSL/zlib development
libraries, Git, patch and the normal upstream unit-test build prerequisites.
Only ARM64 qualification is recorded in this packet.

Run from this packet directory, using an existing clone of
[Lev Kropp's public repository](https://github.com/levkropp/flexe):

```bash
bash reproduce.sh /path/to/flexe-clone
```

1. The helper exports the pinned commit into a new temporary directory and
   applies only [the regression](regression.patch). The input clone is unchanged.
2. It builds `xtensa-tests` and runs `--quiet iram_isync`, requiring an actual
   assertion-failure exit. A compiler failure or crash is not accepted as proof.
3. It applies only [the source correction](source.patch), rebuilds the same
   target and requires that identical regression to exit successfully.
4. It retains source and before/after logs at the directory printed on startup.
   No ROM, firmware, disk image, guest program or graphical session is launched.

[The complete PR diff](upstream-pr.patch) combines source and test changes for
normal review/application. New contribution code is covered by [MIT](LICENSE-MIT);
existing upstream notices remain in force. The helper is an optional manual
reproduction convenience; recorded qualification uses the commands and exact
source hashes retained in the private review receipt.
