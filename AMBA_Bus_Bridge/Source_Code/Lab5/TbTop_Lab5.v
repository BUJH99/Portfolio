/*******************************************************************
* - Project          : 2025 summer internship
* - File name        : TbTop_Lab5.v
* - Description      : Testbench top for Lab5
* - Owner            : Inchul.song
* - Revision history : 1) 2025.06.30 : Initial release
********************************************************************/

`timescale 1ns/10ps

module TbTop_Lab5;


  /***********************************************
  // wire & register
  ***********************************************/
  reg              iClk;
  reg              iRsn;


  reg             iHSEL;
  reg  [1:0]      iHTRANS;
  reg             iHWRITE;
  reg  [31:0]     iHADDR;

//reg             iHREADYin;
  wire            iHREADYin;

  reg  [31:0]     iHWDATA;

  wire [31:0]     oHRDATA;
  wire [1:0]      oHRESP;
  wire            oHREADY;



  /***********************************************
  // Lab5_Top.v instantiation
  ***********************************************/
  Lab5_Top A_Lab5_Top (
  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // AHB interface
  .iHSEL           (iHSEL),
  .iHTRANS         (iHTRANS[1:0]),
  .iHWRITE         (iHWRITE),
  .iHADDR          (iHADDR[31:0]),
  .iHREADYin       (iHREADYin),

  .iHWDATA         (iHWDATA[31:0]),

  .oHRDATA         (oHRDATA[31:0]),
  .oHRESP          (oHRESP[1:0]),
  .oHREADY         (oHREADY)
  );



  /***********************************************
  // iHREADYin connection
  ***********************************************/
  // No mux because of single slave condition !!!
  assign iHREADYin = oHREADY;



  /***********************************************
  // Clock define
  ***********************************************/
  initial
  begin
    iClk <= 1'b0;
  end


  always
  begin
    // 100MHz clock
    #5 iClk <= ~iClk;
  end



  /***********************************************
  // Sync. & active low reset define
  ***********************************************/
  initial
  begin
    iRsn <= 1'b1;

    repeat (  5) @(posedge iClk);
    iRsn <= 1'b0;

    repeat (  2) @(posedge iClk);
    $display("OOOOO Reset released !!! OOOOO");  
    iRsn <= 1'b1;
  end



  /***********************************************
  // AHB interface
  ***********************************************/
  initial
  begin
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Idle
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h0;            // Don't care


    // Reg A write
    // Address phase
    repeat (100) @(posedge iClk);
    iHSEL    <=  1'h1;
    iHTRANS  <=  2'h2;            // Noseq
    iHWRITE  <=  1'h1;            // Write
    iHADDR   <= 32'h0;            // Register A

    // Wait iHREADYin
    wait (iHREADYin);
 
    // Data phase
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h5A5A5A5A;     // Register A write value

    // Wait iHREADYin
    wait (iHREADYin);


    // Reg B write
    // Address phase
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h1;
    iHTRANS  <=  2'h2;            // Noseq
    iHWRITE  <=  1'h1;            // Write
    iHADDR   <= 32'h4;            // Register B

    // Wait iHREADYin
    wait (iHREADYin);
 
    // Data phase
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'hA5A5A5A5;     // Register B write value

    // Wait iHREADYin
    wait (iHREADYin);

 

    // Reg C read
    // Address phase
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h1;
    iHTRANS  <=  2'h2;            // Noseq
    iHWRITE  <=  1'h0;            // Read
    iHADDR   <= 32'h8;            // Register C

    // Wait iHREADYin
    wait (iHREADYin);
 
    // Data phase
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care

    // Wait iHREADYin
    wait (iHREADYin);
 
 

    // Finish
    repeat (100) @(posedge iClk);
    $finish;
  end


  
  /***********************************************
  // Display read data
  ***********************************************/
  // Internal signal probing
  wire             wIntRdSelOutC;

  assign wIntRdSelOutC = A_Lab5_Top.A_Lab5_AhbIfBlk.wRdSelOutC;


  // Display
  always @(posedge iClk)
  begin

    if (wIntRdSelOutC == 1'b1)
    begin
      $display("OOOOO AHB read data = 0x%h !!! OOOOO", oHRDATA[31:0]);
    end

  end



  /***********************************************
  // VCD dump
  ***********************************************/
  initial
  begin
    $shm_open("/user/student/stu2/Internship_JH/Lab5/Testbench/Dump/Lab5.shm");
    $shm_probe("AC");
  end


endmodule
