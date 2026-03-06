// ============================================================================
// (Xi − Xmax) + 16비트 포화 (Q7.8)
// ============================================================================
module q78_sub_sat(
    input  wire signed [15:0] xi,
    input  wire signed [15:0] xmax,
    output reg  signed [15:0] y
);
    reg signed [16:0] diff;
    always @* begin
        diff = $signed(xi) - $signed(xmax);
        if      (diff >  17'sd32767)  y = 16'sd32767;
        else if (diff < -17'sd32768)  y = -16'sd32768;
        else                          y = diff[15:0];
    end
endmodule
