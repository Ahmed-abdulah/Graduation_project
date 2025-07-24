# Simple Single Image Test - ONE image, ONE prediction

echo "🏥 SINGLE IMAGE NEURAL NETWORK TEST"
echo "==================================="
echo "Tests ONE image and gives ONE prediction"
echo ""

# Clean start
quit -sim
if {[file exists work]} {vdel -lib work -all}
vlib work

echo "Compiling neural network..."

# Compile all required files
vlog First_layer/HSwish.sv
vlog First_layer/convolver.sv
vlog First_layer/batchnorm_accumulator.sv
vlog First_layer/batchnorm_normalizer.sv
vlog First_layer/batchnorm_top.sv
vlog First_layer/accelerator.sv

vlog BNECK/conv_1x1_real_weights.sv
vlog BNECK/conv_3x3_dw_real_weights.sv
vlog BNECK/bneck_block_real_weights.sv
vlog BNECK/mobilenetv3_top_real_weights.sv

vlog final_layer/hswish.sv
vlog final_layer/batchnorm.sv
vlog final_layer/batchnorm1d.sv
vlog final_layer/linear.sv
vlog final_layer/final_layer_top.sv

vlog FULL_TOP/full_system_top.sv
vlog FULL_TOP/tb_single_image_simple.sv

echo "✅ Compilation complete!"
echo ""

# Check for image files
if {[file exists "../real_pneumonia_xray.mem"]} {
    echo "✅ Found: real_pneumonia_xray.mem"
    file copy "../real_pneumonia_xray.mem" "real_pneumonia_xray.mem"
} elseif {[file exists "real_pneumonia_xray.mem"]} {
    echo "✅ Found: real_pneumonia_xray.mem"
} else {
    echo "⚠️ real_pneumonia_xray.mem not found"
}

if {[file exists "../xray_image.mem"]} {
    echo "✅ Found: xray_image.mem"
    file copy "../xray_image.mem" "xray_image.mem"
} elseif {[file exists "xray_image.mem"]} {
    echo "✅ Found: xray_image.mem"
} else {
    echo "⚠️ Creating default test image"
    set fp [open "xray_image.mem" w]
    for {set i 0} {$i < 50176} {incr i} {
        puts $fp [format "%04x" [expr {4096 + ($i % 256)}]]
    }
    close $fp
}

echo ""
echo "🚀 Testing with DIFFERENT diseased images..."
echo ""
echo "📋 Available tests:"
echo "  1. Pneumonia (should detect Class 13)"
echo "  2. Hernia (should detect Class 14)"
echo "  3. Cardiomegaly (should detect Class 9)"
echo "  4. Effusion (should detect Class 3)"
echo "  5. Mass (should detect Class 6)"
echo ""

# Test 1: Pneumonia
echo "🔬 TEST 1: PNEUMONIA X-RAY"
echo "Expected: Should detect Pneumonia (Class 13), NOT No Finding"
vsim -t ps tb_single_image_simple +pneumonia
run -all
quit -sim

echo ""
echo "🔬 TEST 2: HERNIA X-RAY"
echo "Expected: Should detect Hernia (Class 14), NOT No Finding"
vsim -t ps tb_single_image_simple +hernia
run -all
quit -sim

echo ""
echo "🔬 TEST 3: CARDIOMEGALY X-RAY"
echo "Expected: Should detect Cardiomegaly (Class 9), NOT No Finding"
vsim -t ps tb_single_image_simple +cardiomegaly
run -all
quit -sim

echo ""
echo "✅ MULTIPLE DISEASE TESTS COMPLETE!"
echo ""
echo "🎯 ANALYSIS:"
echo "  - If ALL tests predict 'No Finding' → Neural network is BROKEN"
echo "  - If ANY test predicts correct disease → Neural network works partially"
echo "  - If MOST tests predict correctly → Neural network works well"
echo ""
echo "📊 Check results above to see if network can detect ANY disease!"
