`timescale 1ns/1ps
module TbTop #(parameter int P_TOPOLOGY = 0);
  import uvm_pkg::*;
  import serial_tb_types_pkg::*;
  import serial_env_pkg::*;
  logic Clk = 0;
  serial_ctrl_if ctrlIf(.iClk(Clk));
  serial_status_if statusIf(.iClk(Clk), .iRst(ctrlIf.iRst), .epoch(ctrlIf.epoch));
  spi_if spiIf(.iClk(Clk), .iRst(ctrlIf.iRst), .epoch(ctrlIf.epoch), .configId(ctrlIf.configId));
  i2c_if i2cIf(.iClk(Clk), .iRst(ctrlIf.iRst), .epoch(ctrlIf.epoch), .configId(ctrlIf.configId));
  SerialDutHarness #(.P_TOPOLOGY(P_TOPOLOGY)) uHarness(.ctrlIf(ctrlIf), .statusIf(statusIf), .spiIf(spiIf), .i2cIf(i2cIf));
  SpiChecker uSpiChecker(.bus(spiIf));
  I2cChecker uI2cChecker(.bus(i2cIf));
  SerialSystemChecker #(.P_TOPOLOGY(P_TOPOLOGY)) uSystemChecker(.ctrlIf(ctrlIf), .spiIf(spiIf), .i2cIf(i2cIf));
  initial begin : clockBlock
    forever #5ns Clk = ~Clk;
  end
  initial begin : resetRequestBlock
    ctrlIf.applyReset(12);
  end
  initial begin : watchdogBlock
    #10ms;
    $fatal(1, "TB_WATCHDOG");
  end
  initial begin : dumpBlock
    $timeformat(-9,0," ns",10);
    if ($test$plusargs("WAVES")) begin
      $dumpfile("serial.vcd");
      $dumpvars(0,TbTop);
    end
  end
  initial begin : uvmBlock
    spiIf.activeMode = P_TOPOLOGY inside {SPI_SLAVE_UNIT, DUAL_SLAVE_UNIT};
    i2cIf.activeMode = P_TOPOLOGY inside {I2C_SLAVE_UNIT, DUAL_SLAVE_UNIT};
    uvm_config_db#(int)::set(null,"uvm_test_top","topology",P_TOPOLOGY);
    uvm_config_db#(virtual serial_ctrl_if)::set(null,"uvm_test_top.env.ctrlAgent","vif_ctrl",ctrlIf);
    uvm_config_db#(virtual serial_status_if)::set(null,"uvm_test_top.env.ctrlAgent","vif_status",statusIf);
    uvm_config_db#(virtual spi_if)::set(null,"uvm_test_top.env.spiAgent","vif_spi",spiIf);
    uvm_config_db#(virtual i2c_if)::set(null,"uvm_test_top.env.i2cAgent","vif_i2c",i2cIf);
    run_test();
  end
endmodule
