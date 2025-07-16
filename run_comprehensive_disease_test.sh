#!/bin/bash

echo "🏥 COMPREHENSIVE DISEASE CLASSIFICATION TEST SUITE"
echo "=" * 60
echo "This script will:"
echo "1. Convert all disease images to memory files"
echo "2. Run comprehensive neural network testing"
echo "3. Analyze and report results"
echo "=" * 60

# Step 1: Convert all disease images
echo ""
echo "📸 STEP 1: Converting Disease Images"
echo "=" * 40

if [ -f "convert_all_diseases_working.sh" ]; then
    echo "Running disease image conversion..."
    ./convert_all_diseases_working.sh
    
    # Check conversion results
    converted_count=$(ls real_*_xray.mem 2>/dev/null | wc -l)
    echo ""
    echo "Conversion Results: $converted_count/15 disease files created"
    
    if [ $converted_count -lt 10 ]; then
        echo "⚠️  Warning: Only $converted_count disease files found"
        echo "   Some tests may be skipped"
    else
        echo "✅ Good: $converted_count disease files ready for testing"
    fi
else
    echo "❌ Error: convert_all_diseases_working.sh not found"
    echo "   Please run the conversion script first"
    exit 1
fi

# Step 2: Run comprehensive testing
echo ""
echo "🧠 STEP 2: Running Neural Network Tests"
echo "=" * 40

if [ -d "FULL_TOP" ]; then
    cd FULL_TOP
    
    echo "Starting comprehensive disease classification test..."
    echo "This may take 15-30 minutes depending on your system"
    echo ""
    
    # Run ModelSim simulation
    if command -v vsim &> /dev/null; then
        echo "Running ModelSim simulation..."
        vsim -c -do run_all_diseases_test.do
        
        if [ $? -eq 0 ]; then
            echo "✅ Simulation completed successfully"
        else
            echo "❌ Simulation failed or was interrupted"
            echo "   Check ModelSim logs for details"
            cd ..
            exit 1
        fi
    else
        echo "❌ Error: ModelSim (vsim) not found"
        echo "   Please ensure ModelSim is installed and in PATH"
        cd ..
        exit 1
    fi
    
    cd ..
else
    echo "❌ Error: FULL_TOP directory not found"
    exit 1
fi

# Step 3: Analyze results
echo ""
echo "📊 STEP 3: Analyzing Results"
echo "=" * 40

if [ -f "disease_classification_summary.txt" ]; then
    echo "Running results analysis..."
    
    # Try different Python commands
    if command -v python &> /dev/null; then
        python FULL_TOP/analyze_all_diseases_results.py
    elif command -v python3 &> /dev/null; then
        python3 FULL_TOP/analyze_all_diseases_results.py
    elif [ -f "/c/Users/lenovo/AppData/Local/Programs/Python/Python311/python.exe" ]; then
        "/c/Users/lenovo/AppData/Local/Programs/Python/Python311/python.exe" FULL_TOP/analyze_all_diseases_results.py
    else
        echo "⚠️  Python not found - showing basic results:"
        echo ""
        echo "📋 Generated Files:"
        ls -la disease_classification_summary.txt all_diseases_*.txt 2>/dev/null
        echo ""
        echo "📖 To view results manually:"
        echo "   cat disease_classification_summary.txt"
    fi
else
    echo "❌ Error: Results file not found"
    echo "   Simulation may not have completed successfully"
    exit 1
fi

# Final summary
echo ""
echo "🎯 COMPREHENSIVE TEST COMPLETE!"
echo "=" * 40
echo ""
echo "📊 Results Files Generated:"
echo "   ✅ disease_classification_summary.txt - Main results and accuracy"
echo "   ✅ all_diseases_diagnosis.txt - Detailed medical analysis"
echo "   ✅ all_diseases_testbench.log - Technical simulation log"
echo ""
echo "📈 Key Metrics to Check:"
echo "   1. Overall Accuracy (target: >80%)"
echo "   2. Per-disease classification accuracy"
echo "   3. Simulation performance (cycles)"
echo "   4. Confidence scores for each prediction"
echo ""
echo "🔬 Next Steps:"
echo "   1. Review accuracy results in summary file"
echo "   2. Identify diseases with low accuracy"
echo "   3. Consider model retraining if accuracy < 70%"
echo "   4. Test with additional real X-ray images"
echo ""
echo "💡 For detailed analysis:"
echo "   python FULL_TOP/analyze_all_diseases_results.py"
echo ""
echo "🏥 Medical AI Testing Suite Complete! 🏥"
