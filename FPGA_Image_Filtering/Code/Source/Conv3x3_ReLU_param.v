// ============================================================================
// 모듈명 : Conv3x3_ReLU_param
// 기능   : 3x3 RGB 이미지 컨볼루션 및 ReLU 연산을 수행합니다.
//          - Sharpen 커널을 기본값으로 가집니다.
//          - 표준 VALID/READY 핸드셰이크 인터페이스를 사용합니다.
// 수정사항 :
//          - 전체 파이프라인과 클럭 동기화를 위해 Clock Enable(i_wEnClk) 로직 추가.
//          - 리셋 신호 이름을 iRst_n으로 통일.
// ============================================================================
module Conv3x3_ReLU_param #(
    parameter integer PIX_BITS = 24,   // RGB888
    parameter integer COEFFW   = 8,    // 계수 비트폭 (signed)
    parameter integer ACCW     = 24,   // 누산 비트폭 (signed, 여유 있게)
    // ===== 기본 커널: Sharpen [[0,-1,0],[-1,5,-1],[0,-1,0]] =====
    // sharpen
    parameter signed [COEFFW-1:0] Ks0 =  0,  parameter signed [COEFFW-1:0] Ks1 = -1,  parameter signed [COEFFW-1:0] Ks2 =  0,
    parameter signed [COEFFW-1:0] Ks3 = -1,  parameter signed [COEFFW-1:0] Ks4 =  5,  parameter signed [COEFFW-1:0] Ks5 = -1,
    parameter signed [COEFFW-1:0] Ks6 =  0,  parameter signed [COEFFW-1:0] Ks7 = -1,  parameter signed [COEFFW-1:0] Ks8 =  0,
    // edge enhance
    parameter signed [COEFFW-1:0] Ke0 = -1,  parameter signed [COEFFW-1:0] Ke1 = -1,  parameter signed [COEFFW-1:0] Ke2 = -1,
    parameter signed [COEFFW-1:0] Ke3 = -1,  parameter signed [COEFFW-1:0] Ke4 =  9,  parameter signed [COEFFW-1:0] Ke5 = -1,
    parameter signed [COEFFW-1:0] Ke6 = -1,  parameter signed [COEFFW-1:0] Ke7 = -1,  parameter signed [COEFFW-1:0] Ke8 = -1,
    // bypass
    parameter signed [COEFFW-1:0] Kb0 =  0,  parameter signed [COEFFW-1:0] Kb1 =  0,  parameter signed [COEFFW-1:0] Kb2 =  0,
    parameter signed [COEFFW-1:0] Kb3 =  0,  parameter signed [COEFFW-1:0] Kb4 =  1,  parameter signed [COEFFW-1:0] Kb5 =  0,
    parameter signed [COEFFW-1:0] Kb6 =  0,  parameter signed [COEFFW-1:0] Kb7 =  0,  parameter signed [COEFFW-1:0] Kb8 =  0,
    // emboss
    parameter signed [COEFFW-1:0] Kem0 = -2,  parameter signed [COEFFW-1:0] Kem1 = -1,  parameter signed [COEFFW-1:0] Kem2 =  0,
    parameter signed [COEFFW-1:0] Kem3 = -1,  parameter signed [COEFFW-1:0] Kem4 =  1,  parameter signed [COEFFW-1:0] Kem5 =  1,
    parameter signed [COEFFW-1:0] Kem6 =  0,  parameter signed [COEFFW-1:0] Kem7 =  1,  parameter signed [COEFFW-1:0] Kem8 =  2
)(
    input  wire                     iClk,
    input  wire                     iRst_n,     // System Reset (active-low)
	
	input  wire	[1:0]				mode,

    // Consumer Input Interface
    input  wire [PIX_BITS*9-1:0]    i_data,
    input  wire                     i_valid,
    output wire                     i_ready,
    // Producer Output Interface
    output reg  [PIX_BITS-1:0]      o_data,
    output reg                      o_valid,
    input  wire                     o_ready
);

    reg out_hold; // 출력 데이터가 내부 레지스터에 보관 중임을 나타내는 플래그
    assign i_ready = (~out_hold) | (out_hold & o_ready);

    // ----------------------------
    // i_data에서 9픽셀(R,G,B) 추출
    // ----------------------------
    // p00 (행0, 열0)
    wire [7:0] r0 = i_data[ 23: 16]; wire [7:0] g0 = i_data[ 15:  8]; wire [7:0] b0 = i_data[  7:  0];
    // p01 (행0, 열1)
    wire [7:0] r1 = i_data[ 47: 40]; wire [7:0] g1 = i_data[ 39: 32]; wire [7:0] b1 = i_data[ 31: 24];
    // p02 (행0, 열2)
    wire [7:0] r2 = i_data[ 71: 64]; wire [7:0] g2 = i_data[ 63: 56]; wire [7:0] b2 = i_data[ 55: 48];
    // p10 (행1, 열0)
    wire [7:0] r3 = i_data[ 95: 88]; wire [7:0] g3 = i_data[ 87: 80]; wire [7:0] b3 = i_data[ 79: 72];
    // p11 (행1, 열1)
    wire [7:0] r4 = i_data[119:112]; wire [7:0] g4 = i_data[111:104]; wire [7:0] b4 = i_data[103: 96];
    // p12 (행1, 열2)
    wire [7:0] r5 = i_data[143:136]; wire [7:0] g5 = i_data[135:128]; wire [7:0] b5 = i_data[127:120];
    // p20 (행2, 열0)
    wire [7:0] r6 = i_data[167:160]; wire [7:0] g6 = i_data[159:152]; wire [7:0] b6 = i_data[151:144];
    // p21 (행2, 열1)
    wire [7:0] r7 = i_data[191:184]; wire [7:0] g7 = i_data[183:176]; wire [7:0] b7 = i_data[175:168];
    // p22 (행2, 열2)
    wire [7:0] r8 = i_data[215:208]; wire [7:0] g8 = i_data[207:200]; wire [7:0] b8 = i_data[199:192];

    // ----------------------------
    // 보조 함수: 곱 결과(계수×픽셀)를 ACCW로 sign-extend
    // ----------------------------
    function signed [ACCW-1:0] mul_sext;
        input signed [COEFFW-1:0] k;
        input        [7:0]        p;
        reg   signed [COEFFW+9-1:0] prod;
        begin
            prod     = k * $signed({1'b0, p});
            mul_sext = {{(ACCW-(COEFFW+9)){prod[COEFFW+9-1]}}, prod};
        end
    endfunction

    // ----------------------------
    // 보조 함수: 3×3 컨볼루션 합 (가중합)
    // ----------------------------
    function signed [ACCW-1:0] conv3x3_sum;
        input [7:0] p0,p1,p2,p3,p4,p5,p6,p7,p8;
        input signed [COEFFW-1:0] k0,k1,k2,k3,k4,k5,k6,k7,k8;
        reg   signed [ACCW-1:0] s;
        begin
            s =  mul_sext(k0,p0) + mul_sext(k1,p1) + mul_sext(k2,p2)
               + mul_sext(k3,p3) + mul_sext(k4,p4) + mul_sext(k5,p5)
               + mul_sext(k6,p6) + mul_sext(k7,p7) + mul_sext(k8,p8);
            conv3x3_sum = s;
        end
    endfunction

    // ----------------------------
    // 보조 함수: ReLU 및 0~255 포화
    // ----------------------------
    function [7:0] relu_sat8_long;
        input signed [ACCW-1:0] x;
        begin
            if (x <= 0)                   relu_sat8_long = 8'd0;
            else if (x >= 255)            relu_sat8_long = 8'd255;
            else                          relu_sat8_long = x[7:0];
        end
    endfunction

    // ----------------------------
    // 출력 레지스터 & 핸드셰이크 로직
    // ----------------------------
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            o_data    <= {PIX_BITS{1'b0}};
            o_valid   <= 1'b0;
            out_hold  <= 1'b0;
        end else begin
                // 핸드셰이크 조건에 따른 내부 상태(out_hold) 업데이트
                if (i_valid && i_ready) begin
                    // 새로운 데이터가 들어오면, 출력 레지스터를 채움
                    out_hold <= 1'b1;
                end else if (out_hold && o_ready) begin
                    // 보관 중인 데이터가 하류로 전달되면, 출력 레지스터를 비움
                    out_hold <= 1'b0;
                end

                // 핸드셰이크 조건에 따른 출력 신호(o_valid) 업데이트
                if (i_valid && i_ready) begin
                    // 입력이 들어온 바로 그 사이클에 o_valid를 1로 설정 (Zero-latency forward)
                    o_valid <= 1'b1;
                end else if (out_hold && o_ready) begin
                    // 데이터가 전달되면 o_valid를 0으로 내림
                    o_valid <= 1'b0;
                end else begin
                    // 그 외의 경우, o_valid는 내부 상태(out_hold)를 따라감
                    o_valid <= out_hold;
                end
                
                // 입력이 수락되면 (i_valid & i_ready), 즉시 계산하여 o_data 레지스터에 저장
                if (i_valid && i_ready) begin
					case(mode)	
						2'b01: begin //sharpen
							// R 채널
							o_data[23:16] <= relu_sat8_long(
								conv3x3_sum(r0,r1,r2,r3,r4,r5,r6,r7,r8,
											Ks0,Ks1,Ks2,Ks3,Ks4,Ks5,Ks6,Ks7,Ks8)
							);
							// G 채널
							o_data[15: 8] <= relu_sat8_long(
								conv3x3_sum(g0,g1,g2,g3,g4,g5,g6,g7,g8,
											Ks0,Ks1,Ks2,Ks3,Ks4,Ks5,Ks6,Ks7,Ks8)
							);
							// B 채널
							o_data[ 7: 0] <= relu_sat8_long(
								conv3x3_sum(b0,b1,b2,b3,b4,b5,b6,b7,b8,
											Ks0,Ks1,Ks2,Ks3,Ks4,Ks5,Ks6,Ks7,Ks8)
							);
						end
						
						2'b10: begin //edge enhance
							// R 채널
							o_data[23:16] <= relu_sat8_long(
								conv3x3_sum(r0,r1,r2,r3,r4,r5,r6,r7,r8,
											Ke0,Ke1,Ke2,Ke3,Ke4,Ke5,Ke6,Ke7,Ke8)
							);
							// G 채널
							o_data[15: 8] <= relu_sat8_long(
								conv3x3_sum(g0,g1,g2,g3,g4,g5,g6,g7,g8,
											Ke0,Ke1,Ke2,Ke3,Ke4,Ke5,Ke6,Ke7,Ke8)
							);
							// B 채널
							o_data[ 7: 0] <= relu_sat8_long(
								conv3x3_sum(b0,b1,b2,b3,b4,b5,b6,b7,b8,
											Ke0,Ke1,Ke2,Ke3,Ke4,Ke5,Ke6,Ke7,Ke8)
							);
						end
						
						2'b11: begin //emboss
							// R 채널
							o_data[23:16] <= relu_sat8_long(
								conv3x3_sum(r0,r1,r2,r3,r4,r5,r6,r7,r8,
											Kem0,Kem1,Kem2,Kem3,Kem4,Kem5,Kem6,Kem7,Kem8)
							);
							// G 채널
							o_data[15: 8] <= relu_sat8_long(
								conv3x3_sum(g0,g1,g2,g3,g4,g5,g6,g7,g8,
											Kem0,Kem1,Kem2,Kem3,Kem4,Kem5,Kem6,Kem7,Kem8)
							);
							// B 채널
							o_data[ 7: 0] <= relu_sat8_long(
								conv3x3_sum(b0,b1,b2,b3,b4,b5,b6,b7,b8,
											Kem0,Kem1,Kem2,Kem3,Kem4,Kem5,Kem6,Kem7,Kem8)
							);
						end
						
						default: begin //bypass
							// R 채널
							o_data[23:16] <= relu_sat8_long(
								conv3x3_sum(r0,r1,r2,r3,r4,r5,r6,r7,r8,
											Kb0,Kb1,Kb2,Kb3,Kb4,Kb5,Kb6,Kb7,Kb8)
							);
							// G 채널
							o_data[15: 8] <= relu_sat8_long(
								conv3x3_sum(g0,g1,g2,g3,g4,g5,g6,g7,g8,
											Kb0,Kb1,Kb2,Kb3,Kb4,Kb5,Kb6,Kb7,Kb8)
							);
							// B 채널
							o_data[ 7: 0] <= relu_sat8_long(
								conv3x3_sum(b0,b1,b2,b3,b4,b5,b6,b7,b8,
											Kb0,Kb1,Kb2,Kb3,Kb4,Kb5,Kb6,Kb7,Kb8)
							);
						end
					endcase
                end
            
        end
    end

endmodule