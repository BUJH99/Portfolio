`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 8-point FFT Core (Radix-2 DIF Butterfly, combinational datapath)
// - 입력 : i_x0 ~ i_x7 (21-bit signed, real-only)
// - 출력 : o_X0_re/im ~ o_X7_re/im (32-bit signed, complex)
// - 제어 : i_start=1 이면 연산 시작, o_busy=1 동안 연산, 완료 시 o_done=1 (1클럭)
// - 알고리즘 : Radix-2 Decimation-In-Frequency FFT (3-stage butterfly)
//   * 입력은 자연 순서, 내부 출력은 bit-reversed 순서
//   * 마지막에 bit-reverse 재배열하여 X[0..7]을 자연 순서로 출력
// - Twiddle : W = exp(-j*2*pi/8)
//   * W^0 = 1
//   * W^1 = 1/sqrt(2) - j 1/sqrt(2)
//   * W^2 = 0 - j
//   * W^3 = -1/sqrt(2) - j 1/sqrt(2)
//   * 1/sqrt(2) ≈ 181/256 → mul_inv_sqrt2()로 shift-add 근사
//////////////////////////////////////////////////////////////////////////////////
module fft8_core (
    input  wire              i_clk,
    input  wire              i_rstn,
    input  wire              i_start,

    input  wire signed [20:0] i_x0,
    input  wire signed [20:0] i_x1,
    input  wire signed [20:0] i_x2,
    input  wire signed [20:0] i_x3,
    input  wire signed [20:0] i_x4,
    input  wire signed [20:0] i_x5,
    input  wire signed [20:0] i_x6,
    input  wire signed [20:0] i_x7,

    output reg               o_busy,
    output reg               o_done,

    output reg signed [31:0] o_X0_re,
    output reg signed [31:0] o_X0_im,
    output reg signed [31:0] o_X1_re,
    output reg signed [31:0] o_X1_im,
    output reg signed [31:0] o_X2_re,
    output reg signed [31:0] o_X2_im,
    output reg signed [31:0] o_X3_re,
    output reg signed [31:0] o_X3_im,
    output reg signed [31:0] o_X4_re,
    output reg signed [31:0] o_X4_im,
    output reg signed [31:0] o_X5_re,
    output reg signed [31:0] o_X5_im,
    output reg signed [31:0] o_X6_re,
    output reg signed [31:0] o_X6_im,
    output reg signed [31:0] o_X7_re,
    output reg signed [31:0] o_X7_im
);

    // 상태 정의
    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;
    localparam ST_DONE = 2'd2;

    reg [1:0] state;

    // 입력 샘플을 32bit로 확장 (레지스터)
    reg signed [31:0] r_x0, r_x1, r_x2, r_x3;
    reg signed [31:0] r_x4, r_x5, r_x6, r_x7;

    // 각 Stage 중간값 (복소수) - 조합 논리 결과
    reg signed [31:0] s1_re [0:7], s1_im [0:7];  // Stage1
    reg signed [31:0] s2_re [0:7], s2_im [0:7];  // Stage2
    reg signed [31:0] s3_re [0:7], s3_im [0:7];  // Stage3 (bit-reversed X[k])

    // 임시 변수들 (조합용)
    integer i;
    reg signed [31:0] u_re, u_im;
    reg signed [31:0] v_re, v_im;
    reg signed [31:0] tmp_re, tmp_im;
    reg signed [31:0] t_re, t_im;

    // 1/sqrt(2) 근사: 181/256 ≈ 0.70703125
    // v * 181 / 256 = (v*(128+32+16+4+1)) >> 8
    function signed [31:0] mul_inv_sqrt2;
        input signed [31:0] v;
        reg   signed [31:0] t;
    begin
        t = (v <<< 7)   // *128
          + (v <<< 5)   // +*32
          + (v <<< 4)   // +*16
          + (v <<< 2)   // +*4
          + v;          // +*1
        mul_inv_sqrt2 = t >>> 8; // /256
    end
    endfunction

    //==================================================
    // 조합 논리: 3-stage Radix-2 DIF FFT 버터플라이
    //  - 입력: r_x0~r_x7
    //  - 출력: s3_re/im[0..7] (bit-reversed X[k])
    //==================================================
    always @* begin
        // (선택 사항) 기본값 0으로 초기화
        for (i=0; i<8; i=i+1) begin
            s1_re[i] = 32'sd0; s1_im[i] = 32'sd0;
            s2_re[i] = 32'sd0; s2_im[i] = 32'sd0;
            s3_re[i] = 32'sd0; s3_im[i] = 32'sd0;
        end

        //-------------------------
        // Stage 1 (길이 8, stride 4)
        //-------------------------
        // (0,4), W^0
        s1_re[0] = r_x0 + r_x4;
        s1_im[0] = 32'sd0;
        tmp_re   = r_x0 - r_x4;
        s1_re[4] = tmp_re;
        s1_im[4] = 32'sd0;

        // (1,5), W^1 = (1/sqrt(2)) - j(1/sqrt(2))
        s1_re[1] = r_x1 + r_x5;
        s1_im[1] = 32'sd0;
        tmp_re   = r_x1 - r_x5;              // real-only
        t_re     = mul_inv_sqrt2(tmp_re);    // x * 1/sqrt(2)
        t_im     = -t_re;                    // -x * 1/sqrt(2)
        s1_re[5] = t_re;
        s1_im[5] = t_im;

        // (2,6), W^2 = -j
        s1_re[2] = r_x2 + r_x6;
        s1_im[2] = 32'sd0;
        tmp_re   = r_x2 - r_x6;              // real-only
        // (d + j0)*(-j) = 0 + j(-d)
        s1_re[6] = 32'sd0;
        s1_im[6] = -tmp_re;

        // (3,7), W^3 = -1/sqrt(2) - j(1/sqrt(2))
        s1_re[3] = r_x3 + r_x7;
        s1_im[3] = 32'sd0;
        tmp_re   = r_x3 - r_x7;              // real-only
        t_re     = mul_inv_sqrt2(tmp_re);
        // (d+0j)*(-α - jα) = -dα + j(-dα)
        s1_re[7] = -t_re;
        s1_im[7] = -t_re;

        //-------------------------
        // Stage 2 (길이 4, 그룹 2개)
        //-------------------------

        // 그룹 0: index 0..3
        // (0,2), W^0
        u_re      = s1_re[0]; u_im = s1_im[0];
        v_re      = s1_re[2]; v_im = s1_im[2];
        s2_re[0]  = u_re + v_re;
        s2_im[0]  = u_im + v_im;
        tmp_re    = u_re - v_re;
        tmp_im    = u_im - v_im;
        s2_re[2]  = tmp_re;   // W^0
        s2_im[2]  = tmp_im;

        // (1,3), W^2 = -j
        u_re      = s1_re[1]; u_im = s1_im[1];
        v_re      = s1_re[3]; v_im = s1_im[3];
        s2_re[1]  = u_re + v_re;
        s2_im[1]  = u_im + v_im;
        tmp_re    = u_re - v_re;
        tmp_im    = u_im - v_im;
        // (tmp_re + j tmp_im)*(-j) = tmp_im + j(-tmp_re)
        s2_re[3]  = tmp_im;
        s2_im[3]  = -tmp_re;

        // 그룹 1: index 4..7
        // (4,6), W^0
        u_re      = s1_re[4]; u_im = s1_im[4];
        v_re      = s1_re[6]; v_im = s1_im[6];
        s2_re[4]  = u_re + v_re;
        s2_im[4]  = u_im + v_im;
        tmp_re    = u_re - v_re;
        tmp_im    = u_im - v_im;
        s2_re[6]  = tmp_re;
        s2_im[6]  = tmp_im;

        // (5,7), W^2 = -j
        u_re      = s1_re[5]; u_im = s1_im[5];
        v_re      = s1_re[7]; v_im = s1_im[7];
        s2_re[5]  = u_re + v_re;
        s2_im[5]  = u_im + v_im;
        tmp_re    = u_re - v_re;
        tmp_im    = u_im - v_im;
        s2_re[7]  = tmp_im;
        s2_im[7]  = -tmp_re;

        //-------------------------
        // Stage 3 (길이 2, 그룹 4개)
        //-------------------------

        // (0,1)
        u_re      = s2_re[0]; u_im = s2_im[0];
        v_re      = s2_re[1]; v_im = s2_im[1];
        s3_re[0]  = u_re + v_re;
        s3_im[0]  = u_im + v_im;
        s3_re[1]  = u_re - v_re;
        s3_im[1]  = u_im - v_im;

        // (2,3)
        u_re      = s2_re[2]; u_im = s2_im[2];
        v_re      = s2_re[3]; v_im = s2_im[3];
        s3_re[2]  = u_re + v_re;
        s3_im[2]  = u_im + v_im;
        s3_re[3]  = u_re - v_re;
        s3_im[3]  = u_im - v_im;

        // (4,5)
        u_re      = s2_re[4]; u_im = s2_im[4];
        v_re      = s2_re[5]; v_im = s2_im[5];
        s3_re[4]  = u_re + v_re;
        s3_im[4]  = u_im + v_im;
        s3_re[5]  = u_re - v_re;
        s3_im[5]  = u_im - v_im;

        // (6,7)
        u_re      = s2_re[6]; u_im = s2_im[6];
        v_re      = s2_re[7]; v_im = s2_im[7];
        s3_re[6]  = u_re + v_re;
        s3_im[6]  = u_im + v_im;
        s3_re[7]  = u_re - v_re;
        s3_im[7]  = u_im - v_im;
    end

    //==================================================
    // 순차 로직: 입력 래치 + busy/done + 출력 래치
    //==================================================
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            state  <= ST_IDLE;
            o_busy <= 1'b0;
            o_done <= 1'b0;

            r_x0 <= 32'sd0; r_x1 <= 32'sd0; r_x2 <= 32'sd0; r_x3 <= 32'sd0;
            r_x4 <= 32'sd0; r_x5 <= 32'sd0; r_x6 <= 32'sd0; r_x7 <= 32'sd0;

            o_X0_re <= 32'sd0; o_X0_im <= 32'sd0;
            o_X1_re <= 32'sd0; o_X1_im <= 32'sd0;
            o_X2_re <= 32'sd0; o_X2_im <= 32'sd0;
            o_X3_re <= 32'sd0; o_X3_im <= 32'sd0;
            o_X4_re <= 32'sd0; o_X4_im <= 32'sd0;
            o_X5_re <= 32'sd0; o_X5_im <= 32'sd0;
            o_X6_re <= 32'sd0; o_X6_im <= 32'sd0;
            o_X7_re <= 32'sd0; o_X7_im <= 32'sd0;
        end
        else begin
            o_done <= 1'b0; // 기본값

            case (state)
            //--------------------------------------------
            // IDLE: i_start=1 → 입력 래치 후 RUN
            //--------------------------------------------
            ST_IDLE: begin
                o_busy <= 1'b0;
                if (i_start) begin
                    // sign-extend 21bit → 32bit
                    r_x0 <= {{11{i_x0[20]}}, i_x0};
                    r_x1 <= {{11{i_x1[20]}}, i_x1};
                    r_x2 <= {{11{i_x2[20]}}, i_x2};
                    r_x3 <= {{11{i_x3[20]}}, i_x3};
                    r_x4 <= {{11{i_x4[20]}}, i_x4};
                    r_x5 <= {{11{i_x5[20]}}, i_x5};
                    r_x6 <= {{11{i_x6[20]}}, i_x6};
                    r_x7 <= {{11{i_x7[20]}}, i_x7};

                    o_busy <= 1'b1;
                    state  <= ST_RUN;
                end
            end

            //--------------------------------------------
            // RUN: 조합 FFT 결과(s3_*)를 출력 레지스터에 저장
            //--------------------------------------------
            ST_RUN: begin
                // DIF 결과는 bit-reversed index에 매핑되어 있음
                // N=8에서 bit-reverse 매핑:
                //   X0 = Y0
                //   X1 = Y4
                //   X2 = Y2
                //   X3 = Y6
                //   X4 = Y1
                //   X5 = Y5
                //   X6 = Y3
                //   X7 = Y7
                o_X0_re <= s3_re[0];
                o_X0_im <= s3_im[0];

                o_X1_re <= s3_re[4];
                o_X1_im <= s3_im[4];

                o_X2_re <= s3_re[2];
                o_X2_im <= s3_im[2];

                o_X3_re <= s3_re[6];
                o_X3_im <= s3_im[6];

                o_X4_re <= s3_re[1];
                o_X4_im <= s3_im[1];

                o_X5_re <= s3_re[5];
                o_X5_im <= s3_im[5];

                o_X6_re <= s3_re[3];
                o_X6_im <= s3_im[3];

                o_X7_re <= s3_re[7];
                o_X7_im <= s3_im[7];

                o_busy <= 1'b0;
                state  <= ST_DONE;
            end

            //--------------------------------------------
            // DONE: o_done 1클럭 펄스 후 IDLE
            //--------------------------------------------
            ST_DONE: begin
                o_done <= 1'b1;
                state  <= ST_IDLE;
            end

            default: begin
                state <= ST_IDLE;
            end
            endcase
        end
    end

endmodule
