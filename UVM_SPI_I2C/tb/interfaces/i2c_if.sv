`timescale 1ns/1ps
interface i2c_if(input logic iClk, input logic iRst, input int unsigned epoch, configId);
  tri1 scl, sda;
  bit sclDriveLow = 0, sdaDriveLow = 0;
  bit activeMode = 0, frameActive = 0;
  assign scl = (activeMode && sclDriveLow) ? 1'b0 : 1'bz;
  assign sda = (activeMode && sdaDriveLow) ? 1'b0 : 1'bz;
  clocking cbDrv @(negedge iClk);
    default input #1step output #0;
    output sclDriveLow, sdaDriveLow;
    input scl, sda, iRst;
  endclocking
  clocking cbMon @(posedge iClk);
    default input #1step;
    input scl, sda, iRst, epoch, configId;
  endclocking
  modport driver(clocking cbDrv);
  modport monitor(clocking cbMon);
endinterface
