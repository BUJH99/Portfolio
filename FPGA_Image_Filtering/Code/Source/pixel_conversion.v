/********************************************************************************
*
* Module: pixel_conversion
*
* Description: RGB888 to RGB565 변환 및 주소 생성을 수행.
*
*
********************************************************************************/
module pixel_conversion (
    //==================================================================
    // Port Declarations
    //==================================================================
    // --- System Signals ---
    input wire          iClk,           // 시스템 클럭 (e.g., 100MHz)
    input wire          iRst_n,         // 시스템 리셋 (active-low)

    // --- Handshake Interface with Convolution Module (Consumer) ---
    output wire         i_ready,        // 본 모듈이 데이터를 받을 준비가 되었음을 알림
    input wire          i_valid,        // Convolution 모듈로부터 유효한 데이터가 왔음을 알림
    input wire [23:0]   i_data,         // 24비트 RGB888 픽셀 데이터

    // --- Output Interface to OutBuf BRAM ---
    output wire         oMemEn,         // Memory Port Enable (to BRAM 'ena')
    output wire         oMemWe,         // Memory Write Enable (to BRAM 'wea')
    output wire [16:0]  oMemAddr,       // Memory Address (to BRAM 'addra')
    output wire [15:0]  oMemWd          // Memory Write Data (to BRAM 'dina')
);

    //==================================================================
    // Parameters & Internal Signals
    //==================================================================
    parameter IMAGE_WIDTH = 480;
    parameter IMAGE_HEIGHT = 272;

    reg [$clog2(IMAGE_WIDTH)-1:0]   x_cnt_reg;
    reg [$clog2(IMAGE_HEIGHT)-1:0]  y_cnt_reg;

    // 데이터 전송(Transaction)은 valid와 ready 신호가 모두 High일 때만 발생
    wire transfer_valid = i_valid && i_ready;

    //==================================================================
    // Sequential Logic: Coordinate Counter
    //==================================================================
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            x_cnt_reg <= 0;
            y_cnt_reg <= 0;
        end else begin
            if (transfer_valid) begin
                if (x_cnt_reg == IMAGE_WIDTH - 1 && y_cnt_reg == IMAGE_HEIGHT - 1) begin
                    x_cnt_reg <= 0;
                    y_cnt_reg <= 0;
                end else if (x_cnt_reg == IMAGE_WIDTH - 1) begin
                    x_cnt_reg <= 0;
                    y_cnt_reg <= y_cnt_reg + 1;
                end else begin
                    x_cnt_reg <= x_cnt_reg + 1;
                end
            end
        end
    end
    
    //==================================================================
    // Combinational Logic: Output Generation
    //==================================================================
    // --- Handshake & Control Signal ---
    // i_ready는 항상 1로 설정. 이 모듈은 항상 데이터를 즉시 처리할 수 있음.
    assign i_ready = 1'b1;

    // BRAM 제어 신호 생성
    // 데이터 전송이 유효할 때 BRAM 포트를 활성화하고 쓰기 동작을 수행.
    // 현재는 쓰기 동작만 있으므로 oMemEn과 oMemWe는 동일하게 동작.
    assign oMemEn = transfer_valid;
    assign oMemWe = transfer_valid;
    
    // --- Address & Data Conversion ---
    // 현재 (x,y) 좌표를 OutBuf의 1차원 메모리 주소로 변환
    assign oMemAddr = (y_cnt_reg * IMAGE_WIDTH) + x_cnt_reg;
    
    // 24비트 RGB888 데이터를 16비트 RGB565로 변환.
    // i_data: {R[23:16], G[15:8], B[7:0]}
    // oMemWd: {R[15:11], G[10:5], B[4:0]} (16 bits)
    assign oMemWd = { i_data[23:19], i_data[15:10], i_data[7:3] };

endmodule