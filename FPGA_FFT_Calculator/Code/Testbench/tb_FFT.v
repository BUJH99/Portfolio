`timescale 1ns / 1ps


module tb_fft8_top;

reg clk;
reg rstn;
reg [4:0] key_push;

wire [3:0] key_out;
wire [4:0] key_in;

wire [7:0] o_seg_com;
wire [7:0] o_seg_d;
wire [7:0] o_index;
wire o_FFT;
wire o_re_im;

initial begin
    #0;  rstn=0;
    #10; rstn=1;
end
initial begin
    #0; clk=0;
    forever begin
        #50 clk = ~clk;
    end
end

initial begin
    #0; key_push=5'd0; 
    key_push = 0;   #100_000_000;
    
    // 1,2,3,4,5,6,7,8,9 입력
    key_push = 7;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 8;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 9;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;   #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 12;   #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;   #33_000_000;
    key_push = 0;   #33_000_000; 
    key_push = 13;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 14;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;   #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 17;   #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 18;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    
    //Ent
    key_push = 4;   #33_000_000; 
    key_push = 0;   #33_000_000;
    
    //FFT Re 값 결과 확인
    key_push = 15;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 15;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    
    //FFT Im 값 결과 확인
    key_push = 5;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    key_push = 10;  #33_000_000; 
    key_push = 0;   #33_000_000; 
    
    #50_000; $finish;
end

//instance block
key_pad U_KEY_MATRIX (
    .rst            (rstn),
    .clk            (clk),
    .key_v          (key_push),
    .key_column_in  (key_out),
    .key_row_out    (key_in)
);

fft8_keypad_top U_FFT_TOP(
    .i_rstn      (rstn),
    .i_clk       (clk),
    .i_key_in    (key_in),
    .o_key_out   (key_out),
    .o_seg_com   (o_seg_com),
    .o_seg_d     (o_seg_d),
    .o_index     (o_index),
    .o_FFT       (o_FFT),
    .o_re_im     (o_re_im)
);
    

endmodule