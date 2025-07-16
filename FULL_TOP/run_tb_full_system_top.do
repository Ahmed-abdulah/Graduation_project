# ModelSim/Questa Simulation Script for Full System Testbench
# This script compiles and runs the complete MobileNetV3 system testbench

# Clear previous simulation
quit -sim

# Create work library
vlib work
vmap work work

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
vlog -sv BNECK/mobilenetv3_top_optimized.sv
vlog -sv BNECK/mobilenetv3_top_real_weights.sv
vlog -sv BNECK/bneck_block_real_weights.sv

# Final Layer components (NEW VERSION)
echo "Compiling Final Layer..."
vlog -sv final_layer/final_layer_top.sv

# Full System Top
echo "Compiling Full System Top..."
vlog -sv FULL_TOP/full_system_top.sv

# Compile testbench last
echo "Compiling Testbench..."
vlog -sv FULL_TOP/tb_full_system_top.sv

echo "Compilation successful!"

# Start simulation
echo "Starting Full System Simulation..."
vsim -t ps -novopt work.tb_full_system_top

# Add waves for debugging (optional - uncomment if needed)
# add wave -position insertpoint sim:/tb_full_system_top/*
# add wave -position insertpoint sim:/tb_full_system_top/dut/*
# add wave -position insertpoint sim:/tb_full_system_top/dut/first_layer_inst/*
# add wave -position insertpoint sim:/tb_full_system_top/dut/bneck_sequence/*
# add wave -position insertpoint sim:/tb_full_system_top/dut/final_layer_inst/*

# Run simulation
echo "Running Full System Testbench..."
run -all

# Display results
echo "Full System Simulation completed!"
echo "Check the following files for results:"
echo "  - full_system_testbench.log (detailed test results)"
echo "  - full_system_outputs.txt (all test outputs)"

# Optional: Display wave window (uncomment if needed)
# view wave

# Keep simulation open for inspection (optional)
# run 1000ns

echo "Full System Simulation script completed successfully!" 