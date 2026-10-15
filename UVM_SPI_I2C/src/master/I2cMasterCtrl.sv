/*
[MODULE_INFO_START]
Name: I2cMasterCtrl
Role: High-level control-State machine for the I2C master subsystem
Summary:
  - Executes START, address, data, repeated-START, and STOP phases for single-byte register transactions
  - Keeps the protocol FSM separate from the byte-oriented datapath and open-drain IO adapter
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module I2cMasterCtrl (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iTxnStart,
  input  logic       iTxnRw,
  input  logic [7:0] iTxnRegAddr,
  input  logic [7:0] iTxnWrData,
  input  logic       iTick,
  input  logic       iSclSync,
  input  logic       iSdaSync,
  input  logic       iTxBit,
  input  logic       iLastBit,
  input  logic       iAckBit,
  output logic       oDivEnable,
  output logic       oBusy,
  output logic       oDone,
  output logic       oSclLevel,
  output logic       oSdaDriveLow,
  output logic       oLoadTxByte,
  output logic [7:0] oTxByte,
  output logic       oClearBitCnt,
  output logic       oTxAdvance,
  output logic       oRxSample,
  output logic       oCaptureAck
);

  import serial_protocol_pkg::*;

  typedef enum logic [2:0] {
    DEVADDR_W,
    REGADDR,
    WRITE_DATA,
    DEVADDR_R,
    READ_DATA
  } phase_e;

  typedef enum logic [2:0] {
    IDLE,
    START,
    ADDR,
    DATA,
    STOP
  } state_e;

  state_e State, State_d;
  phase_e Phase, Phase_d;
  logic [1:0]        StartStep, StartStep_d;
  logic              StartRepeated, StartRepeated_d;
  logic              AckPhase, AckPhase_d;
  logic              TxnRwLatched, TxnRwLatched_d;
  logic [7:0]        RegAddrLatched, RegAddrLatched_d;
  logic [7:0]        WrDataLatched, WrDataLatched_d;
  logic              SclLevel, SclLevel_d;
  logic              SdaDriveLow, SdaDriveLow_d;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      State          <= IDLE;
      Phase          <= DEVADDR_W;
      StartStep      <= '0;
      StartRepeated  <= 1'b0;
      AckPhase       <= 1'b0;
      TxnRwLatched   <= 1'b0;
      RegAddrLatched <= '0;
      WrDataLatched  <= '0;
      SclLevel       <= 1'b1;
      SdaDriveLow    <= 1'b0;
    end else begin
      State          <= State_d;
      Phase          <= Phase_d;
      StartStep      <= StartStep_d;
      StartRepeated  <= StartRepeated_d;
      AckPhase       <= AckPhase_d;
      TxnRwLatched   <= TxnRwLatched_d;
      RegAddrLatched <= RegAddrLatched_d;
      WrDataLatched  <= WrDataLatched_d;
      SclLevel       <= SclLevel_d;
      SdaDriveLow    <= SdaDriveLow_d;
    end
  end

  always_comb begin
    State_d          = State;
    Phase_d          = Phase;
    StartStep_d      = StartStep;
    StartRepeated_d  = StartRepeated;
    AckPhase_d       = AckPhase;
    TxnRwLatched_d   = TxnRwLatched;
    RegAddrLatched_d = RegAddrLatched;
    WrDataLatched_d  = WrDataLatched;
    SclLevel_d       = SclLevel;
    SdaDriveLow_d    = SdaDriveLow;

    unique case (State)
      IDLE: begin
        SclLevel_d    = 1'b1;
        SdaDriveLow_d = 1'b0;
        if (iTxnStart) begin
          State_d          = START;
          Phase_d          = DEVADDR_W;
          StartStep_d      = 2'd0;
          StartRepeated_d  = 1'b0;
          AckPhase_d       = 1'b0;
          TxnRwLatched_d   = iTxnRw;
          RegAddrLatched_d = iTxnRegAddr;
          WrDataLatched_d  = iTxnWrData;
          SclLevel_d       = 1'b1;
          SdaDriveLow_d    = 1'b1;
        end
      end

      START: begin
        if (!StartRepeated) begin
          SclLevel_d    = 1'b1;
          SdaDriveLow_d = 1'b1;
          if (iTick) begin
            SclLevel_d    = 1'b0;
            SdaDriveLow_d = 1'b1;
            AckPhase_d    = 1'b0;
            StartStep_d   = 2'd0;
            State_d       = ADDR;
          end
        end else begin
          unique case (StartStep)
            2'd0: begin
              SclLevel_d    = 1'b0;
              SdaDriveLow_d = 1'b0;
              if (iTick) begin
                SclLevel_d  = 1'b1;
                StartStep_d = 2'd1;
              end
            end

            2'd1: begin
              SclLevel_d    = 1'b1;
              SdaDriveLow_d = 1'b0;
              if (iSclSync) begin
                SdaDriveLow_d = 1'b1;
              end
              if (iTick && iSclSync) begin
                StartStep_d = 2'd2;
              end
            end

            2'd2: begin
              SclLevel_d    = 1'b1;
              SdaDriveLow_d = 1'b1;
              if (iTick) begin
                SclLevel_d      = 1'b0;
                StartRepeated_d = 1'b0;
                StartStep_d     = 2'd0;
                AckPhase_d      = 1'b0;
                State_d         = ADDR;
                Phase_d         = DEVADDR_R;
              end
            end

            default: begin
              StartStep_d = 2'd0;
            end
          endcase
        end
      end

      ADDR,
      DATA: begin
        if (!AckPhase) begin
          if (Phase == READ_DATA) begin
            SdaDriveLow_d = 1'b0;
          end else begin
            SdaDriveLow_d = !iTxBit;
          end

          if (iTick) begin
            if (!SclLevel) begin
              SclLevel_d = 1'b1;
            end else if (iSclSync) begin
              SclLevel_d = 1'b0;
              if (iLastBit) begin
                AckPhase_d = 1'b1;
              end
            end
          end
        end else begin
          SdaDriveLow_d = 1'b0;

          if (iTick) begin
            if (!SclLevel) begin
              SclLevel_d = 1'b1;
            end else if (iSclSync) begin
              SclLevel_d = 1'b0;

              if (Phase == READ_DATA) begin
                State_d       = STOP;
                SdaDriveLow_d = 1'b1;
              end else if (!iSdaSync) begin
                unique case (Phase)
                  DEVADDR_W: begin
                    Phase_d    = REGADDR;
                    AckPhase_d = 1'b0;
                    State_d    = ADDR;
                  end

                  REGADDR: begin
                    AckPhase_d = 1'b0;
                    if (TxnRwLatched) begin
                      State_d         = START;
                      Phase_d         = DEVADDR_R;
                      StartRepeated_d = 1'b1;
                      StartStep_d     = 2'd0;
                      SdaDriveLow_d   = 1'b0;
                      SclLevel_d      = 1'b0;
                    end else begin
                      Phase_d    = WRITE_DATA;
                      State_d    = DATA;
                    end
                  end

                  WRITE_DATA: begin
                    State_d       = STOP;
                    SdaDriveLow_d = 1'b1;
                  end

                  DEVADDR_R: begin
                    Phase_d    = READ_DATA;
                    AckPhase_d = 1'b0;
                    State_d    = DATA;
                  end

                  default: begin
                    State_d       = STOP;
                    SdaDriveLow_d = 1'b1;
                  end
                endcase
              end else begin
                State_d       = STOP;
                SdaDriveLow_d = 1'b1;
              end
            end
          end
        end
      end

      STOP: begin
        if (!SclLevel) begin
          SdaDriveLow_d = 1'b1;
          if (iTick) begin
            SclLevel_d = 1'b1;
          end
        end else begin
          SdaDriveLow_d = 1'b1;
          if (iTick && iSclSync) begin
            SdaDriveLow_d = 1'b0;
            State_d       = IDLE;
          end
        end
      end

      default: begin
        State_d       = IDLE;
        SclLevel_d    = 1'b1;
        SdaDriveLow_d = 1'b0;
      end
    endcase
  end

  always_comb begin
    oDivEnable    = (State != IDLE);
    oBusy         = (State != IDLE);
    oDone         = 1'b0;
    oSclLevel     = SclLevel;
    oSdaDriveLow  = SdaDriveLow;
    oLoadTxByte   = 1'b0;
    oTxByte       = 8'h00;
    oClearBitCnt  = 1'b0;
    oTxAdvance    = 1'b0;
    oRxSample     = 1'b0;
    oCaptureAck   = 1'b0;

    unique case (State)
      IDLE: begin
        oSclLevel    = 1'b1;
        oSdaDriveLow = 1'b0;
      end

      START: begin
        if (!StartRepeated) begin
          oSclLevel    = 1'b1;
          oSdaDriveLow = 1'b1;
          if (iTick) begin
            oLoadTxByte  = 1'b1;
            oClearBitCnt = 1'b1;
            oTxByte      = {LP_I2C_DEV_ADDR, 1'b0};
          end
        end else begin
          unique case (StartStep)
            2'd0: begin
              oSclLevel    = 1'b0;
              oSdaDriveLow = 1'b0;
            end

            2'd1: begin
              oSclLevel    = 1'b1;
              oSdaDriveLow = iSclSync;
            end

            2'd2: begin
              oSclLevel    = 1'b1;
              oSdaDriveLow = 1'b1;
              if (iTick) begin
                oLoadTxByte  = 1'b1;
                oClearBitCnt = 1'b1;
                oTxByte      = {LP_I2C_DEV_ADDR, 1'b1};
              end
            end

            default: begin
              oSclLevel    = 1'b0;
              oSdaDriveLow = 1'b0;
            end
          endcase
        end
      end

      ADDR,
      DATA: begin
        if (!AckPhase) begin
          if (Phase == READ_DATA) begin
            oSdaDriveLow = 1'b0;
          end else begin
            oSdaDriveLow = !iTxBit;
          end

          if (iTick && SclLevel && iSclSync) begin
            if (Phase == READ_DATA) begin
              oRxSample = 1'b1;
            end else begin
              oTxAdvance = 1'b1;
            end
          end
        end else begin
          oSdaDriveLow = 1'b0;
          if (iTick && SclLevel && iSclSync) begin
            if (Phase == READ_DATA) begin
            end else begin
              oCaptureAck = 1'b1;
              if (!iSdaSync) begin
                unique case (Phase)
                  DEVADDR_W: begin
                    oLoadTxByte  = 1'b1;
                    oClearBitCnt = 1'b1;
                    oTxByte      = RegAddrLatched;
                  end

                  REGADDR: begin
                    if (!TxnRwLatched) begin
                      oLoadTxByte  = 1'b1;
                      oClearBitCnt = 1'b1;
                      oTxByte      = WrDataLatched;
                    end
                  end

                  DEVADDR_R: begin
                    oClearBitCnt = 1'b1;
                  end

                  default: begin
                  end
                endcase
              end
            end
          end
        end
      end

      STOP: begin
        if (SclLevel && iSclSync && iTick) begin
          oDone = 1'b1;
        end
      end

      default: begin
        oSclLevel    = 1'b1;
        oSdaDriveLow = 1'b0;
      end
    endcase
  end

endmodule
