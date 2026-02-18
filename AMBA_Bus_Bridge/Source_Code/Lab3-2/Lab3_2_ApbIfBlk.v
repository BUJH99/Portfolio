/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab3_2_ApbIfBlk.v
  - Description      : Mem to Mem w/ 2's complement
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
                       2) 2025.06.25 : add oPready
*******************************************************************/

`timescale 1ns/10ps

module Lab3_2_ApbIfBlk (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // APB interface
  input            iPsel,
  input            iPenable,
  input            iPwrite,
  input  [15:0]    iPaddr,

  input  [31:0]    iPwdata,
  output [31:0]    oPrdata,
  output           oPready,


  // FthDataCp.v interface
  output           oStDtCp,            // 1-clock high enable
  output [9:0]     oPktWdSize,         // Packet word(4Byte) size, Max 512(0x200)

  input            iDtCpDone,          // 1-clock high enable


  // InBuf(BufWrap) write interface
  output           oWrEn_InBuf,        // Write enable
  output [8:0]     oWrAddr_InBuf,      // Write address
  output [31:0]    oWrDt_InBuf,        // 32bit write data


  // OutBuf(BufWrap) read interface
  output           oRdEn_OutBuf,       // Read enable
  output [8:0]     oRdAddr_OutBuf,     // Read address
  input  [31:0]    iRdDt_OutBuf,       // 32bit read data


  // Out enable to Testbench
  output           oOutEnable

  );


  // wire & reg declaration
  wire             wWrEn;              // Register write enable
  wire             wRdEn;              // Register read  enable

  reg  [31:0]      rPrdata;            // APB read register


  // InBuf write access
  wire             wWrEn_InBuf;
  wire [8:0]       wWrAddr_InBuf;
  wire [31:0]      wWrDt_InBuf;


  // FthDataCp.v access
  wire             wStDtCp;
  reg  [9:0]       rPktWdSize;


  // OutBuf read access
  wire              wRdEn_OutBuf;
  wire [8:0]        wRdAddr_OutBuf;
  wire [31:0]       wRdDt_OutBuf;


  // oPrdata realted signals
  reg  [31:0]       rPrdata_Reg;
  wire [31:0]       wPrdata_Reg;

  wire [31:0]       wPrdata_Mem;

  wire [31:0]       wPrdata;



  /*******************************************************************/
  // APB read & write enable
  /*******************************************************************/
  // Register write enable @enable phase
  assign wWrEn =  (  (iPsel    == 1'b1)
                   & (iPenable == 1'b0)
	           & (iPwrite  == 1'b1) ) ? 1'b1 : 1'b0;

  // Register read enable @setup phase
  assign wRdEn = (  (iPsel    == 1'b1)
                  & (iPenable == 1'b0)
		  & (iPwrite  == 1'b0) ) ? 1'b1 : 1'b0;



  /*******************************************************************/
  // InBuf write access (0x4000 ~)
  /*******************************************************************/
  // InBuf write enable
  assign wWrEn_InBuf    = (wWrEn == 1'b1 && iPaddr[15:11] == 5'b01000) ? 1'b1 : 1'b0;

  // InBuf write address(word address & 512 depth)
  assign wWrAddr_InBuf  = iPaddr[10:2];

  // InBuf write data
  assign wWrDt_InBuf    = iPwdata[31:0];



  /*******************************************************************/
  // FtDataCp.v control (Start cmd: 0x0000, Pkt word size: 0x0004)
  /*******************************************************************/
  // Start command
  assign wStDtCp = (wWrEn == 1'b1 && iPaddr[15:0] == 16'h0
                                  && iPwdata[0]   == 1'h1 ) ? 1'b1 : 1'b0;

  // Packet word size
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      rPktWdSize <= 10'h0;
    else if (wWrEn == 1'b1 && iPaddr[15:0] == 16'h4)
      rPktWdSize <= iPwdata[9:0]; 

  end



  /*******************************************************************/
  // OutBuf read access (0x6000 ~)
  /*******************************************************************/
  // OutBuf read enable
  assign wRdEn_OutBuf   = (wRdEn == 1'b1 && iPaddr[15:11] == 5'b01100) ? 1'b1 : 1'b0;

  // OutBuf read address(word address & 512 depth) 
  assign wRdAddr_OutBuf = iPaddr[10:2];

  // OutBuf read data
  assign wRdDt_OutBuf   = iRdDt_OutBuf[31:0];



  /*******************************************************************/
  // Prdata mux
  /*******************************************************************/
  // Prdata from register
  always @(posedge iClk)
  begin
  
    // Synchronous & low reset
    if (!iRsn)
    begin
      rPrdata_Reg <= 32'h0;
    end
    else if (wRdEn == 1'b1)
    begin

      if (iPaddr[15:0] == 16'h0004)
        rPrdata_Reg <= {22'h0, rPktWdSize[9:0]};
      else
        rPrdata_Reg <= 32'h0;

    end

  end

  // Prdata from OutBuf
  assign wPrdata_Mem = wRdDt_OutBuf[31:0];

  // Mux Prdata signals from Reg. & Mem.
  assign wPrdata     = (iPaddr[15:12] == 4'h6) ? wPrdata_Mem[31:0] :
                                                 rPrdata_Reg[31:0];


  /*******************************************************************/
  // Output data assignment
  /*******************************************************************/
  // oPrdata & oPready
  assign oPrdata        = wPrdata[31:0];
  assign oPready        = (iPsel == 1'b1 && iPenable == 1'b1) ? 1'b1 : 1'b0;

  // FthDataCp.v interface
  assign oStDtCp        = wStDtCp;
  assign oPktWdSize     = rPktWdSize[9:0];

  // InBuf interface
  assign oWrEn_InBuf    = wWrEn_InBuf;
  assign oWrAddr_InBuf  = wWrAddr_InBuf[8:0];
  assign oWrDt_InBuf    = wWrDt_InBuf[31:0];

  // OutBuf interface
  assign oRdEn_OutBuf   = wRdEn_OutBuf;
  assign oRdAddr_OutBuf = wRdAddr_OutBuf[8:0];

  // Interrupt
  assign oOutEnable     = iDtCpDone;



endmodule
