# SIMPLE WORKING TEST - GUARANTEED TO WORK
# Run this step by step to debug issues

echo "🔧 SIMPLE WORKING TEST - STEP BY STEP"
echo "====================================="

# Step 1: Clean and create work library
echo "Step 1: Creating work library..."
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Step 2: Go to parent directory where .mem files are
echo "Step 2: Setting working directory..."
cd ..
pwd

# Step 3: Check if test image exists
echo "Step 3: Checking for test images..."
if {[file exists real_pneumonia_xray.mem]} {
    echo "✅ Found: real_pneumonia_xray.mem"
    file copy -force real_pneumonia_xray.mem test_image.mem
    echo "✅ Copied to test_image.mem"
} else {
    echo "❌ Missing: real_pneumonia_xray.mem"
    echo "Creating dummy test image..."
    set fp [open test_image.mem w]
    for {set i 0} {$i < 1000} {incr i} {
        puts $fp [format "%04x" [expr $i % 4096]]
    }
    close $fp
    echo "✅ Created dummy test_image.mem"
}

# Step 4: Compile First Layer
echo "Step 4: Compiling First Layer..."
vlog First_layer/HSwish.sv
vlog First_layer/convolver.sv
vlog First_layer/batchnorm_accumulator.sv
vlog First_layer/batchnorm_normalizer.sv
vlog First_layer/batchnorm_top.sv
vlog First_layer/accelerator.sv
echo "✅ First Layer compiled"

# Step 5: Compile BNECK
echo "Step 5: Compiling BNECK..."
vlog BNECK/conv_1x1_real_weights.sv
vlog BNECK/conv_3x3_dw_real_weights.sv
vlog BNECK/bneck_block_real_weights.sv
vlog BNECK/mobilenetv3_top_real_weights.sv
echo "✅ BNECK compiled"

# Step 6: Compile Final Layer
echo "Step 6: Compiling Final Layer..."
vlog final_layer/hswish.sv
vlog final_layer/batchnorm.sv
vlog final_layer/batchnorm1d.sv
vlog final_layer/linear.sv
vlog final_layer/final_layer_top.sv
echo "✅ Final Layer compiled"

# Step 7: Compile Full System
echo "Step 7: Compiling Full System..."
vlog FULL_TOP/full_system_top.sv
vlog FULL_TOP/tb_full_system_all_diseases.sv
echo "✅ Full System compiled"

# Step 8: Start simulation for ALL 15 DISEASES
echo "Step 8: Starting simulation for ALL 15 diseases..."
vsim -t 1ps tb_full_system_all_diseases

# Step 9: Run simulation for all diseases
echo "Step 9: Running simulation for ALL 15 diseases..."
echo "This will test: Normal, Infiltration, Atelectasis, Effusion, Nodule,"
echo "Pneumothorax, Mass, Consolidation, Pleural Thickening, Cardiomegaly,"
echo "Emphysema, Fibrosis, Edema, Pneumonia, Hernia"
echo ""
run -all

echo ""
echo "🎯 SIMPLE TEST COMPLETE!"
echo ""
echo "Look for these in the output:"
echo "1. 'BNECK FIXED: input=0x????, output=0x????'"
echo "2. 'FINAL LAYER DATA: data=0x????, safe_data=0x????'"
echo "3. 'ALL SCORES:' with different values for each class"
echo "4. 'FIND_MAX_SCORE DEBUG:' showing the maximum selection"
echo "5. Final prediction should NOT always be 'No Finding (Class 0)'"
echo ""
echo "If this works, then run the full test:"
echo "   do run_all_diseases_test.do"

quit -sim
