/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : SpSram.v
  - Description      : Single Port SRAM modeling
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module SpSram (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // SP-SRAM Input & Output
  input            iCsn,               // Chip selected @ Low
  input            iWrn,               // 0:Write, 1:Read
  input  [1:0]     iAddr,              // 32bit data address

  input  [31:0]    iWrDt,              // Write data
  output [31:0]    oRdDt               // Read data

  );



  // Parameter declaration
 


  // Integer declaration
  integer          i;



  // wire & reg declaration
  reg  [31:0]      rMem[0:3];          // 4*32 array

  reg  [31:0]      rRdDt;



  /*************************************************************/
  // SP-SRAM function
  /*************************************************************/
  // rMem write operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      for (i=0 ; i<4 ; i=i+1)
      begin
        rMem[i] <= 32'h0;
      end
    end

    // Write condition
    else if (iCsn == 1'b0 && iWrn == 1'b0)
    begin
      rMem[iAddr] <= iWrDt[31:0];
    end

  end


  // rMem read operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rRdDt <= 32'h0;
    end

    // Read codition
    else if (iCsn == 1'b0 && iWrn == 1'b1)
    begin
      rRdDt <= rMem[iAddr];
    end

  end



  // Output mapping
  assign oRdDt = rRdDt[31:0];


endmodule
