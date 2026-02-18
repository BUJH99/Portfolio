/*******************************************************************
* - Project          : 2025 summer internship
* - File name        : TbTop_Lab5_wTask.v
* - Description      : Testbench top with task for Lab5
* - Owner            : Inchul.song
* - Revision history : 1) 2025.06.30 : Initial release
********************************************************************/

`timescale 1ns/10ps

module TbTop_Lab5_wTask;


  /***********************************************
  // wire & register
  ***********************************************/
  reg              iClk;
  reg              iRsn;


  reg              iHSEL;
  reg  [1:0]       iHTRANS;
  reg              iHWRITE;
  reg  [31:0]      iHADDR;

//reg              iHREADYin;
  wire             iHREADYin;

  reg  [31:0]      iHWDATA;

  wire [31:0]      oHRDATA;
  wire [1:0]       oHRESP;
  wire             oHREADY;



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
  // APB write task
  ***********************************************/
  task ahb_write (
    input  [31:0]  addr,
    input  [31:0]  data
  );
  begin

    // Address phase
    repeat (  0) @(posedge iClk);
    iHSEL   <= 1'h1;
    iHTRANS <= 2'h2;              // Noseq
    iHWRITE <= 1'h1;              // Write
    iHADDR  <= addr[31:0];        // Register address

    // Wait iHREADYin
    wait (iHREADYin);

    // Data phase
    repeat (  1) @(posedge iClk);
    iHSEL   <= 1'h0;
    iHTRANS <= 2'h0;              // Don't care
    iHWRITE <= 1'h0;              // Don't care
    iHADDR  <= 32'hFFFFFFFF;      // Don't care
    iHWDATA <= data[31:0];        // Register write data

    // Wait iHREADYin
    wait (iHREADYin);

    repeat (  1) @(posedge iClk);
    $display("OOOOO Write 0x%h at   addr 0x%h !!! OOOOO", data[31:0], addr[31:0]);

  end
  endtask


    
  /***********************************************
  // APB read task
  ***********************************************/
  task ahb_read (
    input  [31:0]  addr
  );
  begin

    // Address phase
    repeat (  0) @(posedge iClk);
    iHSEL    <=  1'h1;
    iHTRANS  <=  2'h2;            // Noseq
    iHWRITE  <=  1'h0;            // Read
    iHADDR   <= 32'h8;            // Register address

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

    repeat (  1) @(posedge iClk);
    $display("OOOOO Read  0x%h from addr 0x%h !!! OOOOO", oHRDATA[31:0], addr[31:0]);
    
  end
  endtask




  /***********************************************
  // APB interface
  ***********************************************/
  initial
  begin
    iHSEL    <=  1'h0;
    iHTRANS  <=  2'h0;            // Idle
    iHWRITE  <=  1'h0;            // Don't care
    iHADDR   <= 32'hFFFFFFFF;     // Don't care
    iHWDATA  <= 32'h0;            // Don't care

    // Reg A write
    repeat (100) @(posedge iClk);
    ahb_write(32'h0, 32'h5A5A5A5A); 


    // Reg B write
    repeat (  0) @(posedge iClk);
    ahb_write(21'h4, 32'hA5A5A5A5); 


    // Reg C read
    repeat (  0) @(posedge iClk);
    ahb_read(32'h8);


    // Finish
    repeat (100) @(posedge iClk);
    $finish;
  end



  // Display read data
/**
  always @(posedge iClk)
  begin

    if (iPsel == 1'b1 && iPenable == 1'b1 && iPwrite == 1'b0 && iPaddr[15:0] == 16'h000C)
    begin
      $display("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
      $display("OOOOO       APB read data = %h       OOOOO", oPrdata[31:0]);
      $display("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
    end

  end
**/



  /***********************************************
  // VCD dump
  ***********************************************/
  initial
  begin
    $shm_open("/user/student/stu2/Internship_JH/Lab5/Testbench/Dump/Lab5_wTask.shm");
    $shm_probe("AC");
  end


endmodule
