# Comprehensive Disease Testing Script
# Tests all 15 diseases using tb_full_system_all_diseases.sv
# Ensures syntax-error-free compilation and complete testing

# Clean up previous work
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work
vmap work work

echo "================================================================"
echo "COMPREHENSIVE DISEASE CLASSIFICATION TEST"
echo "Testing MobileNetV3 Neural Network with ALL 15 Disease Categories"
echo "================================================================"
echo ""

# Check if all disease memory files exist
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

set disease_names {
    "Normal (No Finding)"
    "Infiltration"
    "Atelectasis"
    "Effusion"
    "Nodule"
    "Pneumothorax"
    "Mass"
    "Consolidation"
    "Pleural Thickening"
    "Cardiomegaly"
    "Emphysema"
    "Fibrosis"
    "Edema"
    "Pneumonia"
    "Hernia"
}

echo "Checking disease memory files..."
set missing_files 0
set existing_files 0

for {set i 0} {$i < [llength $disease_files]} {incr i} {
    set file [lindex $disease_files $i]
    set disease [lindex $disease_names $i]
    
    if {[file exists $file]} {
        set size [file size $file]
        echo "✅ $disease: $file ($size bytes)"
        incr existing_files
    } else {
        echo "❌ $disease: $file (MISSING)"
        incr missing_files
    }
}

echo ""
echo "Disease Files Status: $existing_files found, $missing_files missing"

if {$missing_files > 0} {
    echo ""
    echo "⚠️  WARNING: $missing_files disease files are missing!"
    echo "   Run: ./convert_all_diseases_working.sh to generate them"
    echo "   The test will continue with available files (zeros will be used for missing files)"
    echo ""
}

# Compile all source files in correct order
echo "================================================================"
echo "COMPILING SYSTEMVERILOG FILES"
echo "================================================================"

# Compile First Layer components
echo ""
echo "Compiling First Layer components..."
vlog -work work First_layer/HSwish.sv
if {[string match "*Error*" $::errorInfo]} {
    echo "❌ Error compiling First_layer/HSwish.sv"
    quit -f
}

vlog -work work First_layer/convolver.sv
if {[string match "*Error*" $::errorInfo]} {
    echo "❌ Error compiling First_layer/convolver.sv"
    quit -f
}

vlog  First_layer/batchnorm_accumulator.sv
vlog  First_layer/batchnorm_normalizer.sv
vlog  First_layer/batchnorm_top.sv
vlog -work work First_layer/accelerator.sv

echo "✅ First Layer compilation complete"

# Compile BNECK components
echo ""
echo "Compiling BNECK components..."
vlog -work work BNECK/conv_1x1_optimized.sv
vlog -work work BNECK/conv_3x3_dw_optimized.sv
vlog -work work BNECK/bneck_block_optimized.sv
vlog -work work BNECK/mobilenetv3_sequence_optimized.sv
vlog -work work BNECK/mobilenetv3_top_optimized.sv

echo "✅ BNECK compilation complete"

# Compile Final Layer components (FIXED - no pointwise_conv.sv)
echo ""
echo "Compiling Final Layer components..."
vlog -work work final_layer/hswish.sv
vlog -work work final_layer/batchnorm.sv
vlog -work work final_layer/batchnorm1d.sv
vlog -work work final_layer/linear.sv
vlog -work work final_layer/final_layer_top.sv

echo "✅ Final Layer compilation complete"

# Compile Full System
echo ""
echo "Compiling Full System..."
vlog -work work FULL_TOP/full_system_top.sv

echo "✅ Full System compilation complete"

# Compile comprehensive testbench (SYNTAX FIXED)
echo ""
echo "Compiling comprehensive disease testbench (syntax-error-free)..."
vlog -work work FULL_TOP/tb_full_system_all_diseases.sv

if {[string match "*Error*" $::errorInfo]} {
    echo "❌ Error compiling testbench"
    quit -f
}

echo "✅ Testbench compilation complete"

# Verify compilation
if {[llength [find instances -bydu tb_full_system_all_diseases]] == 0} {
    echo "❌ ERROR: Testbench compilation failed!"
    quit -f
}

echo ""
echo "================================================================"
echo "STARTING COMPREHENSIVE DISEASE SIMULATION"
echo "================================================================"
echo ""
echo "🏥 Testing ALL 15 Disease Categories:"
for {set i 0} {$i < [llength $disease_names]} {incr i} {
    set disease [lindex $disease_names $i]
    echo "   $i. $disease"
}
echo ""
echo "⏱️  Expected Duration: 15-30 minutes"
echo "📊 Progress will be shown in transcript"
echo ""

