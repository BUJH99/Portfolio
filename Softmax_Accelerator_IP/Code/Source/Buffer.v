`timescale 1ns/1ps // 시뮬레이션 해상도/정밀도(1ns/1ps) 고정으로 타이밍 비교 기준을 통일

/* =====================================================================================================================
 * File Name   : Buffer.v
 * Project     : Softmax layer Accelerator Based on FPGA
 * Author      : 숭상화
 * Creation Date: 2025-08-30
 * Description : 단일 클록, 동기식 쓰기/1사이클 지연 읽기 버퍼로서 Q-포맷 스트림의 임시 저장과 RAW 충돌 시 write-first를 의도
 * Design Notes:
 *   - DATA_WIDTH/ADDR_WIDTH 파라미터화로 자원·지연 균형 조정(깊이=2^ADDR_WIDTH) // 다양한 토폴로지에 재사용하기 위한 유연성 확보
 *   - 읽기는 레지스터 1단 삽입으로 타이밍 마진을 확보하고 data_valid로 소비 타이밍을 명시 // 다운스트림 샘플 타이밍을 결정적으로 제공
 *   - 동일 사이클 같은 주소 read/write 시 write-through로 정의하여 RAW 모호성 제거 // FPGA 추론에서 write-first 동작을 기대
 * Dependencies: 상위 시스템의 스트림 소스/싱크와 결선(독립 모듈) // 외부 AXI-Stream 등과 쉽게 연결 가능
 =====================================================================================================================*/

/**
 * @brief 단일 클록 동기식 버퍼(1-사이클 지연 읽기, write-first RAW 처리)
 * @details data_valid로 읽기 유효 타이밍을 명확히 하며, 같은 사이클 같은 주소 접근은 갓 쓴 값을 우선시해 수치 일관성을 보장
 * @param clk 상태/메모리 동기 클록으로 모든 동작을 상승엣지에 정렬
 * @param rst_n Low-Active 리셋으로 초기 상태를 빠르게 강제하여 X 전파를 차단
 * @param data_i 쓰기 데이터로서 save_en과 addr_i에 동기화되어 저장
 * @param save_en 쓰기 인에이블로 클록 상승엣지에서만 메모리 변경을 허용
 * @param addr_i 쓰기 주소로서 RAW 충돌 판정의 기준이 됨
 * @param load_en 읽기 요청으로 다음 사이클 data_valid를 1로 만들어 소비 타이밍을 알림
 * @param addr_o 읽기 주소로서 load_en과 함께 캡처되어 1사이클 뒤 데이터가 출력
 * @param data_valid 읽기 결과 유효 1사이클 펄스로 다운스트림의 샘플 타이밍 기준
 * @param data_o 읽기 데이터로서 write-first 정책에 따라 동주기 RAW 시 data_i가 우선
 */

 /**********************************************************************
 * Stage 0: 파라미터/IF 선언
 * - 폭/깊이를 파라미터화하여 BRAM/분산RAM 선택과 타이밍 목표에 맞춘 스케일링 지원
 **********************************************************************/
module buffer_sync #(
    parameter integer DATA_WIDTH = 16, // Q-포맷 등 데이터 폭 변동에 대응하여 모듈 재사용성 극대화
    parameter integer ADDR_WIDTH = 8 // 깊이=2^ADDR_WIDTH로 지수적 확장 구조를 명시
) (
    input  wire                       clk, // 단일 클록 도메인 가정으로 CDC 이슈 제거
    input  wire                       rst_n, // Low-Active 리셋 채택으로 시스템 전역 리셋과의 친화성 확보

    // write port
    input  wire [DATA_WIDTH-1:0]      data_i, // 저장 대상 데이터로 후속 스테이지의 재사용을 위해 원형 보존
    input  wire                       save_en, // 상승엣지 유효 시에만 쓰기 허용하여 글리치 유발 방지
    input  wire [ADDR_WIDTH-1:0]      addr_i, // 쓰기 주소 인덱스로 동일 사이클 RAW 판정의 한 축

    // read port
    input  wire                       load_en, // 읽기 요청으로 다음 사이클 data_valid를 통해 타이밍 계약 확정
    input  wire [ADDR_WIDTH-1:0]      addr_o, // 읽기 주소 인덱스로 1사이클 뒤 data_o를 선택

    // outputs
    output reg                        data_valid, // 읽기 결과 유효 1펄스로 소비측에서 정확히 한 번 샘플하도록 유도
    output reg  [DATA_WIDTH-1:0]      data_o // 읽기 결과 데이터로 write-first 정책 반영
); // 인터페이스 종결로 상위 결선 시그니처를 명확화

    /**********************************************************************
     * Stage 1: 파생 상수/메모리 선언
     * - 깊이를 지역상수로 고정해 합성기 최적화를 돕고, RAM 추론을 유도
     **********************************************************************/
    localparam integer DEPTH = (1 << ADDR_WIDTH); // 깊이를 2의 거듭제곱으로 정의하여 주소 디코딩 단순화

    // Memory array
    // Xilinx: add ram_style = "block" if BRAM 유도 원하면 주석 해제
    // (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1]; // 단일 포트 RAM 형태로 추론되며 폭/깊이 균형에 따라 BRAM/분산RAM 결정

    /**********************************************************************
     * Stage 2: 쓰기 포트(동기)
     * - 상승엣지에서 save_en이 1일 때만 쓰기하여 메타 안정성과 타이밍 예측 가능성 확보
     **********************************************************************/
    always @(posedge clk) begin // 동기식 메모리 인터페이스로 CDC 제거
        if (!rst_n) begin // 메모리 셀은 보통 리셋 미지원이므로 제어 레지스터만 리셋
            // 메모리 내용 리셋 생략: 대부분의 FPGA RAM 프리미티브가 비지원이라 합성 호환성을 위해 유지 // 전원 인가 후 초기값 불요 가정
        end else if (save_en) begin // 유효 쓰기 요청이 있을 때만 메모리 갱신으로 불필요 토글 억제
            mem[addr_i] <= data_i; // 주소 지정 쓰기 수행으로 후속 RAW 정책의 기반을 마련
        end // save_en 조건문 종료로 우발적 쓰기 방지
    end // 쓰기 always 블록 종료로 동기 쓰기 정의 명확화

    /**********************************************************************
     * Stage 3: 읽기 주소 캡처/데이터 경로(1사이클 지연)
     * - data_valid를 load_en에 정렬해 소비 타이밍을 계약하고, RAW 충돌 시 write-through로 일관성 보장
     **********************************************************************/
    always @(posedge clk) begin // 읽기도 클록 동기에 맞춰 1사이클 지연을 명시
        if (!rst_n) begin // 리셋 시 인터페이스 가시 상태를 결정적으로 초기화
            data_valid<= 1'b0; // 유효 펄스를 0으로 정리해 불의의 샘플링 방지
            data_o    <= {DATA_WIDTH{1'b0}}; // 출력 초기화를 통해 X 전파 차단
        end else begin // 정상 동작 경로로 1사이클 파이프 계약 수행
            data_valid <= load_en; // 다음 사이클 유효 펄스를 예고하여 다운스트림이 정확히 샘플하게 함

            // 1-cycle 지연 데이터 출력 경로 // load_en이 1일 때만 데이터 경로를 활성화해 불필요 토글 억제
            // RAW(read-after-write) 같은 주소 동시 접근 시 갓 쓴 값이 보이도록 우선순위 부여 // 수학적 일관성을 위해 write-first 강제
            // (동일 클록에 write&read가 교차할 경우, 많은 FPGA가 "write-first" 모드로 추론되도록 아래와 같이 처리) // 합성기 의도 전달
            if (load_en) begin // 읽기 요청이 있을 때만 경로 활성
                if (save_en && (addr_i == addr_o)) begin // 같은 사이클·같은 주소 접근 시 충돌을 write-through로 해결
                    data_o <= data_i; // 최신값 우선으로 수치적 재현성 보장
                end else begin // 충돌이 아니면 저장된 값을 정상 경로로 제공
                    data_o <= mem[addr_o]; // 1사이클 지연된 저장값을 출력하여 타이밍 여유 확보
                end // RAW 분기 종료로 명확한 정책 확립
            end // load_en 조건 종료로 불필요 토글 방지
        end // 리셋/정상 분기 종료로 상태 일관성 유지
    end // 읽기 always 블록 종료로 파이프 구조 명확화

endmodule // 모듈 종료: 단일 클록, write-first 정책, 1사이클 지연 읽기로 스트림 타이밍을 안정화
