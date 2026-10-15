`timescale 1ns/1ps
interface serial_ctrl_if(input logic iClk);
  logic iRst = 1'b1;
  bit initialized = 0;
  bit protocolSel = 0;
  bit [6:0] masterData = 0, spiSwitch = 0, i2cSwitch = 0;
  int unsigned epoch = 0, configId = 0;
  logic masterBusy, cmdLoad;
  semaphore sema_reset = new(1);
  clocking cbDrv @(negedge iClk);
    default input #1step output #0;
    output protocolSel, masterData, spiSwitch, i2cSwitch, configId;
    input masterBusy, cmdLoad, iRst, epoch, initialized;
  endclocking
  clocking cbMon @(posedge iClk);
    default input #1step;
    input protocolSel, masterData, spiSwitch, i2cSwitch, configId;
    input masterBusy, cmdLoad, iRst, epoch, initialized;
  endclocking
  // Only this service assigns reset/epoch, including the initial reset request.
  task automatic applyReset(input int unsigned cycles = 12);
    sema_reset.get();
    @(negedge iClk);
    iRst = 1'b1;
    epoch++;
    repeat (cycles) @(negedge iClk);
    iRst = 1'b0;
    initialized = 1;
    sema_reset.put();
  endtask
  modport driver(clocking cbDrv, import applyReset);
  modport monitor(clocking cbMon);
endinterface