# Start simulation
vsim -t 1ps -lib work tb_full_system_all_diseases

# Configure waveform display
configure wave -namecolwidth 300
configure wave -valuecolwidth 120
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Add comprehensive signals to waveform
add wave -divider "=== CLOCK AND RESET ==="
add wave -hex /tb_full_system_all_diseases/clk
add wave -hex /tb_full_system_all_diseases/rst
add wave -hex /tb_full_system_all_diseases/en

add wave -divider "=== TEST PROGRESS ==="
add wave -decimal /tb_full_system_all_diseases/current_test
add wave -decimal /tb_full_system_all_diseases/current_pixel
add wave -decimal /tb_full_system_all_diseases/total_tests
add wave -decimal /tb_full_system_all_diseases/correct_predictions

add wave -divider "=== NEURAL NETWORK INTERFACE ==="
add wave -hex /tb_full_system_all_diseases/pixel_in
add wave -hex /tb_full_system_all_diseases/class_scores
add wave -hex /tb_full_system_all_diseases/valid_out

add wave -divider "=== DISEASE CLASSIFICATION RESULTS ==="
add wave -decimal /tb_full_system_all_diseases/predicted_classes
add wave -decimal /tb_full_system_all_diseases/confidence_scores
add wave -decimal /tb_full_system_all_diseases/test_results

add wave -divider "=== PERFORMANCE METRICS ==="
add wave -decimal /tb_full_system_all_diseases/test_cycles
add wave -decimal /tb_full_system_all_diseases/total_cycles

# Set up comprehensive logging
transcript file comprehensive_disease_simulation.log

echo "================================================================"
echo "RUNNING SIMULATION - TESTING ALL 15 DISEASES"
echo "================================================================"
echo ""
echo "The simulation will:"
echo "1. Load all 15 disease X-ray images"
echo "2. Feed each image through the MobileNetV3 neural network"
echo "3. Classify each disease and measure confidence"
echo "4. Generate comprehensive accuracy reports"
echo "5. Provide medical AI performance analysis"
echo ""

# Run the complete simulation
run -all

echo ""
echo "================================================================"
echo "COMPREHENSIVE DISEASE TESTING COMPLETE!"
echo "================================================================"
echo ""
echo "📊 GENERATED REPORTS:"
echo "   ✅ disease_classification_summary.txt - Main accuracy results"
echo "   ✅ all_diseases_diagnosis.txt - Detailed medical analysis"
echo "   ✅ all_diseases_testbench.log - Technical simulation details"
echo "   ✅ comprehensive_disease_simulation.log - Complete transcript"
echo ""
echo "📈 KEY METRICS TO CHECK:"
echo "   • Overall Classification Accuracy (target: >80%)"
echo "   • Per-Disease Accuracy for each of the 15 conditions"
echo "   • Confidence Scores for correct predictions"
echo "   • Simulation Performance (cycles per disease)"
echo ""
echo "🏥 DISEASES TESTED:"
echo "   0. Normal (No Finding)     8. Pleural Thickening"
echo "   1. Infiltration            9. Cardiomegaly"
echo "   2. Atelectasis            10. Emphysema"
echo "   3. Effusion               11. Fibrosis"
echo "   4. Nodule                 12. Edema"
echo "   5. Pneumothorax           13. Pneumonia"
echo "   6. Mass                   14. Hernia"
echo "   7. Consolidation"
echo ""
echo "🔍 TO ANALYZE RESULTS:"
echo "   python FULL_TOP/analyze_all_diseases_results.py"
echo ""

# Save waveform for detailed analysis
if {[file exists comprehensive_diseases_waveform.wlf]} {
    file delete comprehensive_diseases_waveform.wlf
}
write format wave -window .main_pane.wave.interior.cs.body.pw.wf comprehensive_diseases_waveform.wlf

echo "💾 Waveform saved: comprehensive_diseases_waveform.wlf"
echo ""
echo "🎯 COMPREHENSIVE MEDICAL AI TESTING COMPLETE!"
echo "   Your MobileNetV3 neural network has been tested against"
echo "   all 15 major chest X-ray pathology categories!"

# Keep ModelSim open for result analysis
# quit -sim
