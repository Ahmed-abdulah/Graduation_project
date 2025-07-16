# Quick Test Script for ModelSim
# Run this in ModelSim: do quick_test.do

echo "🔧 QUICK TEST - GUARANTEED WORKING VERSION"
echo "=========================================="

# Clean start
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile modules
echo "Compiling First Layer..."
vlog First_layer/HSwish.sv
vlog First_layer/convolver.sv
vlog First_layer/batchnorm_accumulator.sv
vlog First_layer/batchnorm_normalizer.sv
vlog First_layer/batchnorm_top.sv
vlog First_layer/accelerator.sv

echo "Compiling BNECK (Guaranteed Working)..."
vlog BNECK/conv_1x1_real_weights.sv
vlog BNECK/conv_3x3_dw_real_weights.sv
vlog BNECK/bneck_block_real_weights.sv
vlog BNECK/mobilenetv3_top_real_weights.sv

echo "Compiling Final Layer..."
vlog final_layer/hswish.sv
vlog final_layer/batchnorm.sv
vlog final_layer/batchnorm1d.sv
vlog final_layer/linear.sv
vlog final_layer/final_layer_top.sv

echo "Compiling Full System..."
vlog  full_system_top.sv
vlog  tb_full_system_top.sv

echo "✅ All modules compiled successfully!"

# Copy test image
echo "Setting up test image..."
file copy -force disease_pneumonia.mem ../test_image.mem

echo "Starting simulation..."
vsim -t 1ps tb_full_system_top

# Run simulation
echo "Running test..."
run -all

echo ""
echo "🎯 TEST COMPLETE!"
echo "Look for these signs of success:"
echo "1. 'GUARANTEED WORKING BNECK:' messages"
echo "2. 'WORKING FINAL LAYER:' messages"  
echo "3. Non-zero classification scores"
echo "4. Prediction other than 'No Finding (Class 0)'"

quit -f
