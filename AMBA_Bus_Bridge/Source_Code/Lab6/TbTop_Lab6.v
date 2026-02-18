/*******************************************************************
* - Project          : 2025 summer internship
* - File name        : TbTop_Lab6.v
* - Description      : Testbench top for Lab1
* - Owner            : Inchul.song
* - Revision history : 1) 2025.07.03 : Initial release
********************************************************************/

`timescale 1ns/10ps

module TbTop_Lab6;


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
  // Lab6_Top.v  instantiation
  ***********************************************/
  Lab6_Top A_Lab6_Top (
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
  // iHREADYin function in AHB bus decoder & Mux
  ***********************************************/
  // iHSEL delay with iHREADYin
  reg              rHSEL_Dly;


  // Decoder function in AHB bus matrix
  always @(posedge iClk)
  begin

    if (!iRsn)
      rHSEL_Dly <= 1'b0;
    else if (iHREADYin == 1'b1)
      rHSEL_Dly <= iHSEL;

  end


  // Mux function in AHB bus matrix
  // oHREADY during Lab #6 data phase else 1'b1 !!!
  assign iHREADYin = (rHSEL_Dly == 1'b1) ? oHREADY : 1'b1;



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
  // AHB transaction
  ***********************************************/
  initial
  begin
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Idle
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h0;            // Don't care



    // Addr 0 write  
    // Address phase
    repeat (100) @(posedge iClk);
    iHSEL    <=  1'h1;
    iHTRANS  <=  2'h2;            // Noseq
    iHWRITE  <=  1'h1;            // Write
    iHADDR   <= 32'h70004000;     // Mem Addr 0

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 0
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h11111111;     // Mem Data 0

    // Wait iHREADYin
    wait (iHREADYin);



    // Addr 1 write
    // Address phase
  `ifdef Burst4Case
    repeat (  0) @(posedge iClk);
    iHTRANS  <=  2'h3;            // Seq
  `else
    repeat (  1) @(posedge iClk);
    iHTRANS  <=  2'h2;            // Noseq
  `endif
    iHSEL    <=  1'h1;
    iHWRITE  <=  1'h1;            // Write
    iHADDR   <= 32'h70004004;     // Mem Addr 1

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 1
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h22222222;     // Mem Data 1

    // Wait iHREADYin
    wait (iHREADYin);



    // Addr 2 write
    // Address phase
  `ifdef Burst4Case
    repeat (  0) @(posedge iClk);
    iHTRANS  <=  2'h3;            // Seq
  `else
    repeat (  1) @(posedge iClk);
    iHTRANS  <=  2'h2;            // Noseq
  `endif
    iHSEL    <=  1'h1;
    iHWRITE  <=  1'h1;            // Write
    iHADDR   <= 32'h70004008;     // Mem Addr 2

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 2
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h33333333;     // Mem Data 2

    // Wait iHREADYin
    wait (iHREADYin);



    // Addr 3 write
    // Address phase
  `ifdef Burst4Case
    repeat (  0) @(posedge iClk);
    iHTRANS  <=  2'h3;            // Seq
  `else
    repeat (  1) @(posedge iClk);
    iHTRANS  <=  2'h2;            // Noseq
  `endif
    iHSEL    <=  1'h1;
    iHWRITE  <=  1'h1;            // Write
    iHADDR   <= 32'h7000400C;     // Mem Addr 3

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 3
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h44444444;     // Mem Data 3

    // Wait iHREADYin
    wait (iHREADYin);



    // Dummy wait
    repeat (  5) @(posedge iClk);



    // Addr 0 read
    // Address phase
    repeat (  1) @(posedge iClk);
    iHSEL    <=  1'h1;
    iHTRANS  <=  2'h2;            // Noseq
    iHWRITE  <=  1'h0;            // Read
    iHADDR   <= 32'h70004000;     // Mem Addr 0
    iHWDATA  <= 32'h00000000;     // Don't care

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 0
    repeat (  1) @(posedge iClk);
  `ifdef Burst4Case
  `else
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care

    // Wait iHREADYin
    wait (iHREADYin);
  `endif



    // Addr 1 read
    // Address phase
  `ifdef Burst4Case
    repeat (  1) @(posedge iClk);
    iHTRANS  <=  2'h3;            // Seq
  `else
    repeat (  2) @(posedge iClk);
    iHTRANS  <=  2'h2;            // Noseq
  `endif
    iHSEL    <=  1'h1;
    iHWRITE  <=  1'h0;            // Read
    iHADDR   <= 32'h70004004;     // Mem Addr 1

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 1
    repeat (  1) @(posedge iClk);
  `ifdef Burst4Case
  `else
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care

    // Wait iHREADYin
    wait (iHREADYin);
  `endif



    // Addr 2 read
    // Address phase
  `ifdef Burst4Case
    repeat (  1) @(posedge iClk);
    iHTRANS  <=  2'h3;            // Seq
  `else
    repeat (  2) @(posedge iClk);
    iHTRANS  <=  2'h2;            // Noseq
  `endif
    iHSEL    <=  1'h1;
    iHWRITE  <=  1'h0;            // Read
    iHADDR   <= 32'h70004008;     // Mem Addr 2

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 2
    repeat (  1) @(posedge iClk);
  `ifdef Burst4Case
  `else
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Don't care
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care

    // Wait iHREADYin
    wait (iHREADYin);
  `endif



    // Addr 3 read
    // Address phase
  `ifdef Burst4Case
    repeat (  1) @(posedge iClk);
    iHTRANS  <=  2'h3;            // Seq
  `else
    repeat (  2) @(posedge iClk);
    iHTRANS  <=  2'h2;            // Noseq
  `endif
    iHSEL    <=  1'h1;
    iHWRITE  <=  1'h0;            // Read
    iHADDR   <= 32'h7000400C;     // Mem Addr 3

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase 3
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
  // Display function for write trnasaction
  ***********************************************/
  // Internal signal probing
  wire             wIntWrEn;
  wire [31:0]      wIntHADDR;


  // Write condition
  assign wIntWrEn  = A_Lab6_Top.A_Lab6_AhbIfBlk.rWrValid;
  assign wIntHADDR = A_Lab6_Top.A_Lab6_AhbIfBlk.rHADDR[31:0];


  // Display
  always @(posedge iClk)
  begin

    if (wIntWrEn == 1'b1 && iHREADYin == 1'b1)
    begin
      $display("-----     AHB write 0x%h to   addr 0x%h !!!     -----", iHWDATA[31:0], wIntHADDR[31:0]);
    end

  end



  /***********************************************
  // Display function for read transaction
  ***********************************************/
  // Internal signal probing
  wire             wIntRdEn;


  // Read condition
  assign wIntRdEn = A_Lab6_Top.A_Lab6_AhbIfBlk.rRdValid;


  // Display
  always @(posedge iClk)
  begin

    if (wIntRdEn == 1'b1 && iHREADYin == 1'b1)
    begin
      $display("-----     AHB read  0x%h from addr 0x%h !!!     -----", oHRDATA[31:0], wIntHADDR[31:0]);
    end

  end



  /***********************************************
  // SHM dump
  ***********************************************/
  initial
  begin

  `ifdef Burst4Case
    $shm_open("/user/student/stu2/Internship_JH/Lab6/Testbench/Dump/Lab6_Burst4Case.shm");
    $shm_probe("AC");
  `else
    $shm_open("/user/student/stu2/Internship_JH/Lab6/Testbench/Dump/Lab6.shm");
    $shm_probe("AC");
  `endif

  end


endmodule
