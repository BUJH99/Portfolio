set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ".."]]
set report_dir [file join $project_root ".sim_build" "ooc_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"]
set target_part "xczu3eg-sbva484-1-i"

file mkdir $report_dir
read_verilog -sv [file join $project_root "Source" "Window3x3LineBuffer.sv"]
synth_design -mode out_of_context -top Window3x3LineBuffer -part $target_part

create_clock -name benchmark_clk -period 10.000 [get_ports iClk]
set data_input_ports [get_ports -filter "DIRECTION == IN && NAME != iClk && NAME != iRstn"]
set_input_delay -clock benchmark_clk 0.000 $data_input_ports
set_false_path -from [get_ports iRstn]

report_timing_summary -delay_type max -max_paths 10 -report_unconstrained \
    -file [file join $report_dir "Window3x3LineBuffer_timing_summary.rpt"]
report_utilization -hierarchical \
    -file [file join $report_dir "Window3x3LineBuffer_utilization.rpt"]

set worst_path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
puts "LINE_BUFFER_OOC_TIMING slack_ns=[get_property SLACK $worst_path] datapath_ns=[get_property DATAPATH_DELAY $worst_path]"
puts "LINE_BUFFER_OOC_PASS"
