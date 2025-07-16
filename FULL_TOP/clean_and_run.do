# Clean and Run Script for Full System Testbench
# This script completely cleans the work library and recompiles everything

# Clear previous simulation and work library
quit -sim
vdel -all
vlib work
vmap work work

echo "Cleaned work library and starting fresh compilation..."

# Compile all SystemVerilog files for the complete system
echo "Compiling Full System Files..."

# First Layer components
echo "Compiling First Layer..."
vlog -sv First_layer/accelerator.sv
vlog -sv First_layer/batchnorm_accumulator.sv
vlog -sv First_layer/batchnorm_normalizer.sv
vlog -sv First_layer/batchnorm_top.sv
vlog -sv First_layer/convolver.sv
vlog -sv First_layer/HSwish.sv

# BNeck components
echo "Compiling BNeck Blocks..."
vlog -sv BNECK/bneck_block_optimized.sv
vlog -sv BNECK/conv_1x1_optimized.sv
vlog -sv BNECK/conv_3x3_dw_optimized.sv
vlog -sv BNECK/mobilenetv3_top_optimized.sv

# Final Layer components
echo "Compiling Final Layer..."
vlog -sv final_layer/hswish.sv
vlog -sv final_layer/batchnorm.sv
vlog -sv final_layer/batchnorm1d.sv
vlog -sv final_layer/linear.sv
vlog -sv final_layer/final_layer_top.sv

# Full System Top
echo "Compiling Full System Top..."
vlog -sv full_system_top.sv

# Compile testbench last
echo "Compiling Testbench..."
vlog -sv tb_full_system_top.sv



echo "Compilation successful!"

# Start simulation
echo "Starting Full System Simulation..."
vsim -t ps -novopt work.tb_full_system_top

# Run simulation
echo "Running Full System Testbench..."
run -all

# Display results
echo "Full System Simulation completed!"
echo "Check the following files for results:"
echo "  - full_system_testbench.log (detailed test results)"
echo "  - full_system_outputs.txt (all test outputs)"

echo "Clean compilation and simulation completed successfully!" 