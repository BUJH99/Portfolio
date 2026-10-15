/*
[MODULE_INFO_START]
Name: Conv3x3ReluParam
Role: Apply selectable 3x3 RGB convolution kernels with ReLU saturation.
Summary:
  - Accepts 3x3 RGB888 windows through a valid/ready interface.
  - Produces filtered RGB888 pixels for bypass, sharpen, edge, and emboss modes.
[MODULE_INFO_END]
*/

// ============================================================================
// 모듈명 : Conv3x3ReluParam
// 기능   : 3x3 RGB 이미지 컨볼루션 및 ReLU 연산을 수행합니다.
//          - Sharpen 커널을 기본값으로 가집니다.
//          - 표준 VALID/READY 핸드셰이크 인터페이스를 사용합니다.
// 수정사항 :
//          - 전체 파이프라인과 클럭 동기화를 위해 Clock Enable(iClkEn) 로직 추가.
//          - 리셋 신호 이름을 iRstn으로 통일.
// ============================================================================
module Conv3x3ReluParam #(
    parameter integer P_PIX_BITS = 24,   // RGB888
    parameter integer P_COEFF_WIDTH   = 8,    // 계수 비트폭 (signed)
    parameter integer P_ACC_WIDTH     = 24,   // 누산 비트폭 (signed, 여유 있게)
    // ===== 기본 커널: Sharpen [[0,-1,0],[-1,5,-1],[0,-1,0]] =====
    // sharpen
    parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K0 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K1 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K2 =  0,
    parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K3 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K4 =  5,  parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K5 = -1,
    parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K6 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K7 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_SHARPEN_K8 =  0,
    // edge enhance
    parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K0 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K1 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K2 = -1,
    parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K3 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K4 =  9,  parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K5 = -1,
    parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K6 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K7 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EDGE_K8 = -1,
    // bypass
    parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K0 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K1 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K2 =  0,
    parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K3 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K4 =  1,  parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K5 =  0,
    parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K6 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K7 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_BYPASS_K8 =  0,
    // emboss
    parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K0 = -2,  parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K1 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K2 =  0,
    parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K3 = -1,  parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K4 =  1,  parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K5 =  1,
    parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K6 =  0,  parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K7 =  1,  parameter signed [P_COEFF_WIDTH-1:0] P_EMBOSS_K8 =  2
)(
    input logic                     iClk,
    input logic                     iRstn,     // System Reset (active-low)
	
	input logic	[1:0]				iFilterMode,

    // Consumer Input Interface
    input logic [P_PIX_BITS*9-1:0]    iData,
    input logic                     iValid,
    output logic                     oReady,
    // Producer Output Interface
    output logic  [P_PIX_BITS-1:0]      oData,
    output logic                      oValid,
    input logic                     iReady
);

    logic OutHold; // 출력 데이터가 내부 레지스터에 보관 중임을 나타내는 플래그
    assign oReady = (~OutHold) | (OutHold & iReady);

    // ----------------------------
    // iData에서 9픽셀(R,G,B) 추출
    // ----------------------------
    // p00..p22 (row-major)
    logic [7:0] PixelR0, PixelG0, PixelB0;
    logic [7:0] PixelR1, PixelG1, PixelB1;
    logic [7:0] PixelR2, PixelG2, PixelB2;
    logic [7:0] PixelR3, PixelG3, PixelB3;
    logic [7:0] PixelR4, PixelG4, PixelB4;
    logic [7:0] PixelR5, PixelG5, PixelB5;
    logic [7:0] PixelR6, PixelG6, PixelB6;
    logic [7:0] PixelR7, PixelG7, PixelB7;
    logic [7:0] PixelR8, PixelG8, PixelB8;

    assign PixelR0 = iData[ 23: 16]; assign PixelG0 = iData[ 15:  8]; assign PixelB0 = iData[  7:  0];
    assign PixelR1 = iData[ 47: 40]; assign PixelG1 = iData[ 39: 32]; assign PixelB1 = iData[ 31: 24];
    assign PixelR2 = iData[ 71: 64]; assign PixelG2 = iData[ 63: 56]; assign PixelB2 = iData[ 55: 48];
    assign PixelR3 = iData[ 95: 88]; assign PixelG3 = iData[ 87: 80]; assign PixelB3 = iData[ 79: 72];
    assign PixelR4 = iData[119:112]; assign PixelG4 = iData[111:104]; assign PixelB4 = iData[103: 96];
    assign PixelR5 = iData[143:136]; assign PixelG5 = iData[135:128]; assign PixelB5 = iData[127:120];
    assign PixelR6 = iData[167:160]; assign PixelG6 = iData[159:152]; assign PixelB6 = iData[151:144];
    assign PixelR7 = iData[191:184]; assign PixelG7 = iData[183:176]; assign PixelB7 = iData[175:168];
    assign PixelR8 = iData[215:208]; assign PixelG8 = iData[207:200]; assign PixelB8 = iData[199:192];

    // ----------------------------
    // 보조 함수: 곱 결과(계수×픽셀)를 P_ACC_WIDTH로 sign-extend
    // ----------------------------
    function signed [P_ACC_WIDTH-1:0] MulSext;
        input logic signed [P_COEFF_WIDTH-1:0] k;
        input        logic [7:0]        p;
        logic   signed [P_COEFF_WIDTH+9-1:0] prod;
        begin
            prod     = k * $signed({1'b0, p});
            MulSext = {{(P_ACC_WIDTH-(P_COEFF_WIDTH+9)){prod[P_COEFF_WIDTH+9-1]}}, prod};
        end
    endfunction

    // ----------------------------
    // 보조 함수: 3×3 컨볼루션 합 (가중합)
    // ----------------------------
    function signed [P_ACC_WIDTH-1:0] Conv3x3Sum;
        input logic [7:0] p0,p1,p2,p3,p4,p5,p6,p7,p8;
        input logic signed [P_COEFF_WIDTH-1:0] k0,k1,k2,k3,k4,k5,k6,k7,k8;
        logic   signed [P_ACC_WIDTH-1:0] s;
        begin
            s =  MulSext(k0,p0) + MulSext(k1,p1) + MulSext(k2,p2)
               + MulSext(k3,p3) + MulSext(k4,p4) + MulSext(k5,p5)
               + MulSext(k6,p6) + MulSext(k7,p7) + MulSext(k8,p8);
            Conv3x3Sum = s;
        end
    endfunction

    // ----------------------------
    // 보조 함수: ReLU 및 0~255 포화
    // ----------------------------
    function [7:0] ReluSat8Long;
        input logic signed [P_ACC_WIDTH-1:0] x;
        begin
            if (x <= 0)                   ReluSat8Long = 8'd0;
            else if (x >= 255)            ReluSat8Long = 8'd255;
            else                          ReluSat8Long = x[7:0];
        end
    endfunction

    // ----------------------------
    // 출력 레지스터 & 핸드셰이크 로직
    // ----------------------------
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oData    <= {P_PIX_BITS{1'b0}};
            oValid   <= 1'b0;
            OutHold  <= 1'b0;
        end else begin
                // 핸드셰이크 조건에 따른 내부 상태(OutHold) 업데이트
                if (iValid && oReady) begin
                    // 새로운 데이터가 들어오면, 출력 레지스터를 채움
                    OutHold <= 1'b1;
                end else if (OutHold && iReady) begin
                    // 보관 중인 데이터가 하류로 전달되면, 출력 레지스터를 비움
                    OutHold <= 1'b0;
                end

                // 핸드셰이크 조건에 따른 출력 신호(oValid) 업데이트
                if (iValid && oReady) begin
                    // 입력이 들어온 바로 그 사이클에 oValid를 1로 설정 (Zero-latency forward)
                    oValid <= 1'b1;
                end else if (OutHold && iReady) begin
                    // 데이터가 전달되면 oValid를 0으로 내림
                    oValid <= 1'b0;
                end else begin
                    // 그 외의 경우, oValid는 내부 상태(OutHold)를 따라감
                    oValid <= OutHold;
                end
                
                // 입력이 수락되면 (iValid & oReady), 즉시 계산하여 oData 레지스터에 저장
                if (iValid && oReady) begin
					case(iFilterMode)	
						2'b01: begin //sharpen
							// R 채널
							oData[23:16] <= ReluSat8Long(
								Conv3x3Sum(PixelR0,PixelR1,PixelR2,PixelR3,PixelR4,PixelR5,PixelR6,PixelR7,PixelR8,
											P_SHARPEN_K0,P_SHARPEN_K1,P_SHARPEN_K2,P_SHARPEN_K3,P_SHARPEN_K4,P_SHARPEN_K5,P_SHARPEN_K6,P_SHARPEN_K7,P_SHARPEN_K8)
							);
							// G 채널
							oData[15: 8] <= ReluSat8Long(
								Conv3x3Sum(PixelG0,PixelG1,PixelG2,PixelG3,PixelG4,PixelG5,PixelG6,PixelG7,PixelG8,
											P_SHARPEN_K0,P_SHARPEN_K1,P_SHARPEN_K2,P_SHARPEN_K3,P_SHARPEN_K4,P_SHARPEN_K5,P_SHARPEN_K6,P_SHARPEN_K7,P_SHARPEN_K8)
							);
							// B 채널
							oData[ 7: 0] <= ReluSat8Long(
								Conv3x3Sum(PixelB0,PixelB1,PixelB2,PixelB3,PixelB4,PixelB5,PixelB6,PixelB7,PixelB8,
											P_SHARPEN_K0,P_SHARPEN_K1,P_SHARPEN_K2,P_SHARPEN_K3,P_SHARPEN_K4,P_SHARPEN_K5,P_SHARPEN_K6,P_SHARPEN_K7,P_SHARPEN_K8)
							);
						end
						
						2'b10: begin //edge enhance
							// R 채널
							oData[23:16] <= ReluSat8Long(
								Conv3x3Sum(PixelR0,PixelR1,PixelR2,PixelR3,PixelR4,PixelR5,PixelR6,PixelR7,PixelR8,
											P_EDGE_K0,P_EDGE_K1,P_EDGE_K2,P_EDGE_K3,P_EDGE_K4,P_EDGE_K5,P_EDGE_K6,P_EDGE_K7,P_EDGE_K8)
							);
							// G 채널
							oData[15: 8] <= ReluSat8Long(
								Conv3x3Sum(PixelG0,PixelG1,PixelG2,PixelG3,PixelG4,PixelG5,PixelG6,PixelG7,PixelG8,
											P_EDGE_K0,P_EDGE_K1,P_EDGE_K2,P_EDGE_K3,P_EDGE_K4,P_EDGE_K5,P_EDGE_K6,P_EDGE_K7,P_EDGE_K8)
							);
							// B 채널
							oData[ 7: 0] <= ReluSat8Long(
								Conv3x3Sum(PixelB0,PixelB1,PixelB2,PixelB3,PixelB4,PixelB5,PixelB6,PixelB7,PixelB8,
											P_EDGE_K0,P_EDGE_K1,P_EDGE_K2,P_EDGE_K3,P_EDGE_K4,P_EDGE_K5,P_EDGE_K6,P_EDGE_K7,P_EDGE_K8)
							);
						end
						
						2'b11: begin //emboss
							// R 채널
							oData[23:16] <= ReluSat8Long(
								Conv3x3Sum(PixelR0,PixelR1,PixelR2,PixelR3,PixelR4,PixelR5,PixelR6,PixelR7,PixelR8,
											P_EMBOSS_K0,P_EMBOSS_K1,P_EMBOSS_K2,P_EMBOSS_K3,P_EMBOSS_K4,P_EMBOSS_K5,P_EMBOSS_K6,P_EMBOSS_K7,P_EMBOSS_K8)
							);
							// G 채널
							oData[15: 8] <= ReluSat8Long(
								Conv3x3Sum(PixelG0,PixelG1,PixelG2,PixelG3,PixelG4,PixelG5,PixelG6,PixelG7,PixelG8,
											P_EMBOSS_K0,P_EMBOSS_K1,P_EMBOSS_K2,P_EMBOSS_K3,P_EMBOSS_K4,P_EMBOSS_K5,P_EMBOSS_K6,P_EMBOSS_K7,P_EMBOSS_K8)
							);
							// B 채널
							oData[ 7: 0] <= ReluSat8Long(
								Conv3x3Sum(PixelB0,PixelB1,PixelB2,PixelB3,PixelB4,PixelB5,PixelB6,PixelB7,PixelB8,
											P_EMBOSS_K0,P_EMBOSS_K1,P_EMBOSS_K2,P_EMBOSS_K3,P_EMBOSS_K4,P_EMBOSS_K5,P_EMBOSS_K6,P_EMBOSS_K7,P_EMBOSS_K8)
							);
						end
						
						default: begin //bypass
							// R 채널
							oData[23:16] <= ReluSat8Long(
								Conv3x3Sum(PixelR0,PixelR1,PixelR2,PixelR3,PixelR4,PixelR5,PixelR6,PixelR7,PixelR8,
											P_BYPASS_K0,P_BYPASS_K1,P_BYPASS_K2,P_BYPASS_K3,P_BYPASS_K4,P_BYPASS_K5,P_BYPASS_K6,P_BYPASS_K7,P_BYPASS_K8)
							);
							// G 채널
							oData[15: 8] <= ReluSat8Long(
								Conv3x3Sum(PixelG0,PixelG1,PixelG2,PixelG3,PixelG4,PixelG5,PixelG6,PixelG7,PixelG8,
											P_BYPASS_K0,P_BYPASS_K1,P_BYPASS_K2,P_BYPASS_K3,P_BYPASS_K4,P_BYPASS_K5,P_BYPASS_K6,P_BYPASS_K7,P_BYPASS_K8)
							);
							// B 채널
							oData[ 7: 0] <= ReluSat8Long(
								Conv3x3Sum(PixelB0,PixelB1,PixelB2,PixelB3,PixelB4,PixelB5,PixelB6,PixelB7,PixelB8,
											P_BYPASS_K0,P_BYPASS_K1,P_BYPASS_K2,P_BYPASS_K3,P_BYPASS_K4,P_BYPASS_K5,P_BYPASS_K6,P_BYPASS_K7,P_BYPASS_K8)
							);
						end
					endcase
                end
            
        end
    end

endmodule
