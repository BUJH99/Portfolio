`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: InputController
// description: Generates keypad scan timing, scans the keypad matrix, and decodes key events.
// [MODULE_INFO_END]
module InputController (
    input  logic       iClk,
    input  logic       iRstn,
    input  logic [4:0] iKeyIn,

    output logic [3:0] oKeyOut,
    output logic       oPulse1k,

    output logic       oKeyValid,
    output logic       oIsDigit,
    output logic [3:0] oDigit,
    output logic       oIsMinus,
    output logic       oIsDot,
    output logic       oIsDel,
    output logic       oIsNext,
    output logic       oIsPrev,
    output logic       oIsToggleRi,
    output logic       oIsEnt,
    output logic       oIsEsc
);

    logic [4:0] KeyValue;

    ClkPulse uClkPulse (
        .iClk     (iClk),
        .iRstn    (iRstn),
        .oPulse1k (oPulse1k)
    );

    KeyScan uKeyScan (
        .iRstn     (iRstn),
        .iClk      (iClk),
        .iPulse1k  (oPulse1k),
        .iKeyIn    (iKeyIn),
        .oKeyOut   (oKeyOut),
        .oKeyValid (oKeyValid),
        .oKeyValue (KeyValue)
    );

    KeycodeDecoder uKeycodeDecoder (
        .iKeyValue   (KeyValue),
        .oIsDigit    (oIsDigit),
        .oDigit      (oDigit),
        .oIsMinus    (oIsMinus),
        .oIsDot      (oIsDot),
        .oIsDel      (oIsDel),
        .oIsNext     (oIsNext),
        .oIsPrev     (oIsPrev),
        .oIsToggleRi (oIsToggleRi),
        .oIsEnt      (oIsEnt),
        .oIsEsc      (oIsEsc)
    );

endmodule
