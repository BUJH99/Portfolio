`timescale 1ns/10ps


module Project_Top (
  // Clock & Reset
  input            iClk,
  input            iRsn,

  // AHB Interface 
  input            iHSEL,
  input  [31:0]    iHADDR,
  input  [1:0]     iHTRANS,
  input            iHWRITE,
  input            iHREADYin,
  input  [31:0]    iHWDATA,
  
  output [31:0]    oHRDATA,
  output           oHREADYout,
  output [1:0]     oHRESP
);

  // Wire Ahb2Apb
  wire           wPSEL;
  wire           wPENABLE;
  wire           wPWRITE;
  wire  [15:0]   wPADDR;
  wire  [31:0]   wPWDATA;
  wire  [31:0]   wPRDATA;
  wire           wPREADY;

  //----------------------------------------------------------------
  // Instantiate the Ahb2Apb_Top
  //----------------------------------------------------------------
  Ahb2Apb_Top I_Ahb2Apb_Top (
    .iClk       (iClk),
    .iRsn       (iRsn),
    .iHSEL      (iHSEL),
    .iHADDR     (iHADDR),
    .iHTRANS    (iHTRANS),
    .iHWRITE    (iHWRITE),
    .iHREADYin  (iHREADYin),
    .iHWDATA    (iHWDATA),
    .oHRDATA    (oHRDATA),
    .oHREADYout (oHREADYout),
    .oHRESP     (oHRESP),
    .oPSEL      (wPSEL),
    .oPENABLE   (wPENABLE),
    .oPWRITE    (wPWRITE),
    .oPADDR     (wPADDR),
    .oPWDATA    (wPWDATA),
    .iPRDATA    (wPRDATA),
    .iPREADY    (wPREADY)
  );

  //----------------------------------------------------------------
  // Instantiate the ApbSlave_Top
  //----------------------------------------------------------------
  ApbSlave_Top I_ApbSlave_Top (
    .iClk       (iClk),
    .iRsn       (iRsn),
    .iPsel      (wPSEL),
    .iPenable   (wPENABLE),
    .iPwrite    (wPWRITE),
    .iPaddr     (wPADDR),
    .iPwdata    (wPWDATA),
    .oPrdata    (wPRDATA),
    .oPready    (wPREADY)
  );

endmodule