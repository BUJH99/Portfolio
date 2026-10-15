set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ".."]]
set report_dir [file join $project_root ".sim_build" "ooc_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"]
set target_part "xczu3eg-sbva484-1-i"

file mkdir $report_dir

proc report_ooc_module {module_name source_files clock_port clock_period report_dir target_part} {
    foreach source_file $source_files {
        read_verilog -sv $source_file
    }

    synth_design -mode out_of_context -top $module_name -part $target_part
    create_clock -name benchmark_clk -period $clock_period [get_ports $clock_port]
    set data_input_ports [get_ports -filter "DIRECTION == IN && NAME != $clock_port && NAME != iRstn"]
    if {[llength $data_input_ports] > 0} {
        set_input_delay -clock benchmark_clk 0.000 $data_input_ports
    }
    if {[llength [get_ports -quiet iRstn]] > 0} {
        set_false_path -from [get_ports iRstn]
    }

    set timing_file [file join $report_dir "${module_name}_timing_summary.rpt"]
    set utilization_file [file join $report_dir "${module_name}_utilization.rpt"]
    report_timing_summary -delay_type max -max_paths 10 -report_unconstrained -file $timing_file
    report_utilization -hierarchical -file $utilization_file

    set worst_path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
    set slack [get_property SLACK $worst_path]
    set data_path_delay [get_property DATAPATH_DELAY $worst_path]
    set requirement [get_property REQUIREMENT $worst_path]
    set startpoint [get_property STARTPOINT_PIN $worst_path]
    set endpoint [get_property ENDPOINT_PIN $worst_path]

    puts "OOC_TIMING_RESULT module=$module_name period_ns=$clock_period slack_ns=$slack requirement_ns=$requirement datapath_ns=$data_path_delay"
    puts "OOC_TIMING_PATH module=$module_name startpoint=$startpoint endpoint=$endpoint"

    close_design
}

report_ooc_module "Conv3x3ReluParam" \
    [list [file join $project_root "Source" "Conv3x3ReluParam.sv"]] \
    "iClk" 10.000 $report_dir $target_part

report_ooc_module "Window3x3Case9" \
    [list \
        [file join $project_root "Source" "RasterAddrGen.sv"] \
        [file join $project_root "TestBench" "reference" "Window3x3Case9.sv"]] \
    "iClk" 10.000 $report_dir $target_part

report_ooc_module "Window3x3LineBuffer" \
    [list [file join $project_root "Source" "Window3x3LineBuffer.sv"]] \
    "iClk" 10.000 $report_dir $target_part

puts "OOC_TIMING_PASS report_dir=$report_dir"
