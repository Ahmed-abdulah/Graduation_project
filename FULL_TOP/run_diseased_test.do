# Diseased X-ray Images Test - Tests multiple real diseased images

echo "🏥 DISEASED X-RAY IMAGES MEDICAL AI TEST"
echo "========================================"
echo "This test uses REAL diseased X-ray memory files to check if"
echo "the neural network can actually detect different diseases"
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

# Diseased images testbench
echo "Compiling Diseased Images Testbench..."
vlog -sv FULL_TOP/tb_diseased_images_test.sv

echo ""
echo "✅ ALL FILES COMPILED SUCCESSFULLY!"
echo ""

# Check for required diseased memory files
echo "🔍 Checking for diseased X-ray memory files..."

set required_files {
    "real_pneumonia_xray.mem"
    "real_cardiomegaly_xray.mem"
    "real_effusion_xray.mem"
    "real_atelectasis_xray.mem"
    "real_normal_xray.mem"
}

set files_found 0
set files_missing 0

foreach file $required_files {
    if {[file exists "../$file"]} {
        echo "✅ Found ../$file - copying to working directory"
        file copy "../$file" "$file"
        incr files_found
    } elseif {[file exists "$file"]} {
        echo "✅ Found $file in current directory"
        incr files_found
    } else {
        echo "⚠️ Missing: $file"
        incr files_missing
    }
}

echo ""
echo "📊 File Status:"
echo "  Found: $files_found files"
echo "  Missing: $files_missing files"

if {$files_missing > 0} {
    echo ""
    echo "⚠️ Some diseased image files are missing."
    echo "   The test will create synthetic patterns for missing files."
    echo "   For best results, ensure all real diseased X-ray .mem files are available."
}

echo ""
echo "🚀 Starting Diseased Images Test..."
echo ""
echo "📋 This test will:"
echo "  1. Load 5 different diseased X-ray images"
echo "  2. Test each one through the neural network"
echo "  3. Check if the correct disease is detected"
echo "  4. Report accuracy and any systematic issues"
echo ""

# Start simulation
vsim -t ps -novopt work.tb_diseased_images_test +file

echo "Running diseased images test..."
run -all

echo ""
echo "✅ DISEASED IMAGES TEST COMPLETE!"
echo ""
echo "📊 What this test reveals:"
echo "  - Whether the neural network can detect different diseases"
echo "  - If it's stuck always predicting 'No Finding'"
echo "  - Which diseases it can/cannot recognize"
echo "  - Overall accuracy across multiple disease types"
echo ""
echo "🔍 Key things to look for in results:"
echo "  - Does it predict different classes for different diseases?"
echo "  - Is accuracy better than random (>6.7%)?"
echo "  - Are confidence scores varying appropriately?"
echo ""

# Keep simulation open for analysis
# quit -sim
