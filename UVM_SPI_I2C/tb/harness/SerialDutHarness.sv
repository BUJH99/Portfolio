`timescale 1ns/1ps
module SerialDutHarness #(
  parameter int P_TOPOLOGY = 0
)(serial_ctrl_if ctrlIf, serial_status_if statusIf, spi_if spiIf, i2c_if i2cIf);
  import serial_tb_types_pkg::*;
  logic [15:0] MasterSw, SpiSw, I2cSw;
  assign MasterSw = {ctrlIf.protocolSel, 8'h00, ctrlIf.masterData};
  assign SpiSw = {1'b0, ctrlIf.spiSwitch, 8'h00};
  assign I2cSw = {1'b1, ctrlIf.i2cSwitch, 8'h00};
  if (P_TOPOLOGY == LOOPBACK) begin : genLoopback
    logic [15:0] SlaveSw, SlaveLed;
    assign SlaveSw = ctrlIf.protocolSel ? I2cSw : SpiSw;
    assign statusIf.spiLed = SlaveLed;
    assign statusIf.i2cLed = SlaveLed;
    SerialMasterCore #(.P_POLL_CYCLES(200), .P_SPI_DIV(40), .P_I2C_DIV(40)) uMaster (
      .iClk100Mhz(ctrlIf.iClk), .iRst(ctrlIf.iRst), .iSw(MasterSw), .oLed(statusIf.masterLed),
      .oJaCs(spiIf.csn), .oJaSclk(spiIf.sclk), .oJaMosi(spiIf.mosi), .iJaMiso(spiIf.miso),
      .ioJbScl(i2cIf.scl), .ioJbSda(i2cIf.sda), .oBusy(ctrlIf.masterBusy), .oCmdLoad(ctrlIf.cmdLoad)
    );
    SerialSlaveCore uSlave (
      .iClk100Mhz(ctrlIf.iClk), .iRst(ctrlIf.iRst), .iSw(SlaveSw), .oLed(SlaveLed),
      .iJaCs(spiIf.csn), .iJaSclk(spiIf.sclk), .iJaMosi(spiIf.mosi), .oJaMiso(spiIf.miso),
      .ioJbScl(i2cIf.scl), .ioJbSda(i2cIf.sda)
    );
  end else begin : genUnit
    assign statusIf.masterLed = '0;
    assign ctrlIf.masterBusy = 1'b0;
    assign ctrlIf.cmdLoad = 1'b0;
    assign spiIf.csn = spiIf.activeMode ? spiIf.driveCsn : 1'b1;
    assign spiIf.sclk = spiIf.activeMode ? spiIf.driveSclk : 1'b0;
    assign spiIf.mosi = spiIf.activeMode ? spiIf.driveMosi : 1'b0;
    if (P_TOPOLOGY inside {SPI_SLAVE_UNIT, DUAL_SLAVE_UNIT}) begin : genSpi
      tri1 UnusedScl, UnusedSda;
      SerialSlaveCore uSlave (
        .iClk100Mhz(ctrlIf.iClk), .iRst(ctrlIf.iRst), .iSw(SpiSw), .oLed(statusIf.spiLed),
        .iJaCs(spiIf.csn), .iJaSclk(spiIf.sclk), .iJaMosi(spiIf.mosi), .oJaMiso(spiIf.miso),
        .ioJbScl(UnusedScl), .ioJbSda(UnusedSda)
      );
    end else begin : genNoSpi
      assign spiIf.miso = 1'b0;
      assign statusIf.spiLed = '0;
    end
    if (P_TOPOLOGY inside {I2C_SLAVE_UNIT, DUAL_SLAVE_UNIT}) begin : genI2c
      SerialSlaveCore uSlave (
        .iClk100Mhz(ctrlIf.iClk), .iRst(ctrlIf.iRst), .iSw(I2cSw), .oLed(statusIf.i2cLed),
        .iJaCs(1'b1), .iJaSclk(1'b0), .iJaMosi(1'b0), .oJaMiso(),
        .ioJbScl(i2cIf.scl), .ioJbSda(i2cIf.sda)
      );
    end else begin : genNoI2c
      assign statusIf.i2cLed = '0;
    end
  end
endmodule
