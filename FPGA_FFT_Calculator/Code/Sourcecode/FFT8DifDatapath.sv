`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFT8DifDatapath
// description: Combinational 3-stage radix-2 DIF FFT datapath for 8 real-input samples.
// [MODULE_INFO_END]
module FFT8DifDatapath (
    input  logic signed [31:0] iSample0,
    input  logic signed [31:0] iSample1,
    input  logic signed [31:0] iSample2,
    input  logic signed [31:0] iSample3,
    input  logic signed [31:0] iSample4,
    input  logic signed [31:0] iSample5,
    input  logic signed [31:0] iSample6,
    input  logic signed [31:0] iSample7,

    output logic signed [31:0] oStage3Re0,
    output logic signed [31:0] oStage3Im0,
    output logic signed [31:0] oStage3Re1,
    output logic signed [31:0] oStage3Im1,
    output logic signed [31:0] oStage3Re2,
    output logic signed [31:0] oStage3Im2,
    output logic signed [31:0] oStage3Re3,
    output logic signed [31:0] oStage3Im3,
    output logic signed [31:0] oStage3Re4,
    output logic signed [31:0] oStage3Im4,
    output logic signed [31:0] oStage3Re5,
    output logic signed [31:0] oStage3Im5,
    output logic signed [31:0] oStage3Re6,
    output logic signed [31:0] oStage3Im6,
    output logic signed [31:0] oStage3Re7,
    output logic signed [31:0] oStage3Im7
);

    logic signed [31:0] Stage1Re [0:7];
    logic signed [31:0] Stage1Im [0:7];
    logic signed [31:0] Stage2Re [0:7];
    logic signed [31:0] Stage2Im [0:7];
    logic signed [31:0] Stage3Re [0:7];
    logic signed [31:0] Stage3Im [0:7];

    logic signed [31:0] URe;
    logic signed [31:0] UIm;
    logic signed [31:0] VRe;
    logic signed [31:0] VIm;
    logic signed [31:0] TempRe;
    logic signed [31:0] TempIm;
    logic signed [31:0] TwiddleRe;
    logic signed [31:0] TwiddleIm;

    integer idxStage;

    function automatic logic signed [31:0] MulInvSqrt2(
        input logic signed [31:0] Value
    );
        logic signed [31:0] Product;
        begin
            Product = (Value <<< 7)
                    + (Value <<< 5)
                    + (Value <<< 4)
                    + (Value <<< 2)
                    + Value;
            MulInvSqrt2 = Product >>> 8;
        end
    endfunction

    assign oStage3Re0 = Stage3Re[0];
    assign oStage3Im0 = Stage3Im[0];
    assign oStage3Re1 = Stage3Re[1];
    assign oStage3Im1 = Stage3Im[1];
    assign oStage3Re2 = Stage3Re[2];
    assign oStage3Im2 = Stage3Im[2];
    assign oStage3Re3 = Stage3Re[3];
    assign oStage3Im3 = Stage3Im[3];
    assign oStage3Re4 = Stage3Re[4];
    assign oStage3Im4 = Stage3Im[4];
    assign oStage3Re5 = Stage3Re[5];
    assign oStage3Im5 = Stage3Im[5];
    assign oStage3Re6 = Stage3Re[6];
    assign oStage3Im6 = Stage3Im[6];
    assign oStage3Re7 = Stage3Re[7];
    assign oStage3Im7 = Stage3Im[7];

    always_comb begin
        URe       = '0;
        UIm       = '0;
        VRe       = '0;
        VIm       = '0;
        TempRe    = '0;
        TempIm    = '0;
        TwiddleRe = '0;
        TwiddleIm = '0;

        for (idxStage = 0; idxStage < 8; idxStage = idxStage + 1) begin
            Stage1Re[idxStage] = '0;
            Stage1Im[idxStage] = '0;
            Stage2Re[idxStage] = '0;
            Stage2Im[idxStage] = '0;
            Stage3Re[idxStage] = '0;
            Stage3Im[idxStage] = '0;
        end

        Stage1Re[0] = iSample0 + iSample4;
        Stage1Im[0] = '0;
        TempRe      = iSample0 - iSample4;
        Stage1Re[4] = TempRe;
        Stage1Im[4] = '0;

        Stage1Re[1] = iSample1 + iSample5;
        Stage1Im[1] = '0;
        TempRe      = iSample1 - iSample5;
        TwiddleRe   = MulInvSqrt2(TempRe);
        TwiddleIm   = -TwiddleRe;
        Stage1Re[5] = TwiddleRe;
        Stage1Im[5] = TwiddleIm;

        Stage1Re[2] = iSample2 + iSample6;
        Stage1Im[2] = '0;
        TempRe      = iSample2 - iSample6;
        Stage1Re[6] = '0;
        Stage1Im[6] = -TempRe;

        Stage1Re[3] = iSample3 + iSample7;
        Stage1Im[3] = '0;
        TempRe      = iSample3 - iSample7;
        TwiddleRe   = MulInvSqrt2(TempRe);
        Stage1Re[7] = -TwiddleRe;
        Stage1Im[7] = -TwiddleRe;

        URe         = Stage1Re[0];
        UIm         = Stage1Im[0];
        VRe         = Stage1Re[2];
        VIm         = Stage1Im[2];
        Stage2Re[0] = URe + VRe;
        Stage2Im[0] = UIm + VIm;
        TempRe      = URe - VRe;
        TempIm      = UIm - VIm;
        Stage2Re[2] = TempRe;
        Stage2Im[2] = TempIm;

        URe         = Stage1Re[1];
        UIm         = Stage1Im[1];
        VRe         = Stage1Re[3];
        VIm         = Stage1Im[3];
        Stage2Re[1] = URe + VRe;
        Stage2Im[1] = UIm + VIm;
        TempRe      = URe - VRe;
        TempIm      = UIm - VIm;
        Stage2Re[3] = TempIm;
        Stage2Im[3] = -TempRe;

        URe         = Stage1Re[4];
        UIm         = Stage1Im[4];
        VRe         = Stage1Re[6];
        VIm         = Stage1Im[6];
        Stage2Re[4] = URe + VRe;
        Stage2Im[4] = UIm + VIm;
        TempRe      = URe - VRe;
        TempIm      = UIm - VIm;
        Stage2Re[6] = TempRe;
        Stage2Im[6] = TempIm;

        URe         = Stage1Re[5];
        UIm         = Stage1Im[5];
        VRe         = Stage1Re[7];
        VIm         = Stage1Im[7];
        Stage2Re[5] = URe + VRe;
        Stage2Im[5] = UIm + VIm;
        TempRe      = URe - VRe;
        TempIm      = UIm - VIm;
        Stage2Re[7] = TempIm;
        Stage2Im[7] = -TempRe;

        URe         = Stage2Re[0];
        UIm         = Stage2Im[0];
        VRe         = Stage2Re[1];
        VIm         = Stage2Im[1];
        Stage3Re[0] = URe + VRe;
        Stage3Im[0] = UIm + VIm;
        Stage3Re[1] = URe - VRe;
        Stage3Im[1] = UIm - VIm;

        URe         = Stage2Re[2];
        UIm         = Stage2Im[2];
        VRe         = Stage2Re[3];
        VIm         = Stage2Im[3];
        Stage3Re[2] = URe + VRe;
        Stage3Im[2] = UIm + VIm;
        Stage3Re[3] = URe - VRe;
        Stage3Im[3] = UIm - VIm;

        URe         = Stage2Re[4];
        UIm         = Stage2Im[4];
        VRe         = Stage2Re[5];
        VIm         = Stage2Im[5];
        Stage3Re[4] = URe + VRe;
        Stage3Im[4] = UIm + VIm;
        Stage3Re[5] = URe - VRe;
        Stage3Im[5] = UIm - VIm;

        URe         = Stage2Re[6];
        UIm         = Stage2Im[6];
        VRe         = Stage2Re[7];
        VIm         = Stage2Im[7];
        Stage3Re[6] = URe + VRe;
        Stage3Im[6] = UIm + VIm;
        Stage3Re[7] = URe - VRe;
        Stage3Im[7] = UIm - VIm;
    end

endmodule
