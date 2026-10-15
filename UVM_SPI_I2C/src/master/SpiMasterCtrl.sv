/*
[MODULE_INFO_START]
Name: SpiMasterCtrl
Role: Control-State machine for the SPI master subsystem
Summary:
  - Drives the SPI Mode-0 START/DATA/STOP sequencing using divider ticks
  - Separates control strobes from the datapath so frame formatting remains outside the FSM
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module SpiMasterCtrl (
  input  logic iClk,
  input  logic iRst,
  input  logic iTxnStart,
  input  logic iTick,
  input  logic iBitsDone,
  output logic oDivEnable,
  output logic oCsActive,
  output logic oSclkLevel,
  output logic oLoadFrame,
  output logic oSampleRx,
  output logic oShiftTx,
  output logic oCaptureFrame,
  output logic oBusy,
  output logic oDone
);

  import serial_protocol_pkg::*;

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_e;

  state_e State, State_d;
  logic              SclkLevel, SclkLevel_d;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      State     <= IDLE;
      SclkLevel <= 1'b0;
    end else begin
      State     <= State_d;
      SclkLevel <= SclkLevel_d;
    end
  end

  always_comb begin
    State_d     = State;
    SclkLevel_d = SclkLevel;

    unique case (State)
      IDLE: begin
        SclkLevel_d = 1'b0;
        if (iTxnStart) begin
          State_d = START;
        end
      end

      START: begin
        SclkLevel_d = 1'b0;
        State_d     = DATA;
      end

      DATA: begin
        if (iTick) begin
          if (!SclkLevel) begin
            SclkLevel_d = 1'b1;
          end else begin
            SclkLevel_d = 1'b0;
            if (iBitsDone) begin
              State_d = STOP;
            end
          end
        end
      end

      STOP: begin
        SclkLevel_d = 1'b0;
        State_d     = IDLE;
      end

      default: begin
        State_d     = IDLE;
        SclkLevel_d = 1'b0;
      end
    endcase
  end

  always_comb begin
    oDivEnable    = 1'b0;
    oCsActive     = 1'b0;
    oSclkLevel    = SclkLevel;
    oLoadFrame    = 1'b0;
    oSampleRx     = 1'b0;
    oShiftTx      = 1'b0;
    oCaptureFrame = 1'b0;
    oBusy         = (State != IDLE);
    oDone         = 1'b0;

    unique case (State)
      IDLE: begin
        oSclkLevel = 1'b0;
        if (iTxnStart) begin
          oLoadFrame = 1'b1;
        end
      end

      START: begin
        oCsActive  = 1'b1;
        oSclkLevel = 1'b0;
      end

      DATA: begin
        oCsActive  = 1'b1;
        oDivEnable = 1'b1;
        if (iTick) begin
          if (!SclkLevel) begin
            oSampleRx = 1'b1;
          end else begin
            oShiftTx = 1'b1;
          end
        end
      end

      STOP: begin
        oSclkLevel    = 1'b0;
        oCaptureFrame = 1'b1;
        oDone         = 1'b1;
      end

      default: begin
        oSclkLevel = 1'b0;
      end
    endcase
  end

endmodule
