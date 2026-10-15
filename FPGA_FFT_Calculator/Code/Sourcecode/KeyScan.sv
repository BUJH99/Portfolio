`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: KeyScan
// description: Scans a 4-by-5 keypad matrix and emits debounced key codes.
// [MODULE_INFO_END]
module KeyScan (
    input  logic       iRstn,
    input  logic       iClk,
    input  logic       iPulse1k,
    input  logic [4:0] iKeyIn,

    output logic [3:0] oKeyOut,
    output logic       oKeyValid,
    output logic [4:0] oKeyValue
);

    logic       ScanEn;
    logic [3:0] ScanCnt;
    logic [1:0] ScanCol;
    logic [4:0] DebounceCnt;
    logic [3:0] KeyOut;

    logic [4:0] KeyReadData;
    logic       KeyMulti;
    logic       KeyOn;
    logic       KeyValid;
    logic [4:0] KeyValue;

    assign oKeyOut   = KeyOut;
    assign oKeyValid = KeyValid;
    assign oKeyValue = KeyValue;

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            ScanEn <= 1'b0;
        end else begin
            if (iPulse1k) begin
                ScanEn <= 1'b1;
            end else if (ScanEn && (ScanCol == 2'd3) && (ScanCnt == 4'd9)) begin
                ScanEn <= 1'b0;
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            ScanCnt <= '0;
            ScanCol <= '0;
        end else if (ScanEn) begin
            if (ScanCnt == 4'd9) begin
                ScanCnt <= '0;
                if (ScanCol == 2'd3) begin
                    ScanCol <= '0;
                end else begin
                    ScanCol <= ScanCol + 2'd1;
                end
            end else begin
                ScanCnt <= ScanCnt + 4'd1;
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            KeyOut <= 4'b1111;
        end else if (ScanEn) begin
            if ((ScanCnt == 4'd1) && (ScanCol == 2'd0)) begin
                KeyOut <= 4'b1110;
            end else if ((ScanCnt == 4'd9) && (ScanCol == 2'd0)) begin
                KeyOut <= 4'b1111;
            end else if ((ScanCnt == 4'd1) && (ScanCol == 2'd1)) begin
                KeyOut <= 4'b1101;
            end else if ((ScanCnt == 4'd9) && (ScanCol == 2'd1)) begin
                KeyOut <= 4'b1111;
            end else if ((ScanCnt == 4'd1) && (ScanCol == 2'd2)) begin
                KeyOut <= 4'b1011;
            end else if ((ScanCnt == 4'd9) && (ScanCol == 2'd2)) begin
                KeyOut <= 4'b1111;
            end else if ((ScanCnt == 4'd1) && (ScanCol == 2'd3)) begin
                KeyOut <= 4'b0111;
            end else if ((ScanCnt == 4'd9) && (ScanCol == 2'd3)) begin
                KeyOut <= 4'b1111;
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            KeyReadData <= '0;
        end else begin
            if (KeyMulti) begin
                KeyReadData <= 5'd31;
            end else if ((ScanCnt == 4'd6) && !KeyOn) begin
                if (iKeyIn == 5'b11111) begin
                    KeyReadData <= 5'd0;
                end else if (iKeyIn == 5'b11110) begin
                    KeyReadData <= 5'd1 + ({3'd0, ScanCol} * 5'd5);
                end else if (iKeyIn == 5'b11101) begin
                    KeyReadData <= 5'd2 + ({3'd0, ScanCol} * 5'd5);
                end else if (iKeyIn == 5'b11011) begin
                    KeyReadData <= 5'd3 + ({3'd0, ScanCol} * 5'd5);
                end else if (iKeyIn == 5'b10111) begin
                    KeyReadData <= 5'd4 + ({3'd0, ScanCol} * 5'd5);
                end else if (iKeyIn == 5'b01111) begin
                    KeyReadData <= 5'd5 + ({3'd0, ScanCol} * 5'd5);
                end
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            KeyOn <= 1'b0;
        end else begin
            if ((ScanCol == 2'd0) && (ScanCnt == 4'd1)) begin
                KeyOn <= 1'b0;
            end else if (KeyMulti) begin
                KeyOn <= 1'b1;
            end else if ((ScanCnt == 4'd6) && !KeyOn) begin
                if (~(&iKeyIn)) begin
                    KeyOn <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            KeyMulti <= 1'b0;
        end else begin
            if ((ScanCol == 2'd0) && (ScanCnt == 4'd1)) begin
                KeyMulti <= 1'b0;
            end else if ((ScanCnt == 4'd6) && !KeyOn) begin
                if ((iKeyIn != 5'b11111) &&
                    (iKeyIn != 5'b11110) &&
                    (iKeyIn != 5'b11101) &&
                    (iKeyIn != 5'b11011) &&
                    (iKeyIn != 5'b10111) &&
                    (iKeyIn != 5'b01111)) begin
                    KeyMulti <= 1'b1;
                end
            end else if ((ScanCnt == 4'd6) && KeyOn) begin
                if (~(&iKeyIn)) begin
                    KeyMulti <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            KeyValue <= '0;
        end else begin
            if ((ScanCol == 2'd3) && (ScanCnt == 4'd8) && KeyOn && !KeyMulti) begin
                KeyValue <= KeyReadData;
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            DebounceCnt <= '0;
            KeyValid    <= 1'b0;
        end else begin
            if (KeyMulti) begin
                DebounceCnt <= '0;
            end else if ((ScanCol == 2'd3) && (ScanCnt == 4'd8) && !KeyOn) begin
                DebounceCnt <= '0;
            end else if ((ScanCol == 2'd3) && (ScanCnt == 4'd8) && KeyOn) begin
                if (KeyValue != KeyReadData) begin
                    DebounceCnt <= '0;
                end else begin
                    if (DebounceCnt == 5'd24) begin
                        KeyValid    <= 1'b1;
                        DebounceCnt <= DebounceCnt + 5'd1;
                    end else if (DebounceCnt != 5'd25) begin
                        DebounceCnt <= DebounceCnt + 5'd1;
                    end
                end
            end else begin
                KeyValid <= 1'b0;
            end
        end
    end

endmodule
