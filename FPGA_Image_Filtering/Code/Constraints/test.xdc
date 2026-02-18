# =============================================================================
# 0. FPGA Configuration Settings
# =============================================================================
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

# =============================================================================
# 1. System Clock & Reset (Internal Zynq Connection - Commented Out)
# =============================================================================
# iClk, iRst_n은 Zynq 내부에서 연결되므로 주석 유지
#set_property PACKAGE_PIN D7 [get_ports iClk]
#set_property IOSTANDARD LVCMOS18 [get_ports iClk]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets iClk]

#set_property PACKAGE_PIN F8 [get_ports iRst_n]
#set_property IOSTANDARD LVCMOS12 [get_ports iRst_n]


# =============================================================================
# 5. Mode Selection Input (Internal AXI GPIO - Commented Out)
# =============================================================================
# iMode는 AXI GPIO를 통해 제어되므로 주석 유지
#set_property PACKAGE_PIN E6 [get_ports {iMode[0]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {iMode[0]}]

#set_property PACKAGE_PIN G6 [get_ports {iMode[1]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {iMode[1]}]


# =============================================================================
# 2. TFT LCD Control Signals
# =============================================================================
# [수정됨] Wrapper 포트명에 맞춰 뒤에 '_0' 추가
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN G1 [get_ports oLcdClk_0]
set_property PACKAGE_PIN E4 [get_ports oLcdHSync_0]
set_property PACKAGE_PIN F1 [get_ports oLcdVSync_0]
set_property PACKAGE_PIN E3 [get_ports oLcdDe_0]
set_property PACKAGE_PIN E1 [get_ports oLcdBacklight_0]

# 전압 설정 유지 (LVCMOS12)
set_property IOSTANDARD LVCMOS12 [get_ports oLcdClk_0]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdHSync_0]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdVSync_0]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdDe_0]
set_property IOSTANDARD LVCMOS12 [get_ports oLcdBacklight_0]


# =============================================================================
# 3. TFT LCD RGB Data Signals (RGB565)
# =============================================================================
# [수정됨] Wrapper 포트명에 맞춰 뒤에 '_0' 추가
# -----------------------------------------------------------------------------

# --- Red Channel (5 bits) ---
set_property PACKAGE_PIN R3 [get_ports {oLcdR_0[4]}]
set_property PACKAGE_PIN U2 [get_ports {oLcdR_0[3]}]
set_property PACKAGE_PIN U1 [get_ports {oLcdR_0[2]}]
set_property PACKAGE_PIN T3 [get_ports {oLcdR_0[1]}]
set_property PACKAGE_PIN T2 [get_ports {oLcdR_0[0]}]

# --- Green Channel (6 bits) ---
set_property PACKAGE_PIN M1 [get_ports {oLcdG_0[5]}]
set_property PACKAGE_PIN M5 [get_ports {oLcdG_0[4]}]
set_property PACKAGE_PIN M4 [get_ports {oLcdG_0[3]}]
set_property PACKAGE_PIN L2 [get_ports {oLcdG_0[2]}]
set_property PACKAGE_PIN L1 [get_ports {oLcdG_0[1]}]
set_property PACKAGE_PIN P3 [get_ports {oLcdG_0[0]}]

# --- Blue Channel (5 bits) ---
set_property PACKAGE_PIN N2 [get_ports {oLcdB_0[4]}]
set_property PACKAGE_PIN P1 [get_ports {oLcdB_0[3]}]
set_property PACKAGE_PIN N5 [get_ports {oLcdB_0[2]}]
set_property PACKAGE_PIN N4 [get_ports {oLcdB_0[1]}]
set_property PACKAGE_PIN M2 [get_ports {oLcdB_0[0]}]

###### OV5640 CIS Camera Pins 
set_property PACKAGE_PIN G5 [get_ports CAM_PCLK_0]
#set_property PACKAGE_PIN D7 [get_ports CAM_PCLK]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CAM_PCLK_0]

set_property PACKAGE_PIN A7 [get_ports CAM_PWDN_0]
set_property PACKAGE_PIN A6 [get_ports CAM_RESETn_0]
set_property PACKAGE_PIN E6 [get_ports CAM_SCCB_SCL_0]
set_property PACKAGE_PIN G6 [get_ports CAM_SCCB_SDA_0]
set_property PACKAGE_PIN F7 [get_ports CAM_HSYNC_0]
set_property PACKAGE_PIN G7 [get_ports CAM_VSYNC_0]
set_property PACKAGE_PIN G5 [get_ports CAM_PCLK_0]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CAM_PCLK_0]
set_property PACKAGE_PIN F6 [get_ports CAM_MCLK_0]
set_property PACKAGE_PIN E5 [get_ports {CAM_DATA_0[0]}]
set_property PACKAGE_PIN D6 [get_ports {CAM_DATA_0[1]}]
set_property PACKAGE_PIN D5 [get_ports {CAM_DATA_0[2]}]
set_property PACKAGE_PIN C7 [get_ports {CAM_DATA_0[3]}]
set_property PACKAGE_PIN B6 [get_ports {CAM_DATA_0[4]}]
set_property PACKAGE_PIN C5 [get_ports {CAM_DATA_0[5]}]
set_property PACKAGE_PIN E8 [get_ports {CAM_DATA_0[6]}]
set_property PACKAGE_PIN D8 [get_ports {CAM_DATA_0[7]}]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_PCLK]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_PWDN]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_RESETn]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_SCCB_SCL]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_SCCB_SDA]
#set_property IOSTANDARD LVCMOS18 [get_ports {CAM_DATA[*]}]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_HSYNC]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_VSYNC]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_MCLK]

# =============================================================================
# 4. Bank Voltage / IOSTANDARD 설정
# =============================================================================
# Bank 26 : 1.8V (주요 데이터 핀들)
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 26]]

# Bank 65 : 1.2V (클럭/HS/VS/DE/Reset 등 일부 제어핀)
set_property IOSTANDARD LVCMOS12 [get_ports -of_objects [get_iobanks 65]]