`timescale 1ns/1ps
module SpiChecker(spi_if bus);
  // SPI mode 0 returns SCLK low when CS is inactive; all connected pins are resolved.
  property p_idle_clock;
    @(posedge bus.iClk) disable iff (bus.iRst) bus.csn |-> !bus.sclk;
  endproperty
  assert_idle_clock: assert property (p_idle_clock) else $error("SPI_IDLE_CLOCK");
  assert_known_pins: assert property (@(posedge bus.iClk) disable iff (bus.iRst)
    !$isunknown({bus.csn,bus.sclk,bus.mosi,bus.miso})) else $error("SPI_UNKNOWN");
  assert_passive_release: assert property (@(posedge bus.iClk) disable iff (bus.iRst)
    !bus.activeMode |-> (bus.driveCsn && !bus.driveSclk && !bus.driveMosi)) else $error("SPI_PASSIVE_DRIVE");
endmodule
