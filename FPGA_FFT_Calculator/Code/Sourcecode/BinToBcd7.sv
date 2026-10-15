`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: BinToBcd7
// description: Converts a 24-bit unsigned binary value to seven packed BCD digits.
// [MODULE_INFO_END]
module BinToBcd7 (
    input  logic        iClk,
    input  logic        iRstn,
    input  logic        iStart,
    input  logic [23:0] iValue,

    output logic        oBusy,
    output logic        oDone,
    output logic [27:0] oBcd7
);

    typedef enum logic [0:0] {
        IDLE,
        SHIFT
    } state_e;

    state_e State;

    logic [23:0] Bin;
    logic [27:0] Bcd;
    logic [4:0]  BitCnt;

    logic [27:0] Bcd_d;
    logic [23:0] Bin_d;
    logic [3:0]  Digit;

    integer idxDigit;

    always_comb begin
        Bcd_d = Bcd;
        Bin_d = Bin;
        Digit = '0;

        for (idxDigit = 0; idxDigit < 7; idxDigit = idxDigit + 1) begin
            Digit = Bcd_d[idxDigit*4 +: 4];
            if (Digit >= 4'd5) begin
                Digit = Digit + 4'd3;
            end
            Bcd_d[idxDigit*4 +: 4] = Digit;
        end

        {Bcd_d, Bin_d} = {Bcd_d, Bin_d} << 1;
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            State  <= IDLE;
            oBusy  <= 1'b0;
            oDone  <= 1'b0;
            oBcd7  <= '0;
            Bin    <= '0;
            Bcd    <= '0;
            BitCnt <= '0;
        end else begin
            oDone <= 1'b0;

            unique case (State)
                IDLE: begin
                    oBusy <= 1'b0;
                    if (iStart) begin
                        Bin    <= iValue;
                        Bcd    <= '0;
                        BitCnt <= 5'd24;
                        oBusy  <= 1'b1;
                        State  <= SHIFT;
                    end
                end

                SHIFT: begin
                    Bcd <= Bcd_d;
                    Bin <= Bin_d;

                    if (BitCnt == 5'd1) begin
                        oBcd7 <= Bcd_d;
                        oBusy <= 1'b0;
                        oDone <= 1'b1;
                        State <= IDLE;
                    end else begin
                        BitCnt <= BitCnt - 5'd1;
                    end
                end

                default: begin
                    State <= IDLE;
                end
            endcase
        end
    end

endmodule
