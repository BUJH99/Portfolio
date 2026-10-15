`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFT8CoreCtrl
// description: Moore FSM controller for FFT8 input latch, datapath run, and output latch phases.
// [MODULE_INFO_END]
module FFT8CoreCtrl (
    input  logic iClk,
    input  logic iRstn,
    input  logic iStart,

    output logic oInputLatchEn,
    output logic oOutputLatchEn,
    output logic oBusy,
    output logic oDone
);

    typedef enum logic [1:0] {
        IDLE,
        LATCH,
        RUN,
        DONE
    } state_e;

    state_e State;
    state_e State_d;

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            State <= IDLE;
        end else begin
            State <= State_d;
        end
    end

    always_comb begin
        State_d = State;

        unique case (State)
            IDLE: begin
                if (iStart) begin
                    State_d = LATCH;
                end
            end

            LATCH: begin
                State_d = RUN;
            end

            RUN: begin
                State_d = DONE;
            end

            DONE: begin
                State_d = IDLE;
            end

            default: begin
                State_d = IDLE;
            end
        endcase
    end

    always_comb begin
        oInputLatchEn  = 1'b0;
        oOutputLatchEn = 1'b0;
        oBusy          = 1'b0;
        oDone          = 1'b0;

        unique case (State)
            IDLE: begin
            end

            LATCH: begin
                oInputLatchEn = 1'b1;
                oBusy         = 1'b1;
            end

            RUN: begin
                oOutputLatchEn = 1'b1;
                oBusy          = 1'b1;
            end

            DONE: begin
                oDone = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
