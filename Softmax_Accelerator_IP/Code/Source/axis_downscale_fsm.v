`timescale 1ns/1ps
module axis_downscale_fsm #(
    parameter integer C_MAX    = 1024,
    parameter integer ADDR_W   = 10,
    parameter integer READ_LAT = 1
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // 입력 스트림
    input  wire                 s_valid,
    input  wire                 s_last,
    input  wire                 m_ready,

    output wire                 s_ready,      // IDLE/FILL=1, DRAIN=0
    output wire                 in_fire,      // 수락 펄스
    output reg                  start_first,  // 첫 샘플 수락 1클럭 펄스

    // 버퍼 쓰기
    output reg                  we,
    output reg  [ADDR_W-1:0]    waddr,

    // 버퍼 읽기 (READ_LAT=1)
    output reg                  re,
    output reg  [ADDR_W-1:0]    raddr,
    output reg  [ADDR_W-1:0]    vec_len,

    // 출력 스트림
    output reg                  m_valid,
    output reg                  m_last
);
    localparam [1:0]
        ST_IDLE  = 2'd0,
        ST_FILL  = 2'd1,
        ST_DRAIN = 2'd2;

    reg [1:0] state, state_n;
    reg [ADDR_W-1:0] wr_ptr, wr_ptr_n;
    reg [ADDR_W-1:0] rd_ptr, rd_ptr_n;

    // 준비 신호: DRAIN 때만 0
    assign s_ready = (state != ST_DRAIN);
    assign in_fire = s_valid & s_ready;

    // READ_LAT=1 파이프
    reg re_d1;
    reg [ADDR_W-1:0] rd_ptr_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            re_d1     <= 1'b0;
            rd_ptr_d1 <= {ADDR_W{1'b0}};
        end else begin
            re_d1     <= re;
            rd_ptr_d1 <= rd_ptr;
        end
    end

    // 조합
    always @* begin
        state_n   = state;
        wr_ptr_n  = wr_ptr;
        rd_ptr_n  = rd_ptr;

        we        = 1'b0;
        waddr     = wr_ptr;

        re        = 1'b0;
        raddr     = rd_ptr;

        start_first = 1'b0;

        case (state)
            // -----------------------------------------
            ST_IDLE: begin
                // IDLE에서도 s_ready=1이므로 in_fire 가능
                if (in_fire) begin
                    we       = 1'b1;          // 첫 샘플 즉시 기록
                    waddr    = wr_ptr;        // 0
                    wr_ptr_n = wr_ptr + 1'b1; // 1
                    start_first = 1'b1;
                    if (s_last) begin
                        // 1개짜리 벡터도 지원
                        // vec_len은 순차블록에서 갱신
                        state_n = ST_DRAIN;
                    end else begin
                        state_n = ST_FILL;
                    end
                end
            end

            // -----------------------------------------
            ST_FILL: begin
                if (in_fire) begin
                    we       = 1'b1;
                    waddr    = wr_ptr;
                    wr_ptr_n = wr_ptr + 1'b1;
                    if (s_last) begin
                        state_n = ST_DRAIN;
                    end
                end
            end

            // -----------------------------------------
            ST_DRAIN: begin
                if (rd_ptr < vec_len) begin
                    if (m_ready) begin
                        re       = 1'b1;     // 주소 제시
                        raddr    = rd_ptr;
                        rd_ptr_n = rd_ptr + 1'b1;
                    end
                end else begin
                    state_n = ST_IDLE;
                end
            end

            default: state_n = ST_IDLE;
        endcase
    end

    // 순차
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= ST_IDLE;
            wr_ptr  <= {ADDR_W{1'b0}};
            rd_ptr  <= {ADDR_W{1'b0}};
            vec_len <= {ADDR_W{1'b0}};
            m_valid <= 1'b0;
            m_last  <= 1'b0;
        end else begin
            state  <= state_n;
            wr_ptr <= wr_ptr_n;
            rd_ptr <= rd_ptr_n;

            // s_last를 "수락 시점"에 맞춰 vec_len 고정
            if ((state==ST_IDLE || state==ST_FILL) && in_fire && s_last) begin
                vec_len <= wr_ptr_n; // wr_ptr+1
            end

            // READ_LAT=1: re_d1에 맞춰 m_valid/m_last 생성
            if (state == ST_DRAIN) begin
                m_valid <= re_d1;
                if (re_d1) m_last <= (rd_ptr_d1 == (vec_len - 1'b1));
                else       m_last <= 1'b0;
            end else begin
                m_valid <= 1'b0;
                m_last  <= 1'b0;
            end

            // IDLE 복귀 시 포인터 초기화
            if (state_n == ST_IDLE && state != ST_IDLE) begin
                wr_ptr <= {ADDR_W{1'b0}};
                rd_ptr <= {ADDR_W{1'b0}};
            end
        end
    end
endmodule
