# Timing smoke constraint for internal STA.
# Replace or extend with board pin, IOSTANDARD, and I/O delay constraints
# before treating the build as bitstream/signoff ready.
create_clock -name iClk -period 10.000 [get_ports iClk]
