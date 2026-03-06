// ============================================================================
// FP32 → Q7.8 변환기 (합성 가능, 조합, Verilog-2001 호환)
//  v = (-1)^s * (1.frac) * 2^(exp-127)
//  q = round(v * 2^8).sat_16
// ============================================================================
module fp32_to_q78(
    input  wire [31:0]        fp32,
    output reg  signed [15:0] q78
);
    wire        s = fp32[31];
    wire [7:0]  e = fp32[30:23];
    wire [22:0] m = fp32[22:0];

    wire [23:0] one_m = {1'b1, m}; // 1.frac → 24b 정수

    // Verilog-2001: 블록 맨 앞에 선언
    integer shift;                // (e - 142)
    integer r;                    // -shift
    reg signed [31:0] scaled;     // 스케일 결과(라운딩 후)

    always @* begin
        if (e == 8'hFF) begin
            // Inf/NaN → 포화
            q78 = s ? -16'sd32768 : 16'sd32767;

        end else if (e == 8'h00) begin
            // 서브노말/0 → 0 (필요시 서브노말 근사 추가 가능)
            q78 = 16'sd0;

        end else begin
            // 142 = 127(bias) + 8(Q7.8) + 23(정규화 자리)
            // SV 캐스팅 대신 $signed({1'b0,e})로 안전하게 부호 연산
            shift = $signed({1'b0, e}) - 9'sd142;

            if (shift >= 0) begin
                // 좌시프트 (오버가드)
                if (shift > 31)
                    scaled = 32'sh7FFFFFFF;
                else
                    // <<< 대신 << 로도 동일(좌시프트는 산술/논리 동일)
                    scaled = $signed({1'b0, one_m}) << shift;

            end else begin
                // 우시프트 & 라운드-투-니어레스트
                r = -shift;  // r > 0
                if (r >= 32) begin
                    scaled = 32'sd0;
                end else if (r == 0) begin
                    // r==0이면 쉬프트 없음
                    scaled = $signed({1'b0, one_m});
                end else begin
                    // +0.5 LSB 추가 후 우시프트
                    // (r-1) 음수 방지: 위에서 r>0 보장
                    scaled = ( $signed({1'b0, one_m}) + (32'sd1 << (r-1)) ) >>> r;
                end
            end

            // 부호 적용
            if (s) scaled = -scaled;

            // 16비트 포화
            if (scaled >  32'sd32767)      q78 = 16'sd32767;
            else if (scaled < -32'sd32768) q78 = -16'sd32768;
            else                           q78 = scaled[15:0];
        end
    end
endmodule
