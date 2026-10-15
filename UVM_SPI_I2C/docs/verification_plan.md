# Verification plan and acceptance criteria

## Tests

| Current class | Topology | Required evidence | Prior scenario |
| --- | --- | --- | --- |
| `SerialSmokeTest` | LOOPBACK | Two SPI and two I2C polling pairs | `serial_loopback_smoke_test` |
| `SerialSpiSmokeTest` | LOOPBACK | Two complete SPI write/read pairs | `serial_loopback_spi_smoke_test` |
| `SerialI2cSmokeTest` | LOOPBACK | Two complete I2C write/read pairs | `serial_loopback_i2c_smoke_test` |
| `SerialProtocolSwitchTest` | LOOPBACK | Both SPI→I2C and I2C→SPI directions | `serial_loopback_protocol_switch_test` |
| `SerialRandTest` | LOOPBACK | 16 randomized settings, seeds 1/17/2026 | `serial_loopback_random_test` |
| `SerialCoverageClosureTest` | LOOPBACK | 0, 1, middle and 127 payloads for both protocols | `serial_loopback_coverage_closure_test` |
| `SpiSlaveUnitTest` | SPI_SLAVE_UNIT | Active BFM, high-bit write, invalid register behavior | New |
| `I2cSlaveUnitTest` | I2C_SLAVE_UNIT | Active BFM, repeated START, ACK/NACK, invalid address/register | New |
| `SerialDualBusParallelTest` | DUAL_SLAVE_UNIT | Eight verified frames and nonzero measured overlap | New |
| `SerialRepeatedPayloadTest` | All four | Two identical write/read pairs per active protocol, separate completions | New |
| `SerialResetRecoveryTest` | All four | In-flight frame aborts, new epoch, recovered traffic, no pending requests | New |
| `SerialScoreboardNegativeTest` | SPI_SLAVE_UNIT | Corrupt/drop/duplicate detected exactly once each, followed by valid traffic | New |

The matrix expands to 20 runs. Tests own objections. Monitor and Scoreboard collectors remain passive background tasks and do not keep the simulation alive.

## Acceptance

Normal tests require zero UVM_ERROR/UVM_FATAL, no HDL assertion errors, positive verified completions and empty pending queues. The checker self-test permits only its currently armed diagnostic ID, clears it after one occurrence, and requires exactly three detections. Every unexpected ID or repeated error remains a normal UVM_ERROR. Error severities are never globally downgraded.

The Python runner checks simulator return status and parsed log evidence. A fatal UVM termination cannot pass merely because XSim exits with status zero. A source/tool fingerprint guards cached elaboration. Each run saves its seed, topology, tool version, source hashes and command line.

## Coverage definition

The per-protocol coverage model has five write payload buckets (`0`, `1`, `2..126`, `127`, `128..255`) and four read response buckets (`0`, `1`, `2..126`, `127`). The switch-backed read contract cannot produce `128..255`, so that cross bin is explicitly ignored. There are **nine supported RW×payload cross bins per protocol**.

Only successful Scoreboard comparisons for register `0x01` writes and register `0x02` reads enter these payload covergroups and the corresponding hit masks. Invalid-register and address-NACK checks remain verified checks but do not fill payload coverage. Mask bits 0–4 represent write buckets; bits 5–8 represent read buckets. Bit 9 is unsupported.

`SerialCoverage` separately samples verified protocol×RW combinations and physical overlap. Control request counts, reset/abort counts and both protocol-switch directions are separate scenario evidence. These metrics are not combined into an unsupported overall “100% verification” claim.

The preserved historical report's 18 functional points and 33 matched items belong to a different model and counting unit. They are not imported into the new regression.

## Reproducibility and limits

The supported local runner uses XSim's precompiled UVM 1.2 library with `-L uvm` on compilation and elaboration, as described in [AMD UG900](https://docs.amd.com/r/2025.2-English/ug900-vivado-logic-simulation/Universal-Verification-Methodology-UVM-Support). It explicitly sets the design timescale and elaboration topology.

This regression verifies simulation behavior. It does not establish CDC sign-off, timing closure, board operation or full protocol-standard compliance. Additional mode, burst, arbitration and deliberate clock-stretch scenarios are outside the supported contract.
