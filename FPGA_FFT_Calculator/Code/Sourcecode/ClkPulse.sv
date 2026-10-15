`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: ClkPulse
// description: Generates a one-cycle 1 kHz enable pulse from the input clock.
// [MODULE_INFO_END]
module ClkPulse (
    input  logic iClk,
    input  logic iRstn,
    output logic oPulse1k
);

    localparam logic [13:0] LP_CNT_1K_MAX = 14'd9999;

    logic [13:0] Cnt1k;
    logic        Pulse1k;

    assign oPulse1k = Pulse1k;

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            Cnt1k   <= '0;
            Pulse1k <= 1'b0;
        end else begin
            if (Cnt1k == LP_CNT_1K_MAX) begin
                Cnt1k   <= '0;
                Pulse1k <= 1'b1;
            end else if (Cnt1k == '0) begin
                Cnt1k   <= Cnt1k + 14'd1;
                Pulse1k <= 1'b0;
            end else begin
                Cnt1k <= Cnt1k + 14'd1;
            end
        end
    end

endmodule
