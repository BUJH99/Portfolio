/*******************************************************************
* - Project          : 2025 summer internship course
* - File name        : TbTop_Lab1.v
* - Description      : Testbench top for Lab1
* - Owner            : Inchul.song
* - Revision history : 1) 2025.06.24 : Initial release
********************************************************************/

`timescale 1ns/10ps

module TbTop_Lab1;


  /***********************************************
  // wire & register
  ***********************************************/
  reg              iClk;
  reg              iRsn;


  reg              iInEnable;
  reg  [31:0]      iInA;
  reg  [31:0]      iInB;

  reg              iOutEnable;
  wire [31:0]      oOutC;

  reg              rRltChkTime;



  /***********************************************
  // Lab1_Top.v instantiation
  ***********************************************/
  Lab1_Top A_Lab1_Top (
  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // APB interface
  .iInEnable       (iInEnable),
  .iInA            (iInA[31:0]),
  .iInB            (iInB[31:0]),

  .iOutEnable      (iOutEnable),
  .oOutC           (oOutC[31:0])
  );



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
  // Input signals modeling
  ***********************************************/
  initial
  begin
    iInEnable   <=  1'h0;

    iInA        <=  1'h0;
    iInB        <=  1'h0;

    iOutEnable  <= 16'h0;

    rRltChkTime <= 1'h0;


    // Data input
    repeat (100) @(posedge iClk);
    iInA        <=  32'h5A5A5A5A;
    iInB        <=  32'hA5A5A5A5;
    

    // Input enable
    repeat (  5) @(posedge iClk);
    iInEnable   <=  1'h1;
    repeat (  1) @(posedge iClk);
    iInEnable   <=  1'h0;


    // Output enable
    repeat (100) @(posedge iClk);
    iOutEnable  <=  1'h1;
    repeat (  1) @(posedge iClk);
    iOutEnable  <=  1'h0;
    rRltChkTime <=  1'h1;
    repeat (  1) @(posedge iClk);
    rRltChkTime <=  1'h0;



    // Finish
    repeat (100) @(posedge iClk);
    $finish;
  end


  // Result check
  always @(posedge iClk)
  begin


    if (rRltChkTime == 1'b1)
    begin

      if (oOutC[31:0] == 32'hFFFFFFFF)
      begin
        $display ("---------------------------------");
        $display ("OOOO oOutC result Passed !!! OOOO");
        $display ("---------------------------------");
      end
      else
      begin
        $display ("---------------------------------");
        $display ("XXXXX oOutc data Failed !!! XXXXX");
        $display ("---> Must debug this !!!!!!! <---");
        $display ("---------------------------------");
      end

    end

  end


  /***********************************************
  // SHM dump
  ***********************************************/
  initial
  begin
    $shm_open("/user/student/stu2/Internship_JH/Lab1/Testbench/Dump/Lab1.shm");
    $shm_probe("AC");
  end


endmodule
