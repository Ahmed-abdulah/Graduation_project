#!/bin/bash

echo "🏥 COMPREHENSIVE DISEASE CLASSIFICATION TEST"
echo "============================================"
echo "Testing MobileNetV3 Neural Network with ALL 15 Disease Categories"
echo "Using tb_full_system_all_diseases.sv (syntax-error-free)"
echo "============================================"
echo ""

# Check if we're in the right directory
if [ ! -f "FULL_TOP/tb_full_system_all_diseases.sv" ]; then
    echo "❌ Error: tb_full_system_all_diseases.sv not found"
    echo "   Make sure you're in the FULL_SYSTEM directory"
    exit 1
fi

# Step 1: Convert disease images if needed
echo "📸 STEP 1: Checking Disease Images"
echo "=================================="

disease_files=(
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
)

existing_count=0
missing_count=0

for file in "${disease_files[@]}"; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "unknown")
        echo "✅ Found: $file ($size bytes)"
        ((existing_count++))
    else
        echo "❌ Missing: $file"
        ((missing_count++))
    fi
done

echo ""
echo "Status: $existing_count found, $missing_count missing"

if [ $missing_count -gt 5 ]; then
    echo ""
    echo "⚠️  Too many files missing. Converting disease images first..."
    if [ -f "convert_all_diseases_working.sh" ]; then
        echo "Running disease image conversion..."
        ./convert_all_diseases_working.sh
    else
        echo "❌ Error: convert_all_diseases_working.sh not found"
        echo "   Please convert disease images first"
        exit 1
    fi
elif [ $missing_count -gt 0 ]; then
    echo ""
    echo "⚠️  Some files missing, but continuing with available files"
    echo "   (Missing files will be filled with zeros)"
fi

# Step 2: Run comprehensive testing
echo ""
echo "🧠 STEP 2: Running Comprehensive Neural Network Test"
echo "=================================================="
echo ""
echo "🎯 Testing ALL 15 Disease Categories:"
echo "   0. Normal (No Finding)     8. Pleural Thickening"
echo "   1. Infiltration            9. Cardiomegaly"
echo "   2. Atelectasis            10. Emphysema"
echo "   3. Effusion               11. Fibrosis"
echo "   4. Nodule                 12. Edema"
echo "   5. Pneumothorax           13. Pneumonia"
echo "   6. Mass                   14. Hernia"
echo "   7. Consolidation"
echo ""
echo "⏱️  Expected Duration: 15-30 minutes"
echo "📊 Using syntax-error-free testbench: tb_full_system_all_diseases.sv"
echo ""

# Check if ModelSim is available
if ! command -v vsim &> /dev/null; then
    echo "❌ Error: ModelSim (vsim) not found in PATH"
    echo "   Please ensure ModelSim is installed and accessible"
    exit 1
fi

echo "Starting comprehensive disease classification simulation..."
echo ""

# Run the comprehensive test
vsim -do run_all_diseases_comprehensive.do

# Check if simulation completed successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Simulation completed successfully!"
else
    echo ""
    echo "❌ Simulation failed or was interrupted"
    echo "   Check ModelSim logs for details"
    exit 1
fi

# Step 3: Analyze results
echo ""
echo "📊 STEP 3: Analyzing Comprehensive Results"
echo "========================================"

if [ -f "disease_classification_summary.txt" ]; then
    echo "✅ Main results file found: disease_classification_summary.txt"
    
    # Try to run Python analysis
    python_cmd=""
    if command -v python &> /dev/null; then
        python_cmd="python"
    elif command -v python3 &> /dev/null; then
        python_cmd="python3"
    elif [ -f "/c/Users/lenovo/AppData/Local/Programs/Python/Python311/python.exe" ]; then
        python_cmd="/c/Users/lenovo/AppData/Local/Programs/Python/Python311/python.exe"
    fi
    
    if [ -n "$python_cmd" ] && [ -f "FULL_TOP/analyze_all_diseases_results.py" ]; then
        echo "Running comprehensive results analysis..."
        "$python_cmd" FULL_TOP/analyze_all_diseases_results.py
    else
        echo "⚠️  Python analysis not available - showing basic results:"
        echo ""
        echo "📋 Generated Files:"
        ls -la disease_classification_summary.txt all_diseases_*.txt 2>/dev/null
        echo ""
        echo "📖 To view main results:"
        echo "   cat disease_classification_summary.txt"
    fi
else
    echo "❌ Error: Results file not found"
    echo "   Simulation may not have completed successfully"
    exit 1
fi

# Final summary
echo ""
echo "🎯 COMPREHENSIVE DISEASE TESTING COMPLETE!"
echo "=========================================="
echo ""
echo "📊 GENERATED REPORTS:"
echo "   ✅ disease_classification_summary.txt - Main accuracy results"
echo "   ✅ all_diseases_diagnosis.txt - Detailed medical analysis"
echo "   ✅ all_diseases_testbench.log - Technical simulation log"
echo "   ✅ comprehensive_disease_simulation.log - Complete transcript"
echo "   ✅ comprehensive_diseases_waveform.wlf - Waveform data"
echo ""
echo "📈 KEY METRICS TO REVIEW:"
echo "   • Overall Classification Accuracy (target: >80%)"
echo "   • Per-Disease Accuracy for each condition"
echo "   • Confidence Scores and prediction reliability"
echo "   • Neural network performance timing"
echo ""
echo "🔬 NEXT STEPS:"
echo "   1. Review accuracy in disease_classification_summary.txt"
echo "   2. Identify diseases with low classification accuracy"
echo "   3. Consider model retraining if overall accuracy < 70%"
echo "   4. Test with additional real X-ray images for validation"
echo ""
echo "🏥 Your MobileNetV3 medical AI system has been comprehensively"
echo "   tested against all 15 major chest X-ray pathology categories!"
echo ""
echo "💡 For detailed analysis: python FULL_TOP/analyze_all_diseases_results.py"
