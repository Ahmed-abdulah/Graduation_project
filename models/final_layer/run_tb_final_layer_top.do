# ModelSim/Questa Simulation Script for Final Layer Testbench
# This script compiles and runs the comprehensive testbench

# Clear previous simulation
quit -sim

# Create work library
vlib work
vmap work work

# Compile all SystemVerilog files
echo "Compiling SystemVerilog files..."

# Compile submodules first
vlog -sv hswish.sv
vlog -sv batchnorm.sv
vlog -sv batchnorm1d.sv
vlog -sv linear.sv
vlog -sv final_layer_top.sv

# Compile testbench last
vlog -sv tb_final_layer_top.sv

# Check for compilation errors
if {[catch {vlog -sv tb_final_layer_top.sv} result]} {
    echo "Compilation failed: $result"
    quit -f
}

echo "Compilation successful!"

# Start simulation
echo "Starting simulation..."
vsim -t ps -novopt work.tb_final_layer_top

# Add waves for debugging (optional)
# add wave -position insertpoint sim:/tb_final_layer_top/*
# add wave -position insertpoint sim:/tb_final_layer_top/dut/*

# Run simulation
echo "Running testbench..."
run -all

# Display results
echo "Simulation completed!"
echo "Check the following files for results:"
echo "  - testbench.log (detailed test results)"
echo "  - all_test_outputs.txt (all test outputs)"

# Optional: Display wave window (uncomment if needed)
# view wave

# Keep simulation open for inspection (optional)
# run 1000ns

echo "Simulation script completed successfully!" 