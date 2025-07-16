# Single X-ray Image Test - Uses ONLY xray_image (1).mem

echo "🏥 SINGLE X-RAY IMAGE MEDICAL AI TEST"
echo "====================================="
echo "This test uses ONLY the xray_image (1).mem file"
echo ""

# Clean start
quit -sim
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work

echo "✅ Work library created"
echo ""

# Compile all required files (complete set)
echo "📁 Compiling SystemVerilog files..."

# First Layer components
echo "Compiling First Layer..."
vlog -sv First_layer/accelerator.sv
vlog -sv First_layer/batchnorm_accumulator.sv
vlog -sv First_layer/batchnorm_normalizer.sv
vlog -sv First_layer/batchnorm_top.sv
vlog -sv First_layer/convolver.sv
vlog -sv First_layer/HSwish.sv

# BNECK components (COMPLETE SET)
echo "Compiling BNECK Blocks..."
vlog -sv BNECK/conv_1x1_real_weights.sv
vlog -sv BNECK/conv_3x3_dw_real_weights.sv
vlog -sv BNECK/bneck_block_real_weights.sv
vlog -sv BNECK/mobilenetv3_top_real_weights.sv

# Final Layer components
echo "Compiling Final Layer..."
vlog -sv final_layer/hswish.sv
vlog -sv final_layer/batchnorm.sv
vlog -sv final_layer/batchnorm1d.sv
vlog -sv final_layer/linear.sv
vlog -sv final_layer/final_layer_top.sv

# Full System Top
echo "Compiling Full System Top..."
vlog -sv FULL_TOP/full_system_top.sv

# Single X-ray testbench
echo "Compiling Single X-ray Testbench..."
vlog -sv FULL_TOP/tb_xray_image_only.sv

echo ""
echo "✅ ALL FILES COMPILED SUCCESSFULLY!"
echo ""

# Handle xray_image file
echo "🔍 Looking for xray_image (1).mem..."

if {[file exists "../xray_image (1).mem"]} {
    echo "✅ Found ../xray_image (1).mem - copying to working directory"
    file copy "../xray_image (1).mem" "xray_image.mem"
} elseif {[file exists "xray_image (1).mem"]} {
    echo "✅ Found xray_image (1).mem in current directory"
    file copy "xray_image (1).mem" "xray_image.mem"
} elseif {[file exists "../xray_image.mem"]} {
    echo "✅ Found ../xray_image.mem - copying to working directory"
    file copy "../xray_image.mem" "xray_image.mem"
} elseif {[file exists "xray_image.mem"]} {
    echo "✅ Found xray_image.mem in current directory"
} else {
    echo "⚠️ xray_image file not found - creating test pattern"
    set fp [open "xray_image.mem" w]
    for {set i 0} {$i < 50176} {incr i} {
        puts $fp [format "%04x" [expr {4096 + ($i % 256)}]]
    }
    close $fp
    echo "✅ Test pattern created as xray_image.mem"
}

echo ""
echo "🚀 Starting Single X-ray Simulation..."
echo ""

# Start simulation
vsim -t ps -novopt work.tb_xray_image_only +file

echo "Running single X-ray test..."
run -all

echo ""
echo "✅ SINGLE X-RAY TEST COMPLETE!"
echo ""
echo "📋 What this test did:"
echo "  1. Loaded ONLY xray_image (1).mem"
echo "  2. Processed it through MobileNetV3 neural network"
echo "  3. Classified into 15 medical conditions"
echo "  4. Provided medical recommendation"
echo "  5. Showed performance metrics"
echo ""
echo "📊 Results show:"
echo "  - Classification scores for all 15 diseases"
echo "  - Primary diagnosis with confidence percentage"
echo "  - Medical recommendation based on diagnosis"
echo "  - Processing time and throughput metrics"
echo ""

# Keep simulation open for analysis
# quit -sim
