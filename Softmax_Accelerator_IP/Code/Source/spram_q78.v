// ============================================================================
// Q7.8 싱글포트 RAM (동기식): write 0/1-포트, read 1-사이클 지연
// DEPTH ≤ 2^ADDR_W
// ============================================================================
module spram_q78 #(
    parameter integer DEPTH  = 1024,
    parameter integer ADDR_W = 10
)(
    input  wire                 clk,
    input  wire                 we,
    input  wire [ADDR_W-1:0]    waddr,
    input  wire signed [15:0]   din,
    input  wire                 re,
    input  wire [ADDR_W-1:0]    raddr,
    output reg  signed [15:0]   dout
);
    // (* ram_style = "block" *)  // 필요 시 BRAM 유도 힌트
    reg signed [15:0] mem [0:DEPTH-1];

    // write
    always @(posedge clk) begin
        if (we) mem[waddr] <= din;
    end

    // read (1-cycle latency)
    reg [ADDR_W-1:0] raddr_q;
    always @(posedge clk) begin
        if (re) raddr_q <= raddr;
        dout <= mem[raddr_q];
    end
endmodule
