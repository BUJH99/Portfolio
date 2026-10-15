/*
[MODULE_INFO_START]
Name: I2cSlaveCtrl
Role: Synchronous control-State machine for the I2C slave subsystem
Summary:
  - Decodes START/STOP conditions, address bytes, register bytes, write data, and read-data transmit phases
  - Generates ACK timing and transaction-valid pulses entirely from synchronized edge pulses on the 100MHz system clock
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module I2cSlaveCtrl (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iStartPulse,
  input  logic       iStopPulse,
  input  logic       iSclRise,
  input  logic       iSclFall,
  input  logic [7:0] iRxByte,
  input  logic       iTxBit,
  input  logic       iLastBit,
  input  logic [7:0] iTxnReadData,
  output logic       oStartFrame,
  output logic       oLoadTxByte,
  output logic [7:0] oTxByte,
  output logic       oClearBitCnt,
  output logic       oSampleRxBit,
  output logic       oAdvanceTxBit,
  output logic       oSdaDriveLow,
  output logic       oTxnValid,
  output logic       oTxnWrite,
  output logic [7:0] oTxnAddr,
  output logic [7:0] oTxnWdata
);

  import serial_protocol_pkg::*;

  typedef enum logic [1:0] {
    DEVICE,
    REGADDR,
    WRITE_DATA,
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
  logic             AckPhase, AckPhase_d;
  logic             AckDriveLow, AckDriveLow_d;
  logic             TxMode, TxMode_d;
  logic             TxHold, TxHold_d;
  logic             BytePending, BytePending_d;
  logic [7:0]       RegAddr, RegAddr_d;
  logic             SdaDriveLow, SdaDriveLow_d;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      State        <= IDLE;
      Phase        <= DEVICE;
      AckPhase     <= 1'b0;
      AckDriveLow  <= 1'b0;
      TxMode       <= 1'b0;
      TxHold       <= 1'b0;
      BytePending  <= 1'b0;
      RegAddr      <= '0;
      SdaDriveLow  <= 1'b0;
    end else begin
      State        <= State_d;
      Phase        <= Phase_d;
      AckPhase     <= AckPhase_d;
      AckDriveLow  <= AckDriveLow_d;
      TxMode       <= TxMode_d;
      TxHold       <= TxHold_d;
      BytePending  <= BytePending_d;
      RegAddr      <= RegAddr_d;
      SdaDriveLow  <= SdaDriveLow_d;
    end
  end

  always_comb begin
    State_d       = State;
    Phase_d       = Phase;
    AckPhase_d    = AckPhase;
    AckDriveLow_d = AckDriveLow;
    TxMode_d      = TxMode;
    TxHold_d      = TxHold;
    BytePending_d = BytePending;
    RegAddr_d     = RegAddr;
    SdaDriveLow_d = SdaDriveLow;

    if (iStopPulse) begin
      State_d       = STOP;
      AckPhase_d    = 1'b0;
      AckDriveLow_d = 1'b0;
      TxMode_d      = 1'b0;
      TxHold_d      = 1'b0;
      BytePending_d = 1'b0;
      SdaDriveLow_d = 1'b0;
    end else if (iStartPulse) begin
      State_d       = START;
      Phase_d       = DEVICE;
      AckPhase_d    = 1'b0;
      AckDriveLow_d = 1'b0;
      TxMode_d      = 1'b0;
      TxHold_d      = 1'b0;
      BytePending_d = 1'b0;
      SdaDriveLow_d = 1'b0;
    end else begin
      unique case (State)
        IDLE: begin
          SdaDriveLow_d = 1'b0;
        end

        START: begin
          SdaDriveLow_d = 1'b0;
          State_d       = ADDR;
        end

        ADDR,
        DATA: begin
          if (!AckPhase) begin
            if (!TxMode) begin
              SdaDriveLow_d = 1'b0;

              if (iSclRise && iLastBit) begin
                BytePending_d = 1'b1;
              end

              if (iSclFall && BytePending) begin
                BytePending_d = 1'b0;

                unique case (Phase)
                  DEVICE: begin
                    if (iRxByte[7:1] == LP_I2C_DEV_ADDR) begin
                      AckPhase_d    = 1'b1;
                      AckDriveLow_d = 1'b1;

                      if (iRxByte[0]) begin
                        Phase_d  = READ_DATA;
                        TxMode_d = 1'b1;
                        TxHold_d = 1'b1;
                        State_d  = DATA;
                      end else begin
                        Phase_d  = REGADDR;
                        TxMode_d = 1'b0;
                        State_d  = ADDR;
                      end
                    end else begin
                      AckPhase_d    = 1'b1;
                      AckDriveLow_d = 1'b0;
                      TxMode_d      = 1'b0;
                      State_d       = IDLE;
                    end
                  end

                  REGADDR: begin
                    RegAddr_d      = iRxByte;
                    Phase_d        = WRITE_DATA;
                    AckPhase_d     = 1'b1;
                    AckDriveLow_d  = 1'b1;
                    State_d        = DATA;
                  end

                  default: begin
                    AckPhase_d     = 1'b1;
                    AckDriveLow_d  = 1'b1;
                    State_d        = DATA;
                  end
                endcase
              end
            end else begin
              SdaDriveLow_d = !iTxBit;

              if (iSclFall && iLastBit) begin
                AckPhase_d    = 1'b1;
                AckDriveLow_d = 1'b0;
              end
            end
          end else begin
            SdaDriveLow_d = AckDriveLow;

            if (iSclFall) begin
              AckPhase_d    = 1'b0;
              AckDriveLow_d = 1'b0;
              SdaDriveLow_d = 1'b0;

              if (Phase == READ_DATA) begin
                if (TxHold) begin
                  State_d  = DATA;
                  TxHold_d = 1'b0;
                end else begin
                  TxMode_d = 1'b0;
                  TxHold_d = 1'b0;
                  State_d  = STOP;
                end
              end else if (!AckDriveLow) begin
                TxMode_d = 1'b0;
                TxHold_d = 1'b0;
                State_d  = IDLE;
              end else if (Phase == DEVICE) begin
                if (TxMode) begin
                  State_d = DATA;
                end else begin
                  State_d = ADDR;
                end
              end else begin
                State_d = DATA;
              end
            end
          end
        end

        STOP: begin
          SdaDriveLow_d = 1'b0;
          State_d       = IDLE;
        end

        default: begin
          State_d       = IDLE;
          SdaDriveLow_d = 1'b0;
        end
      endcase
    end
  end

  always_comb begin
    oStartFrame   = 1'b0;
    oLoadTxByte   = 1'b0;
    oTxByte       = 8'h00;
    oClearBitCnt  = 1'b0;
    oSampleRxBit  = 1'b0;
    oAdvanceTxBit = 1'b0;
    oSdaDriveLow  = SdaDriveLow;
    oTxnValid     = 1'b0;
    oTxnWrite     = 1'b0;
    oTxnAddr      = RegAddr;
    oTxnWdata     = iRxByte;

    if (iStopPulse) begin
      oSdaDriveLow = 1'b0;
    end else if (iStartPulse) begin
      oStartFrame  = 1'b1;
      oClearBitCnt = 1'b1;
      oSdaDriveLow = 1'b0;
    end else begin
      unique case (State)
        START: begin
          oClearBitCnt = 1'b1;
          oSdaDriveLow = 1'b0;
        end

        ADDR,
        DATA: begin
          if (!AckPhase) begin
            if (!TxMode) begin
              oSdaDriveLow = 1'b0;

              if (iSclRise) begin
                oSampleRxBit = 1'b1;
              end

              if (iSclFall && BytePending) begin
                unique case (Phase)
                  DEVICE: begin
                    if ((iRxByte[7:1] == LP_I2C_DEV_ADDR) && iRxByte[0]) begin
                      oLoadTxByte = 1'b1;
                      oTxByte     = iTxnReadData;
                    end
                  end

                  WRITE_DATA: begin
                    oTxnValid = 1'b1;
                    oTxnWrite = 1'b1;
                  end

                  default: begin
                  end
                endcase
              end
            end else begin
              oSdaDriveLow = !iTxBit;
              if (iSclFall) begin
                oAdvanceTxBit = 1'b1;
              end
            end
          end else begin
            oSdaDriveLow = AckDriveLow;

            if (iSclFall) begin
              if (Phase == READ_DATA) begin
                if (TxHold) begin
                  oClearBitCnt = 1'b1;
                end
              end else if (AckDriveLow) begin
                oClearBitCnt = 1'b1;
              end
            end
          end
        end

        STOP: begin
          oSdaDriveLow = 1'b0;
        end

        default: begin
          oSdaDriveLow = SdaDriveLow;
        end
      endcase
    end
  end

endmodule
