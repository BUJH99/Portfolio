/*******************************************************************
* - Project          : 2025 summer internship
* - File name        : TbTop_Lab2.v
* - Description      : Testbench top for Lab2
* - Owner            : Inchul.song
* - Revision history : 1) 2024.12.26 : Initial release
*                      2) 2025.06.25 : add oPready
********************************************************************/

`timescale 1ns/10ps

module TbTop_Lab2;


  /***********************************************
  // wire & register
  ***********************************************/
  reg              iClk;
  reg              iRsn;


  reg              iPsel;
  reg              iPenable;
  reg              iPwrite;
  reg  [15:0]      iPaddr;

  reg  [31:0]      iPwdata;
  wire [31:0]      oPrdata;
  wire             oPready;



  /***********************************************
  // FstPrjTop.v  instantiation
  ***********************************************/
  Lab2_Top A_Lab2_Top (
  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // APB interface
  .iPsel           (iPsel),
  .iPenable        (iPenable),
  .iPwrite         (iPwrite),
  .iPaddr          (iPaddr[15:0]),

  .iPwdata         (iPwdata[31:0]),
  .oPrdata         (oPrdata[31:0]),
  .oPready         (oPready)
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
  // APB interface
  ***********************************************/
  initial
  begin
    iPsel    <=  1'h0;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h0;
    iPwdata  <= 32'h0;



    // Reg A write
    repeat (100) @(posedge iClk);
    iPsel    <=  1'h1;
    iPenable <=  1'h0;
    iPwrite  <=  1'h1;
    iPaddr   <= 16'h0000;
    iPwdata  <= 32'h5A5A5A5A;
    
    repeat (  1) @(posedge iClk);
    iPenable <=  1'h1;

    // Wait oPready 
    wait (oPready);

    repeat (  1) @(posedge iClk);
    iPsel    <=  1'h0;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h0;
    iPwdata  <= 32'h0;



    // Reg B write
    repeat (100) @(posedge iClk);
    iPsel    <=  1'h1;
    iPenable <=  1'h0;
    iPwrite  <=  1'h1;
    iPaddr   <= 16'h0004;
    iPwdata  <= 32'hA5A5A5A5;
    
    repeat (  1) @(posedge iClk);
    iPenable <=  1'h1;

    // Wait oPready 
    wait (oPready);

    repeat (  1) @(posedge iClk);
    iPsel    <=  1'h0;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h0;
    iPwdata  <= 32'h0;



    // Reg C read
    repeat (100) @(posedge iClk);
    iPsel    <=  1'h1;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h000C;
    iPwdata  <= 32'h0;
    
    repeat (  1) @(posedge iClk);
    iPenable <=  1'h1;

    // Wait oPready 
    wait (oPready);

    repeat (  1) @(posedge iClk);
    iPsel    <=  1'h0;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h0;
    iPwdata  <= 32'h0;


    // Finish
    repeat (100) @(posedge iClk);
    $finish;
  end



  // Display read data
  always @(posedge iClk)
  begin

    if (iPsel == 1'b1 && iPenable == 1'b1 && iPwrite == 1'b0
                      && oPready == 1'b1  && iPaddr[15:0] == 16'h000C)
    begin
      $display("OOOOO APB read data = 0x%h !!! OOOOO", oPrdata[31:0]);
    end

  end



  /***********************************************
  // VCD dump
  ***********************************************/
  initial
  begin
    $shm_open("/user/student/stu2/Internship_JH/Lab2/Testbench/Dump/Lab2.shm");
    $shm_probe("AC");
  end


endmodule
