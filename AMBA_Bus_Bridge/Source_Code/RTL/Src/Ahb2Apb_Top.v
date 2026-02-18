`timescale 1ns/10ps

module Ahb2Apb_Top (
  // Clock & Reset
  input            iClk,
  input            iRsn,

  // AHB Interface
  input            iHSEL,
  input  [1:0]     iHTRANS,
  input            iHWRITE,
  input  [31:0]    iHADDR,
  input 		   iHREADYin, 
   
  input  [31:0]    iHWDATA,
  
  output [31:0]    oHRDATA,
  output reg[1:0]  oHRESP,
  output           oHREADYout,
  

  // APB Interface
  output           oPSEL,
  output           oPENABLE,
  output           oPWRITE,
  output [15:0]    oPADDR,
  
  output [31:0]    oPWDATA,
  
  input  [31:0]    iPRDATA,
  input            iPREADY
);

  // FSM
  parameter p_Idle   = 2'b00;
  parameter p_Setup  = 2'b01;
  parameter p_Enable = 2'b10;

  reg [1:0] rCurState;
  reg [1:0] rNxtState;

  // wire & reg
  reg [31:0] rHADDR;
  reg        rHWRITE;
    
  wire 		wWrValid; 
  wire 		wRdValid; 
  
  wire 		wEnIdle;
  wire 		wEnSetup;
  wire 		wEnEnable;
  
  wire      ADDRInRANGE;
  
	

  //valid signal AHB transfer

  
 
  
  assign wWrValid = (  (iHSEL       == 1'b1)
					&& (iHTRANS[1]  == 1'b1) // 10=NONSEQ, 11=SEQ
					&& (iHWRITE     == 1'b1) ) ? 1'b1 : 1'b0;
  assign wRdValid = (  (iHSEL       == 1'b1)
					&& (iHTRANS[1]  == 1'b1) // 10=NONSEQ, 11=SEQ
					&& (iHWRITE     == 1'b0) ) ? 1'b1 : 1'b0;
					
  /**********************************************************************
   * FSM
   **********************************************************************/
  // Current state update
  always @(posedge iClk)
  begin
  
    if (!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState[1:0];
	  
  end

  // Next state decision
  always @(*)
  begin
  
    case (rCurState)
	
      p_Idle	:
        if (wWrValid || wRdValid) //wWrvalid or wRdvalid enable => Next cycle 
          rNxtState <= p_Setup;
        else
          rNxtState <= p_Idle;
 
      p_Setup	: 
        rNxtState <= p_Enable; // Next cycle

      p_Enable	:  
        if (iPREADY) // 
          if (wWrValid || wRdValid) // Next Write/Read 있을 시 setup
            rNxtState <= p_Setup;
          else						// Next Write/Read 없을 시 Idle
            rNxtState <= p_Idle;
		else
		    rNxtState <= p_Enable;
      default: 
        rNxtState = p_Idle;
    endcase
  end

  /**********************************************************************
   * Control Signal
   **********************************************************************/
  assign wEnIdle   = (rCurState == p_Idle)   ? 1'b1 : 1'b0;
  assign wEnSetup  = (rCurState == p_Setup)  ? 1'b1 : 1'b0;
  assign wEnEnable = (rCurState == p_Enable) ? 1'b1 : 1'b0;

  /**********************************************************************
   * Data Latching Logic @ AHB one wait
   **********************************************************************/
    // address Phase 
  always @(posedge iClk) 
  begin
    if (!iRsn)
	begin 
      rHADDR   <= 32'h0;
    end
	
	else if (wEnIdle && (iHREADYin == 1'b1))
	begin

      rHADDR   <= iHADDR[31:0];
	  rHWRITE  <= iHWRITE;
    end
  end


  /**********************************************************************
   * Output Logic @ APB zero wait
   **********************************************************************/

  // APB Select: Setup or Enable state 
  assign oPSEL = (wEnSetup || wEnEnable) ? 1'b1 : 1'b0;

  // APB Enable: Enable
  assign oPENABLE = wEnEnable;
  
  // APB write signal
  assign oPADDR  = rHADDR[15:0];
  assign oPWRITE = rHWRITE;
  assign oPWDATA = iHWDATA[31:0];
  
  // AHB Ready: Setup = 0 @ Wait state
  assign oHREADYout = wEnSetup ? 1'b0 : (wEnEnable ? iPREADY : 1'b1);
  
  // AHB read signal
  assign oHRDATA = iPRDATA[31:0];
  
  // AHB oHRESP
  always @(*) 
  begin
  
	if (wEnEnable && iPREADY) 
	begin
      oHRESP = 2'b00; // OKAY
    end
	
    else 
	begin
      oHRESP = 2'bxx; 
    end
	
  end

endmodule