`timescale 1ns/1ps
interface spi_if(input logic iClk, input logic iRst, input int unsigned epoch, configId);
  logic csn, sclk, mosi, miso;
  bit driveCsn = 1, driveSclk = 0, driveMosi = 0;
  bit activeMode = 0;
  clocking cbDrv @(negedge iClk);
    default input #1step output #0;
    output driveCsn, driveSclk, driveMosi;
    input iRst, miso;
  endclocking
  clocking cbMon @(posedge iClk);
    default input #1step;
    input csn, sclk, mosi, miso, iRst, epoch, configId;
  endclocking
  modport driver(clocking cbDrv);
  modport monitor(clocking cbMon);
endinterface
