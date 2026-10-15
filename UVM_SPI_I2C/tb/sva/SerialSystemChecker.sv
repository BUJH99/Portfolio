`timescale 1ns/1ps
module SerialSystemChecker #(parameter int P_TOPOLOGY = 0)
  (serial_ctrl_if ctrlIf, spi_if spiIf, i2c_if i2cIf);
  if (P_TOPOLOGY != 3) begin : genSingleDut
    assert_protocol_exclusive: assert property (@(posedge ctrlIf.iClk) disable iff (ctrlIf.iRst)
      !(!spiIf.csn && i2cIf.frameActive)) else $error("PROTOCOL_OVERLAP_SINGLE_DUT");
  end
endmodule
