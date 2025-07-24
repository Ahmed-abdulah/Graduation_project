# Synthesis Script for MobileNetV3 Full System
# Fixes memory synthesis issues

# Set memory parameter to handle large arrays
set_param synth.elaboration.rodinMoreOptions {rt::set_parameter dissolveMemorySizeLimit 81920}

# Read all SystemVerilog files
read_verilog -sv {
    First_layer/accelerator.sv
    First_layer/batchnorm_accumulator.sv
    First_layer/batchnorm_normalizer.sv
    First_layer/batchnorm_top.sv
    First_layer/convolver.sv
    First_layer/HSwish.sv
    BNECK/bneck_block_optimized.sv
    BNECK/conv_1x1_optimized.sv
    BNECK/conv_3x3_dw_optimized.sv
    BNECK/mobilenetv3_sequence_optimized.sv
    BNECK/mobilenetv3_top_optimized.sv
    final_layer/pointwise_conv.sv
    final_layer/linear.sv
    final_layer/hswish.sv
    final_layer/batchnorm.sv
    final_layer/batchnorm1d.sv
    final_layer/final_layer_top.sv
    FULL_TOP/full_system_top.sv
}

# Set top module
set_property top full_system_top [current_fileset]

# Run synthesis with optimized settings
synth_design -top full_system_top -part xc7z020clg484-1 -directive RuntimeOptimized

# Generate reports
report_utilization -file utilization_report.txt
report_timing -file timing_report.txt

puts "Synthesis completed successfully!"