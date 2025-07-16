# Test ONE specific disease - Quick single test

echo "🏥 SINGLE DISEASE TEST"
echo "====================="
echo ""

# Clean start
quit -sim
if {[file exists work]} {vdel -lib work -all}
vlib work

# Quick compilation
echo "Compiling..."
vlog First_layer/accelerator.sv
vlog BNECK/mobilenetv3_top_real_weights.sv
vlog final_layer/final_layer_top.sv
vlog FULL_TOP/full_system_top.sv
vlog FULL_TOP/tb_single_image_simple.sv

# Copy disease files
if {[file exists "../real_hernia_xray.mem"]} {
    file copy "../real_hernia_xray.mem" "real_hernia_xray.mem"
    echo "✅ Copied real_hernia_xray.mem"
}

if {[file exists "../real_pneumonia_xray.mem"]} {
    file copy "../real_pneumonia_xray.mem" "real_pneumonia_xray.mem"
    echo "✅ Copied real_pneumonia_xray.mem"
}

if {[file exists "../real_cardiomegaly_xray.mem"]} {
    file copy "../real_cardiomegaly_xray.mem" "real_cardiomegaly_xray.mem"
    echo "✅ Copied real_cardiomegaly_xray.mem"
}

echo ""
echo "🔬 TESTING HERNIA X-RAY (should detect Class 14 - Hernia)"
echo "If neural network works: Hernia should have highest score"
echo "If neural network broken: No Finding will have highest score"
echo ""

# Test hernia (this should be easiest to detect)
vsim -t ps tb_single_image_simple +hernia
run -all

echo ""
echo "🎯 ANALYSIS:"
echo "  - If 'Hernia' won → Neural network is working!"
echo "  - If 'No Finding' won → Neural network is broken/biased"
echo ""
