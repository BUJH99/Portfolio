/*
[MODULE_INFO_START]
Name: SpiSlaveCtrl
Role: Synchronous control-State machine for the SPI slave subsystem
Summary:
  - Waits for synchronized CS/SCLK edge pulses and converts them into datapath strobes
  - Emits a transaction-valid pulse only when a complete 16-bit frame is observed before CS deasserts
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module SpiSlaveCtrl (
  input  logic iClk,
  input  logic iRst,
  input  logic iCsFall,
  input  logic iCsRise,
  input  logic iSclkRise,
  input  logic iSclkFall,
  input  logic iFrameDone,
  output logic oStartFrame,
  output logic oSampleMosi,
  output logic oShiftMiso,
  output logic oTxnValid,
  output logic oBusy
);

  import serial_protocol_pkg::*;

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_e;

  state_e State, State_d;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      State <= IDLE;
    end else begin
      State <= State_d;
    end
  end

  always_comb begin
    State_d = State;

    unique case (State)
      IDLE: begin
        if (iCsFall) begin
          State_d = START;
        end
      end

      START: begin
        State_d = DATA;
      end

      DATA: begin
        if (iCsRise) begin
          State_d = STOP;
        end
      end

      STOP: begin
        State_d = IDLE;
      end

      default: begin
        State_d = IDLE;
      end
    endcase
  end

  always_comb begin
    oStartFrame = 1'b0;
    oSampleMosi = 1'b0;
    oShiftMiso  = 1'b0;
    oTxnValid   = 1'b0;
    oBusy       = (State != IDLE);

    unique case (State)
      IDLE: begin
        if (iCsFall) begin
          oStartFrame = 1'b1;
        end
      end

      DATA: begin
        if (iSclkRise) begin
          oSampleMosi = 1'b1;
        end
        if (iSclkFall) begin
          oShiftMiso = 1'b1;
        end
      end

      STOP: begin
        if (iFrameDone) begin
          oTxnValid = 1'b1;
        end
      end

      default: begin
      end
    endcase
  end

endmodule
