`timescale 1ns/1ps
interface serial_status_if(input logic iClk, input logic iRst, input int unsigned epoch);
  logic [15:0] masterLed, spiLed, i2cLed;
  clocking cbMon @(posedge iClk);
    default input #1step;
    input iRst, epoch, masterLed, spiLed, i2cLed;
  endclocking
  modport monitor(clocking cbMon);
endinterface
