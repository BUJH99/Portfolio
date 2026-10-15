/*
[MODULE_INFO_START]
Name: MasterSequencer
Role: High-level polling controller for the Master project
Summary:
  - Launches a write to register 0x01 followed by a read from register 0x02 every time the sticky poll timer expires
  - Updates the mirrored LED payload only after a full write/read transaction pair completes
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module MasterSequencer (
  input  logic               iClk,
  input  logic               iRst,
  input  logic               iTimerExpired,
  input  serial_protocol_pkg::protocol_e iProtocolSel,
  input  logic [7:0]         iWriteData,
  input  logic               iTxnDone,
  input  logic [7:0]         iTxnRdData,
  output logic               oTimerClr,
  output logic               oCmdLoad,
  output logic               oTxnStart,
  output logic               oTxnRw,
  output logic [7:0]         oTxnRegAddr,
  output logic [7:0]         oTxnWrData,
  output serial_protocol_pkg::protocol_e oTxnProtocol,
  output logic [6:0]         oLedMirror,
  output logic               oBusy
);

  import serial_protocol_pkg::*;

  typedef enum logic [2:0] {
    IDLE,
    WRITE_REQ,
    WRITE_WAIT,
    READ_REQ,
    READ_WAIT,
    COMMIT
  } state_e;

  state_e State, State_d;
  logic [7:0]        ReadbackData, ReadbackData_d;
  logic [6:0]        LedMirror, LedMirror_d;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      State        <= IDLE;
      ReadbackData <= '0;
      LedMirror    <= '0;
    end else begin
      State        <= State_d;
      ReadbackData <= ReadbackData_d;
      LedMirror    <= LedMirror_d;
    end
  end

  always_comb begin
    State_d        = State;
    ReadbackData_d = ReadbackData;
    LedMirror_d    = LedMirror;

    unique case (State)
      IDLE: begin
        if (iTimerExpired) begin
          State_d = WRITE_REQ;
        end
      end

      WRITE_REQ: begin
        State_d = WRITE_WAIT;
      end

      WRITE_WAIT: begin
        if (iTxnDone) begin
          State_d = READ_REQ;
        end
      end

      READ_REQ: begin
        State_d = READ_WAIT;
      end

      READ_WAIT: begin
        if (iTxnDone) begin
          ReadbackData_d = iTxnRdData;
          State_d        = COMMIT;
        end
      end

      COMMIT: begin
        LedMirror_d = ReadbackData[6:0];
        State_d     = IDLE;
      end

      default: begin
        State_d = IDLE;
      end
    endcase
  end

  always_comb begin
    oTimerClr    = 1'b0;
    oCmdLoad     = 1'b0;
    oTxnStart    = 1'b0;
    oTxnRw       = 1'b0;
    oTxnRegAddr  = '0;
    oTxnWrData   = '0;
    oTxnProtocol = iProtocolSel;
    oLedMirror   = LedMirror;
    oBusy        = (State != IDLE);

    unique case (State)
      IDLE: begin
        if (iTimerExpired) begin
          oCmdLoad = 1'b1;
        end
      end

      WRITE_REQ: begin
        oTxnStart   = 1'b1;
        oTxnRw      = 1'b0;
        oTxnRegAddr = LP_REG_WRITE;
        oTxnWrData  = iWriteData;
      end

      READ_REQ: begin
        oTxnStart   = 1'b1;
        oTxnRw      = 1'b1;
        oTxnRegAddr = LP_REG_READ;
        oTxnWrData  = 8'h00;
      end

      COMMIT: begin
        oTimerClr = 1'b1;
      end

      default: begin
      end
    endcase
  end

endmodule
