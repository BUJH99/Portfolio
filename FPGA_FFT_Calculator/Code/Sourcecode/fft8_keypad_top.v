//------------------------------------------------------------------------------
// Top: 키패드 FFT 시스템
//   - o_index : 현재 인덱스 (active-low)
//   - o_FFT   : 입력 단계(1) / FFT 계산/결과 단계(0)
//   - o_re_im : 실수(1) / 허수(0), 입력 단계에서는 1
//------------------------------------------------------------------------------
module fft8_keypad_top (
    input  wire        i_rstn,
    input  wire        i_clk,

    input  wire [4:0]  i_key_in,
    output wire [3:0]  o_key_out,

    output wire [7:0]  o_seg_com,
    output wire [7:0]  o_seg_d,

    output wire [7:0]  o_index,
    output wire        o_FFT,
    output wire        o_re_im
);

    // 1ms pulse
    wire w_pls_1k;
    clk_pls u_clk_pls (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),
        .o_pls_1k(w_pls_1k)
    );

    // 키 스캔
    wire [4:0] w_key_value;
    wire       w_key_valid;

    key_scan u_key_scan (
        .i_rstn      (i_rstn),
        .i_clk       (i_clk),
        .i_pls_1k    (w_pls_1k),
        .i_key_in    (i_key_in),
        .o_key_out   (o_key_out),
        .o_key_valid (w_key_valid),
        .o_key_value (w_key_value)
    );

    // 키 디코더
    wire w_is_digit;
    wire [3:0] w_digit;
    wire w_is_minus;
    wire w_is_dot;
    wire w_is_del;
    wire w_is_next;
    wire w_is_prev;
    wire w_is_toggle_ri;
    wire w_is_ent;
    wire w_is_esc;

    keycode_decoder u_keycode_decoder (
        .i_key_value    (w_key_value),

        .o_is_digit     (w_is_digit),
        .o_digit        (w_digit),

        .o_is_minus     (w_is_minus),
        .o_is_dot       (w_is_dot),
        .o_is_del       (w_is_del),
        .o_is_next      (w_is_next),
        .o_is_prev      (w_is_prev),
        .o_is_toggle_ri (w_is_toggle_ri),
        .o_is_ent       (w_is_ent),
        .o_is_esc       (w_is_esc)
    );

    // FFT UI <-> FFT 코어 연결
    wire               w_fft_start;
    wire               w_fft_busy;
    wire               w_fft_done;

    wire signed [20:0] w_x0, w_x1, w_x2, w_x3, w_x4, w_x5, w_x6, w_x7;
    wire signed [31:0] w_X0_re, w_X0_im;
    wire signed [31:0] w_X1_re, w_X1_im;
    wire signed [31:0] w_X2_re, w_X2_im;
    wire signed [31:0] w_X3_re, w_X3_im;
    wire signed [31:0] w_X4_re, w_X4_im;
    wire signed [31:0] w_X5_re, w_X5_im;
    wire signed [31:0] w_X6_re, w_X6_im;
    wire signed [31:0] w_X7_re, w_X7_im;

    wire [31:0] w_bcd8d;
    wire [7:0]  w_dp_mask;
    wire [7:0]  w_index;
    wire        w_FFT;
    wire        w_re_im;

    // FFT UI 컨트롤러
    fft_ui_ctrl u_fft_ui_ctrl (
        .i_clk          (i_clk),
        .i_rstn         (i_rstn),
        .i_pls_1k       (w_pls_1k),

        .i_key_valid    (w_key_valid),
        .i_is_digit     (w_is_digit),
        .i_digit        (w_digit),
        .i_is_minus     (w_is_minus),
        .i_is_dot       (w_is_dot),
        .i_is_del       (w_is_del),
        .i_is_next      (w_is_next),
        .i_is_prev      (w_is_prev),
        .i_is_toggle_ri (w_is_toggle_ri),
        .i_is_ent       (w_is_ent),
        .i_is_esc       (w_is_esc),

        .o_fft_start    (w_fft_start),
        .i_fft_busy     (w_fft_busy),
        .i_fft_done     (w_fft_done),

        .o_x0           (w_x0),
        .o_x1           (w_x1),
        .o_x2           (w_x2),
        .o_x3           (w_x3),
        .o_x4           (w_x4),
        .o_x5           (w_x5),
        .o_x6           (w_x6),
        .o_x7           (w_x7),

        .i_X0_re        (w_X0_re), .i_X0_im(w_X0_im),
        .i_X1_re        (w_X1_re), .i_X1_im(w_X1_im),
        .i_X2_re        (w_X2_re), .i_X2_im(w_X2_im),
        .i_X3_re        (w_X3_re), .i_X3_im(w_X3_im),
        .i_X4_re        (w_X4_re), .i_X4_im(w_X4_im),
        .i_X5_re        (w_X5_re), .i_X5_im(w_X5_im),
        .i_X6_re        (w_X6_re), .i_X6_im(w_X6_im),
        .i_X7_re        (w_X7_re), .i_X7_im(w_X7_im),

        .o_bcd8d        (w_bcd8d),
        .o_dp_mask      (w_dp_mask),

        .o_index        (w_index),
        .o_FFT          (w_FFT),
        .o_re_im        (w_re_im)
    );

    // FFT 코어
    fft8_core u_fft8_core (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),
        .i_start (w_fft_start),

        .i_x0    (w_x0),
        .i_x1    (w_x1),
        .i_x2    (w_x2),
        .i_x3    (w_x3),
        .i_x4    (w_x4),
        .i_x5    (w_x5),
        .i_x6    (w_x6),
        .i_x7    (w_x7),

        .o_busy  (w_fft_busy),
        .o_done  (w_fft_done),

        .o_X0_re (w_X0_re), .o_X0_im (w_X0_im),
        .o_X1_re (w_X1_re), .o_X1_im (w_X1_im),
        .o_X2_re (w_X2_re), .o_X2_im (w_X2_im),
        .o_X3_re (w_X3_re), .o_X3_im (w_X3_im),
        .o_X4_re (w_X4_re), .o_X4_im (w_X4_im),
        .o_X5_re (w_X5_re), .o_X5_im (w_X5_im),
        .o_X6_re (w_X6_re), .o_X6_im (w_X6_im),
        .o_X7_re (w_X7_re), .o_X7_im (w_X7_im)
    );

    // 7-Segment
    seg8digit u_seg8digit (
        .i_rstn    (i_rstn),
        .i_clk     (i_clk),
        .i_pls_1k  (w_pls_1k),
        .i_bcd8d   (w_bcd8d),
        .i_dp_mask (w_dp_mask),
        .o_seg_d   (o_seg_d),
        .o_seg_com (o_seg_com)
    );

    // 상태 신호 외부로
    assign o_index = w_index;
    assign o_FFT   = w_FFT;
    assign o_re_im = w_re_im;

endmodule
