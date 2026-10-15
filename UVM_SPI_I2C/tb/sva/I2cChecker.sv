`timescale 1ns/1ps
module I2cChecker(i2c_if bus);
  // Structural open-drain assignments prevent the BFM from ever driving a logic one.
  assert_known_bus: assert property (@(posedge bus.iClk) disable iff (bus.iRst)
    !$isunknown({bus.scl,bus.sda})) else $error("I2C_UNKNOWN");
  assert_passive_release: assert property (@(posedge bus.iClk) disable iff (bus.iRst)
    !bus.activeMode |-> !(bus.sclDriveLow || bus.sdaDriveLow)) else $error("I2C_PASSIVE_DRIVE");
endmodule
