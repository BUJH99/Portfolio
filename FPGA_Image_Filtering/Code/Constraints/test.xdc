# =============================================================================
# 0. FPGA Configuration Settings
# =============================================================================
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

# =============================================================================
# 1. System Clock & Reset (Internal Zynq Connection - Commented Out)
# =============================================================================
# iClk, iRstn은 Zynq 내부에서 연결되므로 주석 유지
#set_property PACKAGE_PIN D7 [get_ports iClk]
#set_property IOSTANDARD LVCMOS18 [get_ports iClk]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets iClk]

#set_property PACKAGE_PIN F8 [get_ports iRstn]
#set_property IOSTANDARD LVCMOS12 [get_ports iRstn]


# =============================================================================
# 5. Mode Selection Input (Internal AXI GPIO - Commented Out)
# =============================================================================
# iFilterMode는 AXI GPIO를 통해 제어되므로 주석 유지
#set_property PACKAGE_PIN E6 [get_ports {iFilterMode[0]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {iFilterMode[0]}]

#set_property PACKAGE_PIN G6 [get_ports {iFilterMode[1]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {iFilterMode[1]}]


# =============================================================================
# 2. TFT LCD Control Signals
# =============================================================================
# Direct TOP port names
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN G1 [get_ports oLcdClk]
set_property PACKAGE_PIN E4 [get_ports oLcdHSync]
set_property PACKAGE_PIN F1 [get_ports oLcdVSync]
set_property PACKAGE_PIN E3 [get_ports oLcdDe]
set_property PACKAGE_PIN E1 [get_ports oLcdBacklight]

# 전압 설정 유지 (LVCMOS12)
set_property IOSTANDARD LVCMOS12 [get_ports oLcdClk]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdHSync]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdVSync]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdDe]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdBacklight]


# =============================================================================
# 3. TFT LCD RGB Data Signals (RGB565)
# =============================================================================
# Direct TOP port names
# -----------------------------------------------------------------------------

# --- Red Channel (5 bits) ---
set_property PACKAGE_PIN R3 [get_ports {oLcdR[4]}]
set_property PACKAGE_PIN U2 [get_ports {oLcdR[3]}]
set_property PACKAGE_PIN U1 [get_ports {oLcdR[2]}]
set_property PACKAGE_PIN T3 [get_ports {oLcdR[1]}]
set_property PACKAGE_PIN T2 [get_ports {oLcdR[0]}]

# --- Green Channel (6 bits) ---
set_property PACKAGE_PIN M1 [get_ports {oLcdG[5]}]
set_property PACKAGE_PIN M5 [get_ports {oLcdG[4]}]
set_property PACKAGE_PIN M4 [get_ports {oLcdG[3]}]
set_property PACKAGE_PIN L2 [get_ports {oLcdG[2]}]
set_property PACKAGE_PIN L1 [get_ports {oLcdG[1]}]
set_property PACKAGE_PIN P3 [get_ports {oLcdG[0]}]

# --- Blue Channel (5 bits) ---
set_property PACKAGE_PIN N2 [get_ports {oLcdB[4]}]
set_property PACKAGE_PIN P1 [get_ports {oLcdB[3]}]
set_property PACKAGE_PIN N5 [get_ports {oLcdB[2]}]
set_property PACKAGE_PIN N4 [get_ports {oLcdB[1]}]
set_property PACKAGE_PIN M2 [get_ports {oLcdB[0]}]

###### OV5640 CIS Camera Pins 
set_property PACKAGE_PIN G5 [get_ports iCamPclk]
#set_property PACKAGE_PIN D7 [get_ports iCamPclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets iCamPclk]

set_property PACKAGE_PIN A7 [get_ports oCamPwdn]
set_property PACKAGE_PIN A6 [get_ports oCamResetn]
set_property PACKAGE_PIN E6 [get_ports ioCamSccbScl]
set_property PACKAGE_PIN G6 [get_ports ioCamSccbSda]
set_property PACKAGE_PIN F7 [get_ports iCamHsync]
set_property PACKAGE_PIN G7 [get_ports iCamVsync]
set_property PACKAGE_PIN G5 [get_ports iCamPclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets iCamPclk]
set_property PACKAGE_PIN F6 [get_ports oCamMclk]
set_property PACKAGE_PIN E5 [get_ports {iCamData[0]}]
set_property PACKAGE_PIN D6 [get_ports {iCamData[1]}]
set_property PACKAGE_PIN D5 [get_ports {iCamData[2]}]
set_property PACKAGE_PIN C7 [get_ports {iCamData[3]}]
set_property PACKAGE_PIN B6 [get_ports {iCamData[4]}]
set_property PACKAGE_PIN C5 [get_ports {iCamData[5]}]
set_property PACKAGE_PIN E8 [get_ports {iCamData[6]}]
set_property PACKAGE_PIN D8 [get_ports {iCamData[7]}]
#set_property IOSTANDARD LVCMOS18 [get_ports iCamPclk]
#set_property IOSTANDARD LVCMOS18 [get_ports oCamPwdn]
#set_property IOSTANDARD LVCMOS18 [get_ports oCamResetn]
#set_property IOSTANDARD LVCMOS18 [get_ports ioCamSccbScl]
#set_property IOSTANDARD LVCMOS18 [get_ports ioCamSccbSda]
#set_property IOSTANDARD LVCMOS18 [get_ports {iCamData[*]}]
#set_property IOSTANDARD LVCMOS18 [get_ports iCamHsync]
#set_property IOSTANDARD LVCMOS18 [get_ports iCamVsync]
#set_property IOSTANDARD LVCMOS18 [get_ports oCamMclk]

# =============================================================================
# 4. Bank Voltage / IOSTANDARD 설정
# =============================================================================
# Bank 26 : 1.8V (주요 데이터 핀들)
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 26]]

# Bank 65 : 1.2V (클럭/HS/VS/DE/Reset 등 일부 제어핀)
set_property IOSTANDARD LVCMOS12 [get_ports -of_objects [get_iobanks 65]]