`timescale 1ns/10ps

module TbTop_prj;

  /***********************************************
  // wire & register
  ***********************************************/
  reg          iClk;
  reg          iRsn;

  reg          iHSEL;
  reg [1:0]    iHTRANS;
  reg          iHWRITE;
  reg [31:0]   iHADDR;
  reg [31:0]   iHWDATA;
  
  
  reg [31:0]   r_expected_data;
  
  wire [31:0]  oHRDATA;
  wire [1:0]   oHRESP;
  wire         oHREADYout;
  wire         iHREADYin;
  
  // Result check
  integer      error_count;

  // iHREADYin function in AHB bus decoder & Mux
  reg          rHSEL_Dly;

  always @(posedge iClk)
  begin
    if (!iRsn)
      rHSEL_Dly <= 1'b0;
    else if (iHREADYin == 1'b1) //
      rHSEL_Dly <= iHSEL;
  end

  assign iHREADYin = (rHSEL_Dly == 1'b1) ? oHREADYout : 1'b1;

  /***********************************************
  // Project_Top.v instantiation
  ***********************************************/
  Project_Top DUT (
    .iClk       (iClk),
    .iRsn       (iRsn),
    .iHSEL      (iHSEL),
    .iHTRANS    (iHTRANS),
    .iHWRITE    (iHWRITE),
    .iHADDR     (iHADDR),  
    .iHREADYin  (iHREADYin),
    .iHWDATA    (iHWDATA),
    .oHRDATA    (oHRDATA),
    .oHREADYout (oHREADYout),
    .oHRESP     (oHRESP)
  );

  /***********************************************
  // Clock define
  ***********************************************/
  initial begin
    iClk <= 1'b0;
  end

  always begin
    #5 iClk <= ~iClk; // 100MHz clock
  end

  /***********************************************
  // Sync. & active low reset define
  ***********************************************/
  initial begin
    iRsn <= 1'b1;
    @(posedge iClk);
    iRsn <= 1'b0;
    repeat (2) @(posedge iClk); 
    $display("TIME: %0tns -> OOOOO Reset released !!! OOOOO", $time);
    iRsn <= 1'b1;
  end

  /***********************************************
  // AHB Master Tasks
  ***********************************************/

  // AHB Write Task
  task ahb_write(input [31:0] addr, input [31:0] data);
  begin
    @(posedge iClk);
    $display("TIME: %0tns -> AHB Write to Addr: 0x%h, Data: 0x%h", $time, addr, data);
    // Address Phase
    iHSEL     <= 1'b1;
    iHTRANS   <= 2'b10; // NONSEQ
    iHWRITE   <= 1'b1;  // Write
    iHADDR    <= addr;

	@(posedge iClk);
	// Data phase
    iHSEL   <= 1'h0;
    iHTRANS <= 2'h0;    // Don't care
    iHWRITE <= 1'h0;    // Don't care
    iHWDATA <= data;        
    
    // Write complete wait (HREADYout = 1)
    wait (oHREADYout == 1'b1);
    
    // Wirte Complete
    @(posedge iClk);
    iHSEL     <= 1'b0;
    iHTRANS   <= 2'b00; // IDLE
    iHWDATA   <= 32'h0;
    $display("TIME: %0tns -> Write transaction finished.", $time);
  end
  endtask

  // AHB Read Task
  task ahb_read(input [31:0] addr, input [31:0] expected_data);
  begin
  
    @(posedge iClk);
    $display("TIME: %0tns -> AHB Read from Addr: 0x%h", $time, addr);
	
    // Address Phase
    iHSEL     <= 1'b1;
    iHTRANS   <= 2'b10; // NONSEQ
    iHWRITE   <= 1'b0;  // Read
    iHADDR    <= addr;

    @(posedge iClk); // HREADYout = 0
    
	iHSEL   <= 1'b0;
    iHTRANS <= 2'b00;
	
	@(posedge iClk);
	
	r_expected_data <= expected_data;
	
    while (oHREADYout == 1'b0)
	begin
      @(posedge iClk);
    end
    // On this exact cycle, HREADYout is 1 and oHRDATA is valid.
    $display("TIME: %0tns -> Read data available. Read: 0x%h, Expected: 0x%h", $time, oHRDATA, expected_data);
    // Check the read data
	
    if (oHRDATA === expected_data)
	begin
      $display(">>>>> [SUCCESS] Read data matches!");
    end 
	else
	begin
      $error(">>>>> [ERROR] Read data mismatch! Got: 0x%h, Expected: 0x%h", oHRDATA, expected_data);
      error_count = error_count + 1;
    end
    
    // End of transfer, go to IDLE state
    @(posedge iClk);
    iHSEL     <= 1'b0;
    iHTRANS   <= 2'b00; // IDLE
    $display("TIME: %0tns -> Read transaction finished.", $time);
  end
  endtask

  /***********************************************
  // Main Test Scenario
  ***********************************************/
  initial begin
    error_count = 0;
    
    // Initialize AHB signals
    iHSEL     <= 1'b0;
    iHTRANS   <= 2'b00; // IDLE
    iHWRITE   <= 1'b0;
    iHADDR    <= 32'h0;
    iHWDATA   <= 32'h0;
	

    // Wait for reset to be deasserted
	wait (iRsn == 1'b0);
    wait (iRsn == 1'b1);
	@(posedge iClk);
    
    // ---timing diagram ---
    
    // 1. Write 0xDEADBEEF to 0x70008000
    ahb_write(32'h70008000, 32'hDEADBEEF);
    
    repeat(2) @(posedge iClk);

    // 2. Write 0x12345678 to 0x7000803C
    ahb_write(32'h7000803C, 32'h12345678);

    repeat(5) @(posedge iClk);

    // 3. Read from 0x70008000 and check data
    ahb_read(32'h70008000, 32'hDEADBEEF);
    
    repeat(2) @(posedge iClk);

    // 4. Read from 0x7000803C and check data
    ahb_read(32'h7000803C, 32'h12345678);

    repeat(10) @(posedge iClk);

    // --- Final Result Display ---
    $display("======================================================");
    if (error_count == 0) begin
      $display(">>>>> ALL TESTS PASSED <<<<<");
    end else begin
      $display(">>>>> TEST FAILED with %0d errors <<<<<", error_count);
    end
    $display("======================================================");

    #100;
    $finish;
  end

  /***********************************************
  // VCD dump
  ***********************************************/
  initial 
 begin
    $shm_open("/user/student/stu2/Internship_JH/pro1/Testbench/Dump/pro1.shm");
    $shm_probe("AC");
  end

endmodule