# Supported protocol contract

This environment verifies the included RTL's register protocol, using a 100 MHz system clock and accelerated serial timing. It is not a general-purpose SPI/I2C compliance suite.

| Item | Implemented and tested contract |
| --- | --- |
| Reset | Active-high asynchronous RTL reset; serialized testbench requests |
| SPI | Mode 0, MSB-first, 16 bits per CS-low frame |
| SPI header | `{read, register_address[6:0]}` followed by 8 write/dummy bits |
| SPI response | Read data on the final 8 MISO bits, sampled at rising SCLK |
| I2C address | 7-bit `0x5A` |
| I2C write | START, address+W, register byte, data byte, STOP; three slave ACKs |
| I2C read | START, address+W, register byte, repeated START, address+R, data byte, master NACK, STOP |
| I2C unmatched address | A different address (`0x5B` in the unit test) receives NACK and leaves registers unchanged |
| Register `0x01` write | LED gets `write_data[6:0]`; high bit is discarded at the LED |
| Register `0x02` read | `{1'b0, slave_switch[6:0]}` |
| Other register reads | Return zero, including reading `0x01` |
| Other register writes | Do not change the LED |
| Master operation | Timer-driven write `0x01` then read `0x02`; LED mirror commits after the pair |
| Protocol selection | One protocol per Slave core; selection changes at an idle pair boundary |

The BFM uses LOW/high-Z outputs for I2C. Resolved `tri1` nets provide pull-ups. Its SCL-release helper waits for the sampled bus to become high with a bounded timeout, but deliberate slave clock-stretch injection is not part of the regression. No multi-master arbitration, 10-bit addressing, burst transfers, additional SPI modes or master-under-test slave BFM is claimed.

The initial BFM implementation exposed a first-frame CS initialization issue in XSim: the clocking output started at zero while the interface's idle CS value was one. The SPI idle-clock assertion and missing/mismatched frame checks detected it. Explicitly initializing the driver's clocking outputs fixed the first transfer; the unit, repeated, parallel and checker tests exercise that path.

Original source hashes and retained artifacts are listed in [source_provenance.json](source_provenance.json). The prior report remains under [historical_2026-04-20](../results/historical_2026-04-20/).
