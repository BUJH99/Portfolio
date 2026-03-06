`timescale 1ns / 1ps // 시뮬레이션 단위/정밀도 1ns/1ps로 고정하여 타이밍 해석 일관성 확보(테스트벤치와 동일 축 사용)

/* =====================================================================================================================
 * File Name    : exp_block1.v
 * Project      : Softmax layer Accelerator Based on FPGA
 * Author       : 숭상화
 * Creation Date: 2025-08-30
 * Description  : Q7.8 입력 x에 대해 e^x를 Q0.16로 근사 계산하는 LUT·순차 곱셈형 블록(AXI-Stream 스타일 핸드셰이크 준수)
 * Design Notes : - 입력은 downscale 후 음수 영역이 주류이므로 |x|의 2진 전개 비트마다 e^(-2^k) LUT를 누적 곱하여 언더플로를 억제
 *                - 단발 처리 구조(oReady=Idle)로 백프레셔 전파가 명확; 처리 시간은 비트 깊이(12스텝)와 싱크 iReady에 종속
 *                - 누적기는 Q0.32 정밀도로 곱셈 오차 누적을 완화하고, 최종 Q0.16로 트렁케이션(필요 시 라운딩 TODO)
 * Dependencies : 내부 LUT 상수만 사용(외부 모듈 없음). 고정소수점 해석은 시스템 전역 Q-포맷 합의에 의존
 * =====================================================================================================================*/

/**
 * @brief   Q7.8 입력에 대한 e^x를 LUT 기반 순차 곱셈으로 산출(Q0.16), AXIS 유사 ready/valid 제어 제공
 * @details |x| = Σ b_k·2^k (k∈[-8..+3])로 전개 후, e^x = Π_k e^(sign·2^k) 근사를 사용.
 *          본 구현은 downscale 단계 특성상 x≤0이 지배적이라는 가정 하에 e^(-2^k) LUT를 사용하고, |x|의 해당 비트가 1일 때마다 곱해 감.
 *          입력 래치/결과 배출은 ready/valid로 동기화되며, 계산 페이즈 동안 iReady를 고려해 다운스트림 혼잡을 전파(NOTE 참조).
 * @param   iClk     상승엣지 동기 클록 // 시스템 동기화 기준(메타/CDC 회피), 타이밍 분석의 기준 도메인
 * @param   iRsn     비동기 Low-Active 리셋 // 보드 리셋 규격과 일치시키기 위해 Low-Active 채택, 전역 초기화 경로 단순화
 * @param   iValid   입력 유효 플래그 // 소스가 데이터(iData,iLast)를 제시했음을 알리는 레벨, oReady와 AND 시 단일 샘플 수락
 * @param   oReady   입력 수락 가능 플래그 // Idle일 때만 1로 하여 단발 처리 보장(내부 버퍼 없이 상태기계 단순화 목적)
 * @param   iLast    입력 스트림 경계 표시 // 벡터/프레임 경계 전달을 위해 래치 후 완료 시점에 oLast로 재생성
 * @param   iData    Q7.8 부호 입력(16b) // 7비트 정수+8비트 소수: downscale(Xi-Xmax) 범위를 무손실 커버하기 위한 폭
 * @param   oValid   출력 유효 플래그 // Done 상태에서만 1로 하여 결과 타이밍 명확화(파이프라인 해저드 제거 목적)
 * @param   iReady   하류 수신 가능 플래그 // 계산 스텝을 하류 혼잡에 맞춰 게이팅하여 시스템 전반의 백프레셔 일관성 유지
 * @param   oLast    출력 스트림 경계 표시 // 입력 iLast를 래치해 결과 배출 타이밍에 동기화, 벡터 경계 보존
 * @param   oData    Q0.16 출력(16b) // 최종 Q0.32의 상위 16b만 배출: 하드웨어 간단화/지연 최소화(라운딩은 TODO)
 */

module exp_Block2 ( // e^x 근사 계산 블록의 탑 정의(포트는 AXIS 유사 프로토콜로 구성)
    // --- 시스템 신호 ---
    input  wire         iClk,    // 클록 도메인 명시: 단일 도메인 가정으로 CDC 이슈 제거
    input  wire         iRsn,    // Low-Active 비동기 리셋: 전원 투입 직후 안전한 초기 상태 확보

    // --- 입력 인터페이스 (AXI-Stream Slave 스타일) ---
    input  wire         iValid,  // 소스 유효 표식: oReady와 동시 1일 때만 샘플 캡처하여 중복 수락 방지
    output wire         oReady,  // Idle에서만 1: 내부 단일샷 처리 철학으로 리소스/컨트롤 단순화
    input  wire         iLast,   // 스트림 경계: 벡터 처리 후 oLast 동기화를 위해 래치
    input  wire signed [15:0] iData, // Q7.8(부호) 입력 폭 선정: Softmax 전처리 범위(-128..+127.996)와 해상도(2^-8) 타깃

    // --- 출력 인터페이스 (AXI-Stream Master 스타일) ---
    output wire         oValid,  // Done 상태에서만 1: 다운스트림에 명확한 수명 주기 제공
    input  wire         iReady,  // 다운스트림 수용능력: 계산 스텝 게이팅으로 시스템 백프레셔 연동
    output wire         oLast,   // 경계 재생성: 입력 iLast와 동일 의미를 결과 타이밍에 정렬
    output wire [15:0]  oData    // Q0.16(무부호) 출력: 확률/정규화 연산 체인과 직접 호환
); // 모듈 헤더 종료: 이후 내부 상태/데이터패스 정의 시작

/**********************************************************************
 * Stage 1: 데이터 경로 신호 선언
 * - Q0.32 누적 곱으로 정확도 유지, 최종 Q0.16 배출로 I/F 단순화
 **********************************************************************/

    // 조합 와이어
    wire [15:0] wAbsN;
    
    reg [15:0] data1_1_n;               // |x|: e^(-|x|) 곱셈 경로 사용을 위한 비부호 변환(알고리즘 단순화 목적)
    reg [15:0] data1_2_n;               
   reg [15:0] data1_3_n;
   wire [15:0] data2_1_n;
   wire [31:0] data2_2_n;
   wire [31:0] data3_n;
   
   reg [15:0] data1_1;               
    reg [15:0] data1_2;               
   reg [15:0] data1_3;
   reg [15:0] data2_1;
   reg [15:0] data2_2;
   reg [15:0] data3;
   
   reg  data1_valid;               
    reg  data1_last;               
   reg  data2_valid;
   reg  data2_last;
   reg  data3_valid;
   reg  data3_last;
   
                                         

    // 입력값이 음수일 경우 2의 보수를 취하여 절대값을 계산
    assign wAbsN = (iData[15]) ? -iData : iData;


    // 상태 업데이트(순차): 비동기 Low 리셋, 엣지 트리거
    always @(posedge iClk or negedge iRsn) begin // FSM 상태 래치: 타이밍 경계 명확화
        if (!iRsn)   begin                           // 전역 초기화 시 안전 상태 강제
            data1_1 <= 16'h0000;               // |x|: e^(-|x|) 곱셈 경로 사용을 위한 비부호 변환(알고리즘 단순화 목적)
         data1_2 <= 16'h0000;               
         data1_3 <= 16'h0000;
         data2_1 <= 16'h0000;
         data2_2 <= 16'h0000;
         data3 <= 16'h0000;                // 초기 상태: 입력 수락 가능
         
         data1_valid <= 1'b0;               
         data1_last <= 1'b0;               
         data2_valid <= 1'b0;
         data2_last <= 1'b0;
         data3_valid <= 1'b0;
         data3_last <= 1'b0;
         
        end else begin                                    // 정상 동작 경로
         
         if (~data3_valid || oValid) begin
             if(iReady) begin
                data3 <= data3_n[31:16];
                data3_valid <= data2_valid;
                data3_last <= data2_last;
             end else begin
                 data3 <= data3_n[31:16];
                data3_valid <= 1'b0;
                data3_last <= 1'b0;
             end
         
             if(iReady|| ~data2_valid) begin
                data2_1 <= data2_1_n;
                data2_2 <= data2_2_n[31:16];
                data2_valid <= data1_valid;
                data2_last <= data1_last;
             end
         
             if((iReady || ~data2_valid || ~data1_valid)) begin
                data1_1 <= (wAbsN[14:12] == 3'b000) ? data1_1_n : 16'h0000;
                    data1_2 <= data1_2_n;
                data1_3 <= data1_3_n;
                data1_valid <= iValid;
                data1_last <= iLast;
             end   
          end      
      end
    end // 상태 레지스터 블록 종료


   always @* begin
      case (wAbsN[11:8])
         4'b1111: data1_1_n = 16'h0000;
         
         4'b1110: data1_1_n = 16'h0000;
         4'b1101: data1_1_n = 16'h0000;
         4'b1011: data1_1_n = 16'h0000;
         4'b0111: data1_1_n = 16'h003B;
         
         4'b1100: data1_1_n = 16'h0000;
         4'b1010: data1_1_n = 16'h0002;
         4'b1001: data1_1_n = 16'h0008;
         4'b0110: data1_1_n = 16'h00A2;
         4'b0101: data1_1_n = 16'h01B9;
         4'b0011: data1_1_n = 16'h0CBE;
         
         4'b1000: data1_1_n = 16'h0016;
         4'b0100: data1_1_n = 16'h04B0;
         4'b0010: data1_1_n = 16'h22A5;
         4'b0001: data1_1_n = 16'h5E2D;
         
         4'b0000: data1_1_n = 16'hFFFF;
         default: data1_1_n = 16'hFFFF;
      endcase
   end
   
   always @* begin
      case (wAbsN[7:4])
         4'b1111: data1_2_n = 16'h643F;
         
         4'b1110: data1_2_n = 16'h6AB7;
         4'b1101: data1_2_n = 16'h7199;
         4'b1011: data1_2_n = 16'h80B9;
         4'b0111: data1_2_n = 16'hA547;
      
         4'b1100: data1_2_n = 16'h78ED;
         4'b1010: data1_2_n = 16'h8907;
         4'b1001: data1_2_n = 16'h91DD;
         4'b0110: data1_2_n = 16'hAFF1;
         4'b0101: data1_2_n = 16'hBB4A;
         4'b0011: data1_2_n = 16'hD43A;
         
         4'b1000: data1_2_n = 16'h9B46;
         4'b0100: data1_2_n = 16'hC75F;
         4'b0010: data1_2_n = 16'hE1EB;
         4'b0001: data1_2_n = 16'hF07D;
         
         4'b0000: data1_2_n = 16'hFFFF;
         default: data1_2_n = 16'hFFFF;
      endcase
   end
   
   
   always @* begin
      case (wAbsN[3:0])
         4'b1111: data1_3_n = 16'hF16D;
      
         4'b1110: data1_3_n = 16'hF260;
         4'b1101: data1_3_n = 16'hF352;
         4'b1011: data1_3_n = 16'hF53A;
         4'b0111: data1_3_n = 16'hF916;
         
         4'b1100: data1_3_n = 16'hF447;
         4'b1010: data1_3_n = 16'hF631;
         4'b1001: data1_3_n = 16'hF727;
         4'b0110: data1_3_n = 16'hFA11;
         4'b0101: data1_3_n = 16'hFB0B;
         4'b0011: data1_3_n = 16'hFD03;
         
         4'b1000: data1_3_n = 16'hF820;
         4'b0100: data1_3_n = 16'hFC08;
         4'b0010: data1_3_n = 16'hFE02;
         4'b0001: data1_3_n = 16'hFF00;
         
         4'b0000: data1_3_n = 16'hFFFF;
         default: data1_3_n = 16'hFFFF;
      endcase
   end

   assign data2_2_n = data1_2*data1_3;
   
   assign data2_1_n = data1_1;
   
   assign data3_n = data2_1*data2_2;
   
   assign oData = data3;
   
   assign oValid = data3_valid && iReady;
   
   assign oLast = data3_last;
   
   assign oReady = ~data1_valid;

/**********************************************************************
 * Stage 4: 출력 매핑
 * - Q0.32 → Q0.16 절단, Done에서만 유효 신호/경계 배출
 **********************************************************************/
// NOTE: 검증 포인트
// - LUT 상수 테이블은 고정소수점 레퍼런스 모델과 일치해야 함(오차 예산 문서화 필수)
// - iReady 게이팅으로 처리 지연이 변동될 수 있으므로 상위 시스템은 지연 허용 범위를 고려할 것
// - 입력이 +범위(양수 x)가 유의미하게 존재할 경우 e^(+|x|) 경로 보강 또는 범위 제한 필요(FIXME 후보)

endmodule // 모듈 정의 종료: exp_Block1
