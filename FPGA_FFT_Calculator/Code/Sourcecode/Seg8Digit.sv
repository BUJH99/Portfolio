`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: Seg8Digit
// description: Drives an 8-digit seven-segment display with decimal-point support.
// [MODULE_INFO_END]
module Seg8Digit (
    input  logic        iRstn,
    input  logic        iClk,
    input  logic        iPulse1k,
    input  logic [31:0] iDisplayBcd,
    input  logic [7:0]  iDotMask,

    output logic [7:0]  oSegData,
    output logic [7:0]  oSegCom
);

    logic [2:0] ComCnt;
    logic [7:0] SegCom;
    logic [7:0] SegData;

    logic [3:0] BcdSel;
    logic [6:0] SegBits;
    logic [7:0] SegComNext;
    logic       Dot;

    assign Dot      = iDotMask[ComCnt];
    assign oSegCom  = SegCom;
    assign oSegData = SegData;

    always_comb begin
        unique case (ComCnt)
            3'd0:    BcdSel = iDisplayBcd[31:28];
            3'd1:    BcdSel = iDisplayBcd[27:24];
            3'd2:    BcdSel = iDisplayBcd[23:20];
            3'd3:    BcdSel = iDisplayBcd[19:16];
            3'd4:    BcdSel = iDisplayBcd[15:12];
            3'd5:    BcdSel = iDisplayBcd[11:8];
            3'd6:    BcdSel = iDisplayBcd[7:4];
            default: BcdSel = iDisplayBcd[3:0];
        endcase
    end

    always_comb begin
        unique case (BcdSel)
            4'h0:    SegBits = 7'h3f;
            4'h1:    SegBits = 7'h06;
            4'h2:    SegBits = 7'h5b;
            4'h3:    SegBits = 7'h4f;
            4'h4:    SegBits = 7'h66;
            4'h5:    SegBits = 7'h6d;
            4'h6:    SegBits = 7'h7d;
            4'h7:    SegBits = 7'h07;
            4'h8:    SegBits = 7'h7f;
            4'h9:    SegBits = 7'h6f;
            4'hA:    SegBits = 7'h40;
            default: SegBits = 7'h00;
        endcase
    end

    always_comb begin
        unique case (ComCnt)
            3'd0:    SegComNext = 8'b1000_0000;
            3'd1:    SegComNext = 8'b0100_0000;
            3'd2:    SegComNext = 8'b0010_0000;
            3'd3:    SegComNext = 8'b0001_0000;
            3'd4:    SegComNext = 8'b0000_1000;
            3'd5:    SegComNext = 8'b0000_0100;
            3'd6:    SegComNext = 8'b0000_0010;
            default: SegComNext = 8'b0000_0001;
        endcase
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            ComCnt <= '0;
        end else if (iPulse1k) begin
            if (ComCnt == 3'd7) begin
                ComCnt <= '0;
            end else begin
                ComCnt <= ComCnt + 3'd1;
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            SegCom  <= '0;
            SegData <= '0;
        end else if (iPulse1k) begin
            SegCom  <= SegComNext;
            SegData <= {Dot, SegBits};
        end
    end

endmodule
