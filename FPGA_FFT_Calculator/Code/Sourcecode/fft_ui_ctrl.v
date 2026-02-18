`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// FFT UI Controller (Calculator-style Input)
//  - 8 samples, each as signed decimal: int 3 digits + frac 3 digits
//  - Input style:
//      * digits: append like calculator (12 -> 12, not 120)
//      * '/'   : decimal point, 이후 숫자는 소수부
//      * '-'   : 언제든 부호 토글
//      * F1    : Backspace (부호 제외 마지막 입력 한 자리 지움)
//      * F2/F3 : 인덱스 이동 (기존 값 유지, 이어서 입력 가능)
//  - FFT input: ±999.999 (×1000 정수로 변환)
//  - FFT output display: ±9999.999 (4자리 정수 + 3자리 소수)
//  - o_index : 현재 인덱스를 active-low로 표시
//  - o_FFT   : 1 = FFT 전(입력 단계), 0 = FFT 계산/결과 단계
//  - o_re_im : 1 = 실수 표시, 0 = 허수 표시 (입력 단계에서는 1)
//////////////////////////////////////////////////////////////////////////////////
module fft_ui_ctrl #(
    parameter N_SAMPLES = 8
)(
    input  wire              i_clk,
    input  wire              i_rstn,
    input  wire              i_pls_1k,

    // 키 디코더 + valid
    input  wire              i_key_valid,
    input  wire              i_is_digit,
    input  wire [3:0]        i_digit,
    input  wire              i_is_minus,
    input  wire              i_is_dot,
    input  wire              i_is_del,
    input  wire              i_is_next,
    input  wire              i_is_prev,
    input  wire              i_is_toggle_ri,
    input  wire              i_is_ent,
    input  wire              i_is_esc,

    // FFT 코어 인터페이스
    output reg               o_fft_start,   // 1클럭 pulse
    input  wire              i_fft_busy,
    input  wire              i_fft_done,

    output wire signed [20:0] o_x0,
    output wire signed [20:0] o_x1,
    output wire signed [20:0] o_x2,
    output wire signed [20:0] o_x3,
    output wire signed [20:0] o_x4,
    output wire signed [20:0] o_x5,
    output wire signed [20:0] o_x6,
    output wire signed [20:0] o_x7,

    input  wire signed [31:0] i_X0_re,
    input  wire signed [31:0] i_X0_im,
    input  wire signed [31:0] i_X1_re,
    input  wire signed [31:0] i_X1_im,
    input  wire signed [31:0] i_X2_re,
    input  wire signed [31:0] i_X2_im,
    input  wire signed [31:0] i_X3_re,
    input  wire signed [31:0] i_X3_im,
    input  wire signed [31:0] i_X4_re,
    input  wire signed [31:0] i_X4_im,
    input  wire signed [31:0] i_X5_re,
    input  wire signed [31:0] i_X5_im,
    input  wire signed [31:0] i_X6_re,
    input  wire signed [31:0] i_X6_im,
    input  wire signed [31:0] i_X7_re,
    input  wire signed [31:0] i_X7_im,

    // 7-Segment 출력용
    output reg  [31:0]       o_bcd8d,
    output reg  [7:0]        o_dp_mask,

    // 현재 표시 중인 인덱스 LED (active-low)
    output wire [7:0]        o_index,

    // 상태 플래그
    output reg               o_FFT,     // 1: 입력 단계(FFT 전), 0: FFT 계산/결과 단계
    output reg               o_re_im    // 1: 실수 표시, 0: 허수 표시
);

    // 모드 정의
    localparam MODE_INPUT    = 2'd0;
    localparam MODE_WAIT_FFT = 2'd1;
    localparam MODE_OUTPUT   = 2'd2;

    reg [1:0]  r_mode;

    // 입력 모드에서 현재 인덱스(0~7), 출력 모드에서 현재 FFT bin(0~7)
    reg [2:0]  r_cur_sample;
    reg [2:0]  r_cur_bin;

    // 각 샘플의 부호 (1이면 음수)
    reg [7:0]  r_sample_sign;   // bit[i]

    // 각 샘플의 소수점 입력 여부 (1: '/'를 눌렀음)
    reg [7:0]  r_dp_flag;       // bit[i]

    // 정수부/소수부 길이 (0~3)
    reg [1:0]  r_int_len  [0:N_SAMPLES-1];
    reg [1:0]  r_frac_len [0:N_SAMPLES-1];

    // 정수부/소수부 BCD (각 3자리, [11:8]=첫 자리, [7:4]=둘째, [3:0]=셋째)
    reg [11:0] r_int_bcd  [0:N_SAMPLES-1];
    reg [11:0] r_frac_bcd [0:N_SAMPLES-1];

    // FFT 입력 값 (×1000 스케일, ±999.999 범위 내)
    reg signed [20:0] r_x [0:N_SAMPLES-1];

    // 출력 모드에서 실수/허수 선택 (0: real, 1: imag)
    reg r_show_imag;

    integer i;
    integer idx;
    integer s;
    integer j;
    integer k;

    reg [20:0] abs_scaled;

    //---------------------------------------------
    // Helper: 정수부(0~999) 계산
    //---------------------------------------------
    function [9:0] fn_int_part;
        input [11:0] bcd;   // [11:8]=d0, [7:4]=d1, [3:0]=d2
        input [1:0]  len;   // 0~3
        reg   [3:0]  d0,d1,d2;
        reg   [9:0]  v;
    begin
        d0 = bcd[11:8];
        d1 = bcd[7:4];
        d2 = bcd[3:0];
        case (len)
            2'd0: v = 10'd0;
            2'd1: v = d0;
            2'd2: v = d0*10 + d1;
            default: v = d0*100 + d1*10 + d2; // len==3
        endcase
        fn_int_part = v;
    end
    endfunction

    //---------------------------------------------
    // Helper: 소수부(0~999) 계산 (×1000 스케일 기준)
    //---------------------------------------------
    function [9:0] fn_frac_part;
        input [11:0] bcd;
        input [1:0]  len;
        reg   [3:0]  f0,f1,f2;
        reg   [9:0]  v;
    begin
        f0 = bcd[11:8];
        f1 = bcd[7:4];
        f2 = bcd[3:0];
        case (len)
            2'd0: v = 10'd0;
            2'd1: v = f0*100;
            2'd2: v = f0*100 + f1*10;
            default: v = f0*100 + f1*10 + f2;
        endcase
        fn_frac_part = v;
    end
    endfunction

    //---------------------------------------------
    // Helper: 한 샘플의 절대값 ×1000 정수로 변환 (0~999_999)
    //---------------------------------------------
    function [20:0] fn_sample_abs_scaled;
        input [11:0] int_bcd;
        input [11:0] frac_bcd;
        input [1:0]  int_len;
        input [1:0]  frac_len;
        reg [9:0] ip;
        reg [9:0] fp;
        reg [20:0] scaled;
    begin
        ip = fn_int_part(int_bcd,  int_len);   // 0~999
        fp = fn_frac_part(frac_bcd, frac_len); // 0~999
        // scaled = ip*1000 + fp;  (*1000 = *1024 - *16 - *8)
        scaled = ( (ip << 10) - (ip << 4) - (ip << 3) );
        scaled = scaled + fp;
        fn_sample_abs_scaled = scaled;
    end
    endfunction

    // FFT 입력 포트 매핑
    assign o_x0 = r_x[0];
    assign o_x1 = r_x[1];
    assign o_x2 = r_x[2];
    assign o_x3 = r_x[3];
    assign o_x4 = r_x[4];
    assign o_x5 = r_x[5];
    assign o_x6 = r_x[6];
    assign o_x7 = r_x[7];

    //---------------------------------------------
    // 메인 상태/입력 처리 (이 부분은 기존과 동일)
    //---------------------------------------------
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            r_mode       <= MODE_INPUT;
            r_cur_sample <= 3'd0;
            r_cur_bin    <= 3'd0;
            r_show_imag  <= 1'b0;
            r_sample_sign<= 8'd0;
            r_dp_flag    <= 8'd0;
            for (i=0; i<N_SAMPLES; i=i+1) begin
                r_int_len[i]   <= 2'd0;
                r_frac_len[i]  <= 2'd0;
                r_int_bcd[i]   <= 12'd0;
                r_frac_bcd[i]  <= 12'd0;
                r_x[i]         <= 21'sd0;
            end
            o_fft_start  <= 1'b0;
        end
        else begin
            o_fft_start <= 1'b0;

            // FFT 완료 체크
            if (r_mode == MODE_WAIT_FFT) begin
                if (i_fft_done) begin
                    r_mode      <= MODE_OUTPUT;
                    r_cur_bin   <= 3'd0;
                    r_show_imag <= 1'b0;   // 처음에는 실수부 표시
                end
            end

            // 키 입력 처리
            if (i_key_valid) begin
                case (r_mode)
                //--------------------------------------------------
                // 입력 모드
                //--------------------------------------------------
                MODE_INPUT: begin
                    idx = r_cur_sample;

                    if (i_is_digit) begin
                        if (!r_dp_flag[idx]) begin
                            // 정수부 입력 (최대 3자리)
                            if (r_int_len[idx] < 2'd3) begin
                                case (r_int_len[idx])
                                    2'd0: r_int_bcd[idx][11:8] <= i_digit;
                                    2'd1: r_int_bcd[idx][7:4]  <= i_digit;
                                    2'd2: r_int_bcd[idx][3:0]  <= i_digit;
                                endcase
                                r_int_len[idx] <= r_int_len[idx] + 2'd1;
                            end
                        end
                        else begin
                            // 소수부 입력 (최대 3자리)
                            if (r_frac_len[idx] < 2'd3) begin
                                case (r_frac_len[idx])
                                    2'd0: r_frac_bcd[idx][11:8] <= i_digit;
                                    2'd1: r_frac_bcd[idx][7:4]  <= i_digit;
                                    2'd2: r_frac_bcd[idx][3:0]  <= i_digit;
                                endcase
                                r_frac_len[idx] <= r_frac_len[idx] + 2'd1;
                            end
                        end
                    end
                    else if (i_is_minus) begin
                        // 언제든 부호 토글
                        r_sample_sign[idx] <= ~r_sample_sign[idx];
                    end
                    else if (i_is_dot) begin
                        // 소수점 입력 (한 번만 의미 있음)
                        r_dp_flag[idx] <= 1'b1;
                    end
                    else if (i_is_del) begin
                        // Backspace: 소수부 -> '.' -> 정수부 순서로 한 자리씩 지움
                        if (r_frac_len[idx] > 0) begin
                            case (r_frac_len[idx])
                                2'd1: r_frac_bcd[idx][11:8] <= 4'd0;
                                2'd2: r_frac_bcd[idx][7:4]  <= 4'd0;
                                2'd3: r_frac_bcd[idx][3:0]  <= 4'd0;
                            endcase
                            r_frac_len[idx] <= r_frac_len[idx] - 2'd1;
                        end
                        else if (r_dp_flag[idx]) begin
                            r_dp_flag[idx] <= 1'b0;  // '.' 제거
                        end
                        else if (r_int_len[idx] > 0) begin
                            case (r_int_len[idx])
                                2'd1: r_int_bcd[idx][11:8] <= 4'd0;
                                2'd2: r_int_bcd[idx][7:4]  <= 4'd0;
                                2'd3: r_int_bcd[idx][3:0]  <= 4'd0;
                            endcase
                            r_int_len[idx] <= r_int_len[idx] - 2'd1;
                        end
                        // 부호는 지우지 않음
                    end
                    else if (i_is_next) begin
                        r_cur_sample <= (r_cur_sample==3'd7) ? 3'd0 : (r_cur_sample + 3'd1);
                    end
                    else if (i_is_prev) begin
                        r_cur_sample <= (r_cur_sample==3'd0) ? 3'd7 : (r_cur_sample - 3'd1);
                    end
                    else if (i_is_esc) begin
                        // 전체 초기화
                        r_sample_sign <= 8'd0;
                        r_dp_flag     <= 8'd0;
                        for (i=0; i<N_SAMPLES; i=i+1) begin
                            r_int_len[i]   <= 2'd0;
                            r_frac_len[i]  <= 2'd0;
                            r_int_bcd[i]   <= 12'd0;
                            r_frac_bcd[i]  <= 12'd0;
                        end
                        r_cur_sample <= 3'd0;
                    end
                    else if (i_is_ent && !i_fft_busy) begin
                        // 모든 샘플을 ×1000 정수로 변환하여 r_x에 저장, FFT 시작
                        for (i=0; i<N_SAMPLES; i=i+1) begin
                            abs_scaled = fn_sample_abs_scaled(
                                r_int_bcd[i], r_frac_bcd[i],
                                r_int_len[i],  r_frac_len[i]
                            );
                            if (abs_scaled == 21'd0) begin
                                r_x[i] <= 21'sd0;   // 0일 때는 부호 무시
                            end
                            else if (r_sample_sign[i]) begin
                                r_x[i] <= -$signed(abs_scaled);
                            end
                            else begin
                                r_x[i] <=  $signed(abs_scaled);
                            end
                        end
                        o_fft_start <= 1'b1;
                        r_mode      <= MODE_WAIT_FFT;
                    end
                end // MODE_INPUT

                //--------------------------------------------------
                // 출력 모드
                //--------------------------------------------------
                MODE_OUTPUT: begin
                    if (i_is_next) begin
                        r_cur_bin <= (r_cur_bin==3'd7) ? 3'd0 : (r_cur_bin + 3'd1);
                    end
                    else if (i_is_prev) begin
                        r_cur_bin <= (r_cur_bin==3'd0) ? 3'd7 : (r_cur_bin - 3'd1);
                    end
                    else if (i_is_toggle_ri) begin
                        r_show_imag <= ~r_show_imag;  // 0:real -> 1:imag
                    end
                    else if (i_is_esc) begin
                        r_mode       <= MODE_INPUT;
                        r_cur_sample <= 3'd0;
                    end
                end

                //--------------------------------------------------
                // WAIT_FFT: 별도 키 처리 없음
                //--------------------------------------------------
                default: begin
                    // no-op
                end
                endcase
            end
        end
    end

    //----------------------------------------------------------
    // FFT 결과 선택 + 절대값/부호/포화 (출력 모드용)
    //----------------------------------------------------------
    reg signed [31:0] cur_val_out;
    wire        cur_sign_raw;
    wire [31:0] cur_abs_raw;
    wire [31:0] cur_abs_sat;

    always @* begin
        case (r_cur_bin)
            3'd0: cur_val_out = r_show_imag ? i_X0_im : i_X0_re;
            3'd1: cur_val_out = r_show_imag ? i_X1_im : i_X1_re;
            3'd2: cur_val_out = r_show_imag ? i_X2_im : i_X2_re;
            3'd3: cur_val_out = r_show_imag ? i_X3_im : i_X3_re;
            3'd4: cur_val_out = r_show_imag ? i_X4_im : i_X4_re;
            3'd5: cur_val_out = r_show_imag ? i_X5_im : i_X5_re;
            3'd6: cur_val_out = r_show_imag ? i_X6_im : i_X6_re;
            3'd7: cur_val_out = r_show_imag ? i_X7_im : i_X7_re;
            default: cur_val_out = 32'sd0;
        endcase
    end

    assign cur_sign_raw = cur_val_out[31];
    assign cur_abs_raw  = cur_sign_raw ? (~cur_val_out + 32'd1) : cur_val_out;

    // 최대 9,999,999 로 포화 (24bit 이하)
    assign cur_abs_sat  = (cur_abs_raw > 32'd9_999_999) ? 32'd9_999_999 : cur_abs_raw;

    //----------------------------------------------------------
    // Binary → BCD7 변환기 인스턴스 (Multi-cycle)
    //----------------------------------------------------------
    reg        bcd_start;
    wire       bcd_busy;
    wire       bcd_done;
    wire [27:0] bcd7_val;

    // 변환 결과/부호 저장용
    reg [27:0] disp_bcd7;
    reg        disp_sign;
    reg        start_req_sign;
    reg        start_req_zero;

    bin_to_bcd7 u_bin_to_bcd7 (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),
        .i_start (bcd_start),
        .i_val   (cur_abs_sat[23:0]),   // 24bit 만 사용
        .o_busy  (bcd_busy),
        .o_done  (bcd_done),
        .o_bcd7  (bcd7_val)
    );

    // 변환 제어
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            bcd_start      <= 1'b0;
            disp_bcd7      <= 28'd0;
            disp_sign      <= 1'b0;
            start_req_sign <= 1'b0;
            start_req_zero <= 1'b1;
        end else begin
            bcd_start <= 1'b0;

            // 출력 모드에서, 변환기가 놀고 있으면 계속 최신 값으로 변환
            if ((r_mode == MODE_OUTPUT) && !bcd_busy) begin
                bcd_start      <= 1'b1;
                start_req_sign <= cur_sign_raw;
                start_req_zero <= (cur_abs_sat == 32'd0);
            end

            // 변환 완료 시 결과 래치
            if (bcd_done) begin
                disp_bcd7 <= bcd7_val;
                // 0일 때는 부호 표시 안 함
                disp_sign <= start_req_sign & ~start_req_zero;
            end
        end
    end

    //----------------------------------------------------------
    // 7-Segment 표시용 조합 논리
    //   - 입력 모드: 계산기 스타일, 오른쪽 정렬
    //   - 출력 모드: ±iiii.fff (disp_bcd7 사용)
    //----------------------------------------------------------
    reg [31:0]        cur_abs_dummy;  // 사용 안 하지만 형태 맞추기용
    reg signed [31:0] cur_val_dummy;

    // 입력 모드용 임시 변수들
    integer idx2;
    integer t;        // token index (왼쪽→오른쪽)
    integer width;    // sign + int_len + frac_len
    integer t_dp;     // token index of last integer digit
    integer s_dp;     // 실제 디지트 index (0=rightmost)
    reg [3:0] sym [0:7];    // sym[0]=digit0 (오른쪽), sym[7]=digit7 (왼쪽)
    reg [7:0] dp_local;
    reg       sign_cur;
    reg [1:0] int_len_cur, frac_len_cur;
    reg       dp_flag_cur;
    reg [3:0] digit_val;

    always @* begin
        o_bcd8d   = 32'd0;
        o_dp_mask = 8'b0000_0000;

        // sym, dp_local 초기화
        dp_local = 8'b0000_0000;
        for (t=0; t<8; t=t+1) begin
            sym[t] = 4'hB;   // blank
        end

        if (r_mode == MODE_INPUT) begin
            //------------------------------------------------------
            // 입력 모드 표시 (계산기 스타일)
            //------------------------------------------------------
            idx2         = r_cur_sample;
            sign_cur     = r_sample_sign[idx2];
            int_len_cur  = r_int_len[idx2];
            frac_len_cur = r_frac_len[idx2];
            dp_flag_cur  = r_dp_flag[idx2];

            // 전체 자릿수 (sign + 정수 + 소수)
            width = int_len_cur + frac_len_cur + (sign_cur ? 1 : 0);

            if (width != 0) begin
                // 토큰(왼→오) 인덱스 t: 0..width-1, 최대 8로 클램프
                for (t=0; t<8; t=t+1) begin
                    if (t < width) begin
                        s = width-1 - t; // 오른쪽 정렬

                        if (sign_cur && (t == 0)) begin
                            // sign token
                            sym[s] = 4'hA;     // '-'
                        end
                        else if (t >= (sign_cur ? 1 : 0) &&
                                 t <  (sign_cur ? 1 : 0) + int_len_cur) begin
                            // 정수부 자리
                            j = t - (sign_cur ? 1 : 0); // 0..int_len_cur-1
                            case (j)
                                0: digit_val = r_int_bcd[idx2][11:8];
                                1: digit_val = r_int_bcd[idx2][7:4];
                                2: digit_val = r_int_bcd[idx2][3:0];
                                default: digit_val = 4'd0;
                            endcase
                            sym[s] = digit_val;
                        end
                        else begin
                            // 소수부 자리
                            k = t - (sign_cur ? 1 : 0) - int_len_cur; // 0..frac_len_cur-1
                            if (k >= 0 && k < frac_len_cur) begin
                                case (k)
                                    0: digit_val = r_frac_bcd[idx2][11:8];
                                    1: digit_val = r_frac_bcd[idx2][7:4];
                                    2: digit_val = r_frac_bcd[idx2][3:0];
                                    default: digit_val = 4'd0;
                                endcase
                                sym[s] = digit_val;
                            end
                        end
                    end
                end

                // 소수점 위치: 마지막 정수 자리의 디지트에 DP ON
                if (dp_flag_cur && (int_len_cur > 0)) begin
                    t_dp = (sign_cur ? 1 : 0) + int_len_cur - 1;
                    s_dp = width - 1 - t_dp;
                    if (s_dp >= 0 && s_dp < 8)
                        dp_local[7 - s_dp] = 1'b1;
                end
            end

            // sym[] -> o_bcd8d 매핑
            o_bcd8d[31:28] = sym[7];
            o_bcd8d[27:24] = sym[6];
            o_bcd8d[23:20] = sym[5];
            o_bcd8d[19:16] = sym[4];
            o_bcd8d[15:12] = sym[3];
            o_bcd8d[11:8]  = sym[2];
            o_bcd8d[7:4]   = sym[1];
            o_bcd8d[3:0]   = sym[0];

            o_dp_mask      = dp_local;
        end
        else begin
            //------------------------------------------------------
            // FFT 결과 표시 모드
            //   - bin_to_bcd7에서 계산된 disp_bcd7 사용
            //   - ±iiii.fff 형식 (4자리 정수 + 3자리 소수)
            //------------------------------------------------------
            o_bcd8d[31:28] = disp_sign ? 4'hA : 4'hB;      // '-' 또는 blank
            o_bcd8d[27:24] = disp_bcd7[27:24]; // d6 (천의 자리)
            o_bcd8d[23:20] = disp_bcd7[23:20]; // d5
            o_bcd8d[19:16] = disp_bcd7[19:16]; // d4
            o_bcd8d[15:12] = disp_bcd7[15:12]; // d3
            o_bcd8d[11:8]  = disp_bcd7[11:8];  // d2
            o_bcd8d[7:4]   = disp_bcd7[7:4];   // d1
            o_bcd8d[3:0]   = disp_bcd7[3:0];   // d0

            // 소수점 위치: 정수 4자리 뒤 (digit3)
            o_dp_mask      = 8'b0001_0000;
        end
    end

    //-------------------------------------------
    // o_index: 현재 인덱스 표시 (active-low)
    //-------------------------------------------
    wire [2:0] w_cur_index = (r_mode == MODE_OUTPUT) ? r_cur_bin : r_cur_sample;
    assign o_index = ~(8'b0000_0001 << w_cur_index);

    //-------------------------------------------
    // 상태 플래그: o_FFT, o_re_im
    //-------------------------------------------
    always @* begin
        case (r_mode)
            MODE_INPUT: begin
                o_FFT   = 1'b1;  // FFT 전 입력 단계
                o_re_im = 1'b1;  // 입력 단계에서는 항상 1(실수)
            end
            MODE_WAIT_FFT: begin
                o_FFT   = 1'b0;  // FFT 연산 중
                o_re_im = 1'b1;  // 아직 결과 표시 전이므로 실수 기준
            end
            MODE_OUTPUT: begin
                o_FFT   = 1'b0;  // FFT 결과 표시 단계
                o_re_im = (r_show_imag == 1'b0) ? 1'b1 : 1'b0; // real=1, imag=0
            end
            default: begin
                o_FFT   = 1'b1;
                o_re_im = 1'b1;
            end
        endcase
    end

endmodule
