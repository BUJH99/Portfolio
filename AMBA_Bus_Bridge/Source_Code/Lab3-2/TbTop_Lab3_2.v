/*******************************************************************
* - Project          : 2025 summer internship
* - File name        : TbTop_Lab3_2.v
* - Description      : Testbench top for Lab3_2
* - Owner            : Inchul.song
* - Revision history : 1) 2024.12.27 : Initial release
*                      2) 2025.06.26 : add oPready
********************************************************************/

`timescale 1ns/10ps

module TbTop_Lab3_2;


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

  wire             oOutEnable;

  integer          i;



  /***********************************************
  // FthPrjTop.v  instantiation
  ***********************************************/
  Lab3_2_Top A_Lab3_2_Top (
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
  .oPready         (oPready),


  // Interrupt out to CPU
  .oOutEnable      (oOutEnable)
  );



  /***********************************************
  // Clock define
  ***********************************************/
  initial
  begin
    iClk    <= 1'b0;
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
    $display("--------------------------->");
    $display("**** Reset released !!! ****");
    iRsn <= 1'b1;
    $display("--------------------------->");
  end



  /***********************************************
  // APB write task
  ***********************************************/
  task apb_write (
    input  [15:0]  addr,     // Write address
    input  [31:0]  data      // Read data
  );
  begin

    iPsel    <= 1'b1;
    iPenable <= 1'b0;
    iPwrite  <= 1'b1;
    iPaddr   <= addr[15:0];
    iPwdata  <= data[31:0];


    @(posedge iClk);
    iPenable <= 1'b1;


    // Wait oPready
    wait (oPready);


    @(posedge iClk);
    $display("**** Write 0x%h at addr 0x%h !!! ****", data[31:0], addr[15:0]);
    iPsel    <= 1'b0;
    iPenable <= 1'b0;

  end
  endtask


    
  /***********************************************
  // APB read task
  ***********************************************/
  task apb_read (
    input  [15:0]  addr,     // Read address
    input  [31:0]  data      // Expected data
  );
  begin

    iPsel    <= 1'b1;
    iPenable <= 1'b0;
    iPwrite  <= 1'b0;
    iPaddr   <= addr[15:0];


    @(posedge iClk);
    iPenable <= 1'b1;


    // Wait oPready
    wait (oPready);


    @(posedge iClk);
    $display("**** Read  0x%h & expected 0x%h from addr 0x%h !!! ****", oPrdata[31:0], data[31:0], addr[15:0]);

    if (oPrdata[31:0] == data[31:0])
    begin
      $display ("     OOOO Read data Passed !!! OOOO");
    end
    else
    begin
      $display ("     XXXX Read data Failed !!! XXXX");
      $display ("     ---> Must debug this  !!! <---");
    end

    iPsel    <= 1'b0;
    iPenable <= 1'b0;

  end
  endtask




  /****************************************************
  // Intialization & function start !!!!!!!!!!!!!!!!!!!
  ****************************************************/
  initial
  begin

    iPsel    <=  1'h0;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h0;
    iPwdata  <= 32'h0;





    // InBuf.v (0x4000 ~) write
    repeat (100) @(posedge iClk);
    for (i=0 ; i<512 ; i=i+1)
    begin
      repeat (  5) @(posedge iClk);


      if (i<256) // 0~255
      begin
        apb_write(16'h4000+(4*i), i*32'h0101 + (255-i)*32'h01010000);
      end
      else       // 256~511
      begin
        apb_write(16'h4000+(4*i), (i-256)*32'h0101 + (511-i)*32'h01010000);
      end

    end





    // Packet size write (512Bytes : 0x200) & read
    repeat (100) @(posedge iClk);
    apb_write(16'h0004, 32'h200);
    
    repeat (100) @(posedge iClk);
    apb_read(16'h0004, 32'h200);



    // Function start
    repeat (  5) @(posedge iClk);
    apb_write(16'h0000, 32'h1);
    $display("------------------------------------------------->");
    $display("OOOOO Lab3_2 Project function is started !!! OOOOO");
    $display("------------------------------------------------->");
    $display("OOOOO           Waiting oOutEnable           OOOOO");
    $display("------------------------------------------------->");

  end





  /****************************************************
  // oOutEnable & data check !!!!!!!!!!!!!!!!!!!!!!!!!!
  ****************************************************/
  initial
  begin

    // oOutEnable wait
    @(posedge oOutEnable);
    $display("------------------------------------------------->");
    $display("OOOOO 1st oOutEnable occured !!! OOOOO");
    $display("------------------------------------------------->");

   



    // OutBuf.v (0x6000 ~) check
    for (i=0 ; i<512 ; i=i+1)
    begin
      repeat (100) @(posedge iClk);

      if (i<256) // 0~255
      begin
        apb_read(16'h6000+(4*i), i*32'h01010000 + (255-i)*32'h0101);
      end
      else       // 256~511
      begin
        apb_read(16'h6000+(4*i), (i-256)*32'h01010000 + (511-i)*32'h0101);
      end

    end





    // Finish
    repeat (100) @(posedge iClk);
    $display("-------------------------------------------------->");
    $display("OOOOO   Lab3_2 Simulation has been done   !!! OOOOO");
    $display("OOOOO Must check Lab3_2.log & Lab3_2.shm  !!! OOOOO");
    $display("-------------------------------------------------->");





    // Only test
    `ifdef testa
      $display("1234567890");
      $display("1234567890");
      $display("1234567890");
      $display("1234567890");
      $display("1234567890");
      $display("1234567890");
    `elsif testb
      $display("ABCDEFGHIJ");
      $display("ABCDEFGHIJ");
      $display("ABCDEFGHIJ");
      $display("ABCDEFGHIJ");
      $display("ABCDEFGHIJ");
      $display("ABCDEFGHIJ");
    `elsif testc
      `include "/user/student/inchul.song/Internship_2025_summer/Lab3_2/TestBench/Vector/IncludeFile.v"
    `else
    `endif






    $finish;

  end



  /***********************************************
  // VCD dump
  ***********************************************/
  initial
  begin
    $shm_open("/user/student/stu2/Internship_JH/Lab3_2/Testbench/Dump/Lab3_2.shm");
    $shm_probe("AC");
  end


endmodule
