`timescale 1ns/1ps // 1ns 단위 해상도로 시뮬레이션해 타겟 클록(수십 MHz급) 타이밍 여유와 이벤트 정밀도를 균형화하기 위함

/* =====================================================================================================================
 * File Name    : SUB_BLOCK.v
 * Project      : Softmax layer Accelerator Based on FPGA
 * Author       : 숭상화
 * Creation Date: 2025-08-30
 * Description  : Downscale 결과(Xi−Xmax; Q7.8)를 버퍼에 보존한 뒤, Ln(∑exp) 경로 출력과 빼기(Xi−Xmax−lnSumExp)를 수행하는 서브블록
 * Design Notes : Softmax의 하드웨어 친화식 f(Xi)=exp(Xi−Xmax−ln(∑exp(Xj−Xmax))) 구현을 위한 버퍼링·카운트·FSMD 결합 구조 채택  :contentReference[oaicite:0]{index=0}
 *               Downscale가 Ln보다 먼저 완료되므로 버퍼 필수(데이터 정합)  :contentReference[oaicite:1]{index=1}
 *               Ln 블록은 exp/adder 결과의 지수·가수 분해(ICISLog)로 ln(2)*exp + ln(1.mant) 근사 사용  :contentReference[oaicite:2]{index=2}
 * Dependencies : counter.v(가변 길이 카운트), Buffer.v 혹은 buffer_sync(동기식 듀얼포트 버퍼), FSMD_sub.v(제어·감산·포화)
 * =====================================================================================================================*/

/**
 * @brief Xi−Xmax(Downscale) 스트림을 버퍼링하고, Ln(∑exp) 경로와 동기해 Xi−Xmax−lnSumExp를 순차 산출
 * @details 두 경로의 도착 시차를 버퍼로 흡수하고(out-of-order 방지), FSMD가 요청할 때마다 대응 샘플을 읽어 감산을 확정
 *          카운터1은 쓰기 주소(Downscale valid 기반), 카운터2는 처리 진행(outc 기반)으로 벡터 경계·순서를 보장
 *          결과는 16b 고정소수(Q7.8)로 출력되며 마지막 샘플에서 last 펄스를 표식
 * @param clk             동기 클록(상승엣지)로 모든 상태·카운터·버퍼 액세스를 일괄 동기화
 * @param rst_n           비동기 Low 리셋으로 파이프 초기 상태를 빠르게 강제(초기 쓰기/읽기 주소 확립)
 * @param downscale_data_i[15:0] Downscale 출력 Xi−Xmax(Q7.8) 입력(감산의 데이터1 원천)
 * @param downscale_data_valid_i Downscale 데이터 유효 표시(버퍼 저장 트리거)로 연속 주소 배치 보장
 * @param downscale_last_i       Downscale 벡터 끝 표식으로 전체 길이 추정·검증에 활용 가능
 * @param in_data_i[15:0]        Ln(∑exp) 결과(Q7.8 동치 스케일)로 감산의 데이터2(트리거 역할 포함)
 * @param in_data_valid_i        Ln 경로 데이터 유효(FSMD가 감산 싸이클 진입 신호로 사용)
 * @param ready                  하류 백프레셔 허용 신호(FSMD 진행 허용/보류 판정에 반영)
 * @param data_o[15:0]           감산 결과(Q7.8)로 Exp2 전단 입력이자 정규화된 지수입력에 해당  :contentReference[oaicite:3]{index=3}
 * @param data_valid_o           결과 유효(파이프라인 경계 간 타이밍 계약 유지)
 * @param last                   벡터 종료 표식(후속 Exp2/AXIS TLAST 등과 정렬)
 */

 /**********************************************************************
 * Stage 0: 톱-랩퍼 개요
 * - Downscale 경로는 먼저 완주하므로 저장, Ln 경로 도착 시 FSMD가 요청-응답으로 쌍 매칭  :contentReference[oaicite:4]{index=4}
 **********************************************************************/

module Sub_block #(
    parameter integer CNT_MAX    = 8, // 벡터 최대 길이(처리 반복 수)를 하드 제한해 주소폭·자원 고정을 용이화
    parameter integer ADDR_WIDTH = $clog2(CNT_MAX) // 버퍼 주소폭을 벡터 길이 로그로 설정해 과대폭 낭비 없이 전 범위 인덱싱
)(
    input  wire         clk, // 단일 클록 도메인에서 버퍼/카운터/FSMD의 동작 일관성 확보
    input  wire         rst_n, // 비동기 Low 리셋으로 전 경로 상태를 결정적 초기화(첫 트랜잭션 안정화)

    // Downscale 쪽 입력: 먼저 끝나는 경로를 보존해야 감산 시점에 데이터 정합이 가능
    input  wire [15:0]  downscale_data_i, // Xi−Xmax(Q7.8)로 부호 있는 16b 고정소수 입력(Exp1 범위 제한 근거)  :contentReference[oaicite:5]{index=5}
    input  wire         downscale_data_valid_i, // 유효 시에만 저장해 쓰기 주소와 데이터의 1:1 매핑 보장
    input  wire         downscale_last_i, // 벡터 경계 식별로 길이 추정·진행 종료 판단 일관성 확보

    // Ln 쪽 입력: 늦게 도착하므로 이 신호가 FSMD의 감산 트리거 역할을 수행
    input  wire [15:0]  in_data_i, // ln(∑exp)(Q7.8 동치)로 동일 스케일에서 직접 감산 가능하도록 설계  :contentReference[oaicite:6]{index=6}
    input  wire         in_data_valid_i, // 유효 시점에 FSMD가 data1_req를 내고 짝 데이터를 읽도록 유도
    
    input  wire         ready, // 하위 블록 수용능력 반영으로 불필요한 결과 축적·오버런 방지

    // 결과: Xi−Xmax−lnSumExp를 Q7.8로 산출해 Exp2에 투입(확률값 계산 전단)  :contentReference[oaicite:7]{index=7}
    output wire [15:0]  data_o, // 포화 옵션으로 Q7.8 범위를 유지해 후단 지수 근사 정확도 확보
    output wire         data_valid_o, // 결과 시점 명시로 다운스트림 파이프 동기 유지
    output wire         last // 입력 벡터 경계와 동일한 지점에서 종료 신호 전달해 AXIS TLAST 정합 보장
);

    // -------------------------------
    // 내부 배선: FSMD 요청/진행·버퍼 데이터 유효·카운터 주소를 결합해 데이터 일관성 유지
    // -------------------------------
    wire                      buf_data_valid; // 버퍼가 제공하는 data1 준비 상태로 FSMD의 감산 안전 조건
    wire [15:0]               buf_data_o; // 버퍼에서 읽힌 Xi−Xmax(Q7.8)로 감산의 피감수

    wire                      fsmd_data1_req; // FSMD가 data1을 요구하는 펄스/레벨로 읽기 사이클 타이밍 결정
    wire                      fsmd_outc; // 한 샘플 처리 완료 펄스로 진행 카운터 증가의 기준

    wire [ADDR_WIDTH-1:0]     cnt1_out; // 쓰기 주소를 연속 증가시켜 입력 순서를 재현
    wire [ADDR_WIDTH-1:0]     cnt2_out; // 읽기 주소=진행 인덱스로 FSMD 처리 순서와 동기화

    /**********************************************************************
     * Stage 1: Counter1 — BUFFER write 주소 관리
     * - downscale_data_valid_i마다 증가해 입력 순서 보존(읽기 시 동일 인덱스로 짝 매칭)
     **********************************************************************/
    counter #(
        .WIDTH(ADDR_WIDTH), // 주소폭을 벡터 길이에 상응하도록 축소해 LUT/FF 자원 절약
        .CNT_MAX (CNT_MAX) // 과주기 증가 방지를 위해 상한을 명시해 경계 안정성 확보
    ) counter1 (
        .clk (clk), // 단일 도메인 동기화로 글리치 없이 결정적 증가
        .rst_n (rst_n), // 리셋 시 주소 0으로 복귀해 첫 샘플부터 연속 배치
        .inc (downscale_data_valid_i), // 유효 샘플에만 저장·주소 증가해 공백 인덱스 방지
        .out (cnt1_out) // 현재 쓰기 주소 노출로 다른 블록(예: FSMD 길이 참조)과 공유
    );

    /**********************************************************************
     * Stage 2: Counter2 — FSMD 진행 인덱스
     * - fsmd_outc마다 증가해 처리된 샘플 수를 표식(읽기 주소와 동일하게 사용)
     **********************************************************************/
    counter #(
        .WIDTH(ADDR_WIDTH), // 동일 폭으로 읽기/쓰기 주소 공간을 일치시켜 인덱스 충돌 방지
        .CNT_MAX (CNT_MAX) // 처리 최대치 고정으로 범위 외 접근 억제
    ) counter2 (
        .clk (clk), // 감산 완료 타이밍에 맞춰 동기 증가
        .rst_n (rst_n), // 리셋 시 첫 읽기 인덱스를 0으로 초기화
        .inc (fsmd_outc), // 결과 확정 시점에만 증가해 중복 읽기 방지
        .out (cnt2_out) // 현재 처리 인덱스를 공개해 버퍼 읽기 주소로 재사용
    );

    /**********************************************************************
     * Stage 3: BUFFER — Downscale 결과 보존 및 임의접근 읽기
     * - 쓰기: valid 기반 연속 배치, 읽기: FSMD 요청 타이밍에 인덱스 지정
     * - Downscale 선조기 완료를 흡수해 Ln 경로와 시점 정합 보장  :contentReference[oaicite:8]{index=8}
     **********************************************************************/
    buffer_sync #(
        .DATA_WIDTH(16), // Q7.8 고정소수 16b 전폭을 보존해 정밀도 손실 없이 전달
        .ADDR_WIDTH(ADDR_WIDTH) // 벡터 길이에 상응하는 최소 주소폭으로 메모리 절약
    ) u_buffer (
        .clk      (clk), // 단일 클록에서 R/W 동기화로 읽기-쓰기 경쟁 완화
        .rst_n    (rst_n), // 리셋 시 내부 포인터/유효 플래그 초기화

        // write
        .data_i   (downscale_data_i), // Xi−Xmax를 원본 스케일 그대로 저장해 후속 감산 오차 최소화
        .save_en  (downscale_data_valid_i), // 유효 시에만 기록해 쓰기 홀 방지
        .addr_i   (cnt1_out), // 입력 순서대로 주소 배치해 읽기 시 동일 인덱스와 자연 매칭

        // read
        .load_en  (fsmd_data1_req), // FSMD 요청 시점에만 읽어 불필요한 액세스 억제
        .addr_o   (cnt2_out), // 진행 인덱스를 읽기 주소로 사용해 결과 순서를 보장

        // outputs to FSMD (as data1 stream)
        .data_valid (buf_data_valid), // 읽기 데이터 준비 완료를 알려 감산 타이밍을 안정화
        .data_o     (buf_data_o) // 감산 피감수(Xi−Xmax)를 제공해 즉시 연산 가능
    );

    /**********************************************************************
     * Stage 4: FSMD(Subtractor) — Xi−Xmax−lnSumExp 계산 제어
     * - data2(Ln) 도착을 트리거로 data1 버퍼 읽기→감산→진행 카운트 갱신까지 원사이클 정책 확립
     * - lnSumExp는 ICISLog 기반 Ln 블록 산출값으로 Q7.8 스케일 정합을 유지  :contentReference[oaicite:9]{index=9}
     **********************************************************************/
    fsmd_subtractor #(
        .SATURATE(1), // 포화 사용으로 Q7.8 동적범위 외 값이 후단 지수 근사 왜곡을 유발하지 않도록 차단
        .count_width(ADDR_WIDTH) // 진행 카운트 폭을 주소폭과 일치시켜 오버플로/언더플로 위험 제거
    ) u_fsmd (
        .clk        (clk), // 제어·연산을 동일 클록에 귀속해 상태 전이 결정성 확보
        .rst_n      (rst_n), // 리셋 시 FSM 초기 상태로 복귀해 첫 트랜잭션부터 정합 보장

        // data2 (Ln)
        .data2_en   (in_data_valid_i), // Ln 유효를 연산 트리거로 사용해 시점 불일치 해소
        .data2_i    (in_data_i), // ln(∑exp) 값으로 데이터2(감산 감수)를 제공

        // data1 (from BUFFER)
        .data1_req  (fsmd_data1_req), // 짝 샘플을 요구해 버퍼에서 정확한 Xi−Xmax를 획득
        .data1_en   (buf_data_valid), // 버퍼 데이터 준비 상태를 확인해 안전한 감산 타이밍 확보
        .data1_i    (buf_data_o), // 감산 피감수(Xi−Xmax) 입력으로 수치 정합 유지

        // external counter feedback (counter2)
        .count_i    (cnt2_out), // 진행 인덱스로 내부 상태와 외부 주소의 일관성 유지
        
        .ready      (ready), // 하류 수용능력 반영으로 결과 배출 타이밍 제어
        
        .last_count(cnt1_out), // 총 샘플 수 추정치(마지막 쓰기 주소 기준)로 종료 조건 판단을 단순화

        // results
        .data_o       (data_o), // Xi−Xmax−lnSumExp 결과(Q7.8)로 Exp2 입력 직결  :contentReference[oaicite:10]{index=10}
        .data_valid_o (data_valid_o), // 결과 유효 플래그로 다운스트림 파이프 동기화
        .outc         (fsmd_outc), // 한 샘플 처리 완료 펄스로 진행 카운터2 증가 유도
        .last         (last) // 벡터 종료 표식으로 상위 AXIS TLAST 정합·검사 용이
    );

endmodule // 단일 모듈 내에서 버퍼·카운터·FSMD를 결합해 Softmax의 하드웨어 친화식 감산 경로를 구성
