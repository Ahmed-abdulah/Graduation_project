# COMPREHENSIVE TEST - ALL 15 DISEASES WITH DETAILED ANALYSIS
# This will test all diseases and show internal processing details

echo "🏥 COMPREHENSIVE MEDICAL AI TEST - ALL 15 DISEASES"
echo "=================================================="
echo ""
echo "This test will:"
echo "1. Test all 15 disease categories"
echo "2. Show internal neural network processing"
echo "3. Calculate real accuracy statistics"
echo "4. Provide detailed medical analysis"
echo ""

# Clean start
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Go to parent directory where disease files are
cd ..

# Check for all disease files
set disease_files {
    "real_normal_xray.mem"
    "real_infiltration_xray.mem" 
    "real_atelectasis_xray.mem"
    "real_effusion_xray.mem"
    "real_nodule_xray.mem"
    "real_pneumothorax_xray.mem"
    "real_mass_xray.mem"
    "real_consolidation_xray.mem"
    "real_pleural_thickening_xray.mem"
    "real_cardiomegaly_xray.mem"
    "real_emphysema_xray.mem"
    "real_fibrosis_xray.mem"
    "real_edema_xray.mem"
    "real_pneumonia_xray.mem"
    "real_hernia_xray.mem"
}

set found_files 0
echo "Checking for disease X-ray files..."
foreach file $disease_files {
    if {[file exists $file]} {
        echo "✅ Found: $file"
        incr found_files
    } else {
        echo "❌ Missing: $file"
    }
}

echo ""
echo "Found $found_files out of 15 disease files"
if {$found_files < 15} {
    echo "⚠️  Some files missing - test will continue with available files"
}
echo ""

# Compile all components
echo "Compiling neural network components..."

# First Layer
echo "  📊 Compiling First Layer (Input Processing)..."
vlog First_layer/HSwish.sv
vlog First_layer/convolver.sv  
vlog First_layer/batchnorm_accumulator.sv
vlog First_layer/batchnorm_normalizer.sv
vlog First_layer/batchnorm_top.sv
vlog First_layer/accelerator.sv

# BNECK (Neural Network Backbone)
echo "  🧠 Compiling BNECK (Neural Network Backbone)..."
vlog BNECK/conv_1x1_real_weights.sv
vlog BNECK/conv_3x3_dw_real_weights.sv
vlog BNECK/bneck_block_real_weights.sv
vlog BNECK/mobilenetv3_top_real_weights.sv

# Final Layer (Classification)
echo "  🎯 Compiling Final Layer (Disease Classification)..."
vlog final_layer/hswish.sv
vlog final_layer/batchnorm.sv
vlog final_layer/batchnorm1d.sv
vlog final_layer/linear.sv
vlog final_layer/final_layer_top.sv

# Full System
echo "  🏥 Compiling Full Medical AI System..."
vlog FULL_TOP/full_system_top.sv
vlog FULL_TOP/tb_full_system_all_diseases.sv

echo "✅ All components compiled successfully!"
echo ""

# Start comprehensive simulation
echo "🚀 Starting comprehensive medical AI simulation..."
echo "Testing all 15 disease categories with real chest X-ray images"
echo ""
echo "Expected diseases to test:"
echo "  0. No Finding (Normal)"
echo "  1. Infiltration" 
echo "  2. Atelectasis"
echo "  3. Effusion"
echo "  4. Nodule"
echo "  5. Pneumothorax"
echo "  6. Mass"
echo "  7. Consolidation"
echo "  8. Pleural Thickening"
echo "  9. Cardiomegaly"
echo " 10. Emphysema"
echo " 11. Fibrosis"
echo " 12. Edema"
echo " 13. Pneumonia"
echo " 14. Hernia"
echo ""

# Configure simulation for detailed analysis
vsim -t 1ps tb_full_system_all_diseases

# Set up logging
transcript file comprehensive_medical_ai_test.log

echo "⏱️  Simulation starting... (Expected duration: 5-15 minutes)"
echo "📊 Progress will be shown for each disease test"
echo ""

# Run the comprehensive test
run -all

echo ""
echo "🎉 COMPREHENSIVE MEDICAL AI TEST COMPLETE!"
echo "=========================================="
echo ""
echo "📊 Results Analysis:"
echo "  - Detailed log: comprehensive_medical_ai_test.log"
echo "  - Look for accuracy statistics in the final summary"
echo "  - Each disease shows internal processing details"
echo ""
echo "🔍 Key Metrics to Check:"
echo "  1. Overall Accuracy (should be >60% with current fixes)"
echo "  2. Individual disease predictions"
echo "  3. Score distributions (should be different for each disease)"
echo "  4. Processing consistency (no more 'x' values)"
echo ""
echo "🏥 Medical AI Performance Summary will be displayed above"

quit -sim
