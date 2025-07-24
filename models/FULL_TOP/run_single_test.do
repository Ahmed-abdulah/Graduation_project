# ModelSim/Questa Single Test Script
# Simple, reliable test for one X-ray image

echo "🏥 SINGLE TEST MEDICAL AI SYSTEM"
echo "================================"
echo ""

# Clean previous simulation
quit -sim

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

echo "✅ Work library created"
echo ""

# Compile all required files
echo "📁 Compiling SystemVerilog files..."
echo ""

# First Layer components
echo "Compiling First Layer..."
vlog -work work ../First_layer/accelerator.sv
vlog -work work ../First_layer/batchnorm_accumulator.sv
vlog -work work ../First_layer/batchnorm_normalizer.sv
vlog -work work ../First_layer/batchnorm_top.sv
vlog -work work ../First_layer/convolver.sv
vlog -work work ../First_layer/HSwish.sv

# BNeck components (using real weights version)
echo "Compiling BNeck Blocks (Real Weights)..."
vlog -work work ../BNECK/conv_1x1_real_weights.sv
vlog -work work ../BNECK/conv_3x3_dw_real_weights.sv
vlog -work work ../BNECK/bneck_block_real_weights.sv
vlog -work work ../BNECK/mobilenetv3_top_real_weights.sv

# Final Layer components
echo "Compiling Final Layer..."
vlog -work work ../final_layer/hswish.sv
vlog -work work ../final_layer/batchnorm.sv
vlog -work work ../final_layer/batchnorm1d.sv
vlog -work work ../final_layer/linear.sv
vlog -work work ../final_layer/final_layer_top.sv

# Full System Top
echo "Compiling Full System..."
vlog -work work full_system_top.sv

# Compile testbench
echo "Compiling Single Test Testbench..."
vlog -work work tb_single_test.sv

echo ""
echo "✅ All files compiled successfully!"
echo ""

# Check if test image exists
if {![file exists "test_image.mem"]} {
    echo "⚠️ test_image.mem not found. Creating default test pattern..."
    
    # Create a simple test pattern
    set fp [open "test_image.mem" w]
    for {set i 0} {$i < 50176} {incr i} {
        # Create a simple gradient pattern
        set val [expr {($i % 256) + 4096}]
        puts $fp [format "%04x" $val]
    }
    close $fp
    
    echo "✅ Default test pattern created"
}

echo ""
echo "🚀 Starting Single Test Simulation..."
echo ""

# Start simulation
vsim -t 1ps -lib work tb_single_test

# Add waves for debugging (optional)
# add wave -position insertpoint sim:/tb_single_test/clk
# add wave -position insertpoint sim:/tb_single_test/rst
# add wave -position insertpoint sim:/tb_single_test/en
# add wave -position insertpoint sim:/tb_single_test/valid_out
# add wave -position insertpoint sim:/tb_single_test/class_scores

# Run simulation
echo "Running simulation..."
run -all

echo ""
echo "🎯 Single Test Complete!"
echo ""
echo "📋 What this test does:"
echo "  1. Loads one X-ray image (224x224 pixels)"
echo "  2. Processes it through the complete neural network"
echo "  3. Outputs classification for 15 medical conditions"
echo "  4. Shows performance metrics and recommendations"
echo ""
echo "📊 Expected output:"
echo "  - Classification scores for all 15 diseases"
echo "  - Primary diagnosis with confidence"
echo "  - Medical recommendation"
echo "  - Processing time and throughput"
echo ""

# Keep simulation open for analysis
# quit -sim
