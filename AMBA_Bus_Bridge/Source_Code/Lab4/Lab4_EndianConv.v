/**********************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab4_EndianCov.v
  - Description      : Endian conversion function 
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
**********************************************************************/

`timescale 1ns/10ps

module Lab4_EndianConv (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // FthApbIfBlk.v interface
  input            iStDtCp,            // 1-clock high enable
  input  [9:0]     iPktWdSize,         // Packet word(4Byte) size, Max 512(0x200)

  output           oDtCpDone,          // 1-clock high enable


  // InBuf(BufWrap.v) read interface
  output           oRdEn_InBuf,        // Read enable
  output [8:0]     oRdAddr_InBuf,      // Read address
  input  [31:0]    iRdDt_InBuf,        // 32bit read data 


  // OutBuf(BufWrap.v) write interface
  output           oWrEn_OutBuf,       // Write enable
  output [8:0]     oWrAddr_OutBuf,     // Write address
  output [31:0]    oWrDt_OutBuf        // 32bit write data

  );



  // Parameter
  parameter   p_Idle        = 3'b000,

              p_StDtCp      = 3'b001,

              p_FstRdInBuf  = 3'b010,
              p_FstDtLatch  = 3'b011,

              p_RdAndWr     = 3'b100,

              p_LstDtLatch  = 3'b101,
              p_LstWrOutBuf = 3'b110,

              p_DtCpDone    = 3'b111;



  // wire & reg
  reg  [2:0]  rCurState;
  reg  [2:0]  rNxtState;

  wire        wEnStDtCp;
  wire        wEnFstRdInBuf;
  wire        wEnFstDtLatch;
  wire        wEnRdAndWr;
  wire        wEnLstDtLatch;
  wire        wEnLstWrOutBuf;
  wire        wEnDtCpDone;


  wire        wRdEn_InBuf;
  reg  [8:0]  rRdAddr_InBuf;
  wire [31:0] wRdDt_InBuf;


  wire [31:0] wRdDt_EndianConv;
  wire        wEnDtLatch;
  reg  [31:0] rRdDt_EndianConvLat;


  wire        wWrEn_OutBuf;
  reg  [8:0]  rWrAddr_OutBuf;
  wire [31:0] wWrDt_OutBuf;


  wire [9:0]  wLastRdInBuf;
  wire        wLastWordFlag;



  /**************************************************/
  // FSM
  /**************************************************/
  // Current state update
  always @(posedge iClk)
  begin

    if (!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState[2:0]; 

  end


  // Next state decision
  always @(*)
  begin

    case (rCurState)

      p_Idle     :
        if (iStDtCp == 1'b1)
          rNxtState <= p_StDtCp;
        else
          rNxtState <= p_Idle;



      p_StDtCp   :
        rNxtState <= p_FstRdInBuf;



      p_FstRdInBuf   :
        rNxtState <= p_FstDtLatch;

      p_FstDtLatch  :
        rNxtState <= p_RdAndWr;



      p_RdAndWr  :
        if (wLastWordFlag == 1'b1)
          rNxtState <= p_LstDtLatch;
        else
          rNxtState <= p_RdAndWr;
 


      p_LstDtLatch :
          rNxtState <= p_LstWrOutBuf;

      p_LstWrOutBuf :
          rNxtState <= p_DtCpDone;



      p_DtCpDone :
        rNxtState <= p_Idle;


      default    :
        rNxtState <= p_Idle;

    endcase

  end



  /**************************************************/
  // Control signals
  /**************************************************/
  // Each enable
  assign wEnStDtCp      = (rCurState == p_StDtCp     ) ? 1'b1 : 1'b0;

  assign wEnFstRdInBuf  = (rCurState == p_FstRdInBuf ) ? 1'b1 : 1'b0;
  assign wEnFstDtLatch  = (rCurState == p_FstDtLatch ) ? 1'b1 : 1'b0;

  assign wEnRdAndWr     = (rCurState == p_RdAndWr    ) ? 1'b1 : 1'b0;

  assign wEnLstDtLatch  = (rCurState == p_LstDtLatch ) ? 1'b1 : 1'b0;
  assign wEnLstWrOutBuf = (rCurState == p_LstWrOutBuf) ? 1'b1 : 1'b0;

  assign wEnDtCpDone    = (rCurState == p_DtCpDone   ) ? 1'b1 : 1'b0;



  /**************************************************/
  // InBuf read signal
  /**************************************************/
  // Read enable
  assign wRdEn_InBuf = (wEnFstRdInBuf | wEnFstDtLatch | wEnRdAndWr);

  // Read address
  always @(posedge iClk)
  begin

    if (!iRsn)
    begin
      rRdAddr_InBuf <= 9'h0;
    end
    else if (wEnStDtCp == 1'b1 || wEnDtCpDone == 1'b1)
    begin
      rRdAddr_InBuf <= 9'h0;
    end
    else if (wRdEn_InBuf == 1'b1)
    begin

      if (rRdAddr_InBuf == 9'h1ff)
        rRdAddr_InBuf <= 9'h1ff;
      else
        rRdAddr_InBuf <= 9'( rRdAddr_InBuf[8:0] + 9'h1 );

    end

  end

  // Read data
  assign wRdDt_InBuf = iRdDt_InBuf[31:0];




  /**************************************************/
  // Data endian conversion & latch
  /**************************************************/
  // Endian conversion
  assign wRdDt_EndianConv = {wRdDt_InBuf[ 7: 0],
                             wRdDt_InBuf[15: 8],
                             wRdDt_InBuf[23:16],
                             wRdDt_InBuf[31:24]};


  // Read data latch enable
  assign wEnDtLatch = (wEnFstDtLatch | wEnRdAndWr | wEnLstDtLatch);


  // Read data latch
  always @(posedge iClk)
  begin

    if (!iRsn)
     rRdDt_EndianConvLat <= 32'h0;
    else if (wEnDtLatch == 1'b1)
     rRdDt_EndianConvLat <= wRdDt_EndianConv[31:0];

  end



  /**************************************************/
  // OutBuf write signal
  /**************************************************/
  // Write enable
  assign wWrEn_OutBuf   = (wEnRdAndWr | wEnLstDtLatch | wEnLstWrOutBuf);

  // Write address
  always @(posedge iClk)
  begin

    if (!iRsn)
    begin
      rWrAddr_OutBuf <= 9'h0;
    end
    else if (wEnStDtCp == 1'b1 || wEnDtCpDone == 1'b1)
    begin
      rWrAddr_OutBuf <= 9'h0;
    end
    else if (wWrEn_OutBuf == 1'b1)
    begin

      if (rWrAddr_OutBuf == 9'h1ff)
        rWrAddr_OutBuf <= 9'h1ff;
      else
        rWrAddr_OutBuf <= 9'( rWrAddr_OutBuf[8:0] + 9'h1 );

    end

  end

  // Write data
  assign wWrDt_OutBuf   = rRdDt_EndianConvLat[31:0];



  /**************************************************/
  // Last read & write flag
  /**************************************************/
  // Last read address of InBuf
  assign wLastRdInBuf  = 9'( iPktWdSize[9:0] - 10'h1 );

  // Last read access flag
  assign wLastWordFlag = (rRdAddr_InBuf[8:0] == wLastRdInBuf[8:0]) ? 1'b1 : 1'b0;



  /**************************************************/
  // Out mapping
  /**************************************************/
  // Data copy done to FthApbIfBlk.v
  assign oDtCpDone      = wEnDtCpDone;


  // InBuf access
  assign oRdEn_InBuf    = wRdEn_InBuf;
  assign oRdAddr_InBuf  = rRdAddr_InBuf[8:0];


  // Outbuf access
  assign oWrEn_OutBuf   = wWrEn_OutBuf;
  assign oWrAddr_OutBuf = rWrAddr_OutBuf[8:0];
  assign oWrDt_OutBuf   = wWrDt_OutBuf[31:0];


endmodule
