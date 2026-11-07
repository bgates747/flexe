Prepared by Codex on behalf of Brandon

This PR resolves unread UART tail bytes being left without another RX timeout
interrupt after software acknowledges the previous timeout. With no further
input, the linked reproducer leaves two bytes in the FIFO and never sees the
second interrupt on the old model; the patch generates it after the configured
idle interval. It also stops asserting the first timeout immediately on arrival.

[`periph_uart_rx_inject_num`](https://github.com/levkropp/flexe/blob/e2b79fc7a8987b2821f74065e47e70e3e261e45e/src/peripherals.c#L16663)
and the CONF1 branch of
[`uart_write`](https://github.com/levkropp/flexe/blob/e2b79fc7a8987b2821f74065e47e70e3e261e45e/src/peripherals.c#L2936)
set `UART_RXFIFO_TOUT_INT` immediately when bytes are present and timeout is
enabled, without waiting for the configured idle interval. Clearing `RXFIFO_TOUT_INT` while bytes
remain only clears the bit. A sub-threshold FIFO tail then has no timeout event
to wake its reader unless new input arrives.

The [synthetic regression](repro/tests/test_uart_idle_timeout.h) injects three
bytes, waits for the configured deadline, reads one byte and clears the timeout.
It then advances virtual time with no additional input and requires the two
remaining bytes to generate another interrupt. All three classic UART ports
are covered, including raw/masked interrupt state and CPU delivery, deadline
edges, input restarting the idle interval, disable/re-enable and drain cleanup.
Two existing UART tests are updated to wait for their timeout instead of
requiring the old zero-delay behavior. No firmware or application assets are used.

Validated against master `e2b79fc7a8987b2821f74065e47e70e3e261e45e`
on Linux ARM64, GCC 14.2, Release with LTO/native tuning disabled:

1. New regression with unchanged production code: 2 tests, 42 passing and
   16 failing assertions, including the missing reasserted timeout on all ports.
2. Identical regression with the correction: 2 tests, 58 passing assertions,
   0 failures.
3. UART MMIO and system-clock neighbours: 9 tests, 100 passing assertions,
   0 failures. No silicon or whole-application qualification is claimed.

Build the normal `xtensa-tests` target, then run:

```bash
./build/xtensa-tests --quiet uart_idle_timeout
```

[Reproduction instructions](REPRODUCING.md) explain applying the regression
first, observing assertion failures, then applying the source patch and rerunning.
