`timescale 1ns / 1ps

//============================================================
// Behavioral memory models for TOP simulation
//============================================================
module InputMemory_RGB888 (
    input  wire        clka,
    input  wire        ena,
    input  wire        wea,
    input  wire [16:0] addra,
    input  wire [23:0] dina,
    input  wire        clkb,
    input  wire        enb,
    input  wire [16:0] addrb,
    output reg  [23:0] doutb
);

    reg [23:0] mem [0:131071];

    always @(posedge clka) begin
        if (ena && wea) begin
            mem[addra] <= dina;
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            doutb <= mem[addrb];
        end
    end

endmodule

module OutputMemory_RGB565 (
    input  wire        clka,
    input  wire        ena,
    input  wire        wea,
    input  wire [16:0] addra,
    input  wire [15:0] dina,
    input  wire        clkb,
    input  wire        enb,
    input  wire [16:0] addrb,
    output reg  [15:0] doutb
);

    reg [15:0] mem [0:131071];

    always @(posedge clka) begin
        if (ena && wea) begin
            mem[addra] <= dina;
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            doutb <= mem[addrb];
        end
    end

endmodule
