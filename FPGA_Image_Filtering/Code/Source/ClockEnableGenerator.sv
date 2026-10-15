/*
[MODULE_INFO_START]
Name: ClockEnableGenerator
Role: Generate a periodic clock enable pulse for LCD timing.
Summary:
  - Counts the 100 MHz system clock to create a 6.25 MHz enable pulse.
  - Resets the counter with active-low reset.
[MODULE_INFO_END]
*/

/********************************************************************************
*
* Module: ClockEnableGenerator
*
* Description:
*   100MHz의 시스템 클럭(iClk)을 입력받아 6.25MHz 주파수에 해당하는
*   클럭 인에이블(oClkEn) 신호를 생성합니다.
*
********************************************************************************/
module ClockEnableGenerator (
    //==================================================================
    // Port Declarations
    //==================================================================
    input logic         iClk,       // 시스템 클럭 입력 (100MHz)
    input logic         iRstn,       // 시스템 리셋 (active-low)
    output logic         oClkEn    // 클럭 인에이블 출력 (6.25MHz 펄스)
);

    //==================================================================
    // Internal Counter Register
    //==================================================================
    // 16분주를 위해 0부터 15까지 카운트하는 4비트 레지스터 (2^4 = 16)
    logic [3:0] Cnt;

    //==================================================================
    // Sequential Logic: Counter
    //==================================================================
    // 시스템 클럭의 상승 엣지마다 카운터를 1씩 증가시킵니다.
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            // 시스템 리셋 시, 카운터를 0으로 초기화합니다.
            Cnt <= 4'b0;
        end else begin
            // 카운터가 최대값(15)에 도달하면 0으로 롤오버(Roll-over)합니다.
            if (Cnt == 4'd15) begin
                Cnt <= 4'b0;
            end else begin
                // 그 외의 경우, 카운터를 1 증가시킵니다.
                Cnt <= Cnt + 1'b1;
            end
        end
    end

    //==================================================================
    // Combinational Logic: Output Generation
    //==================================================================
    // 카운터 값이 최대값(15)일 때만 출력 신호를 1로 설정합니다.
    // 이는 정확히 16 클럭마다 한 번씩 발생하는, 1 클럭 폭의 인에이블 펄스를 생성합니다.
    assign oClkEn = (Cnt == 4'd15);

endmodule