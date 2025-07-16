#!/bin/bash

echo "TESTING IMPROVED WEIGHT FIX WITH DEBUG"
echo "======================================"
echo ""
echo "IMPROVEMENTS MADE:"
echo "1. Fixed array size: linear_weights[0:19200] (was 1279)"
echo "2. Fixed weight indexing: proper linear layer computation"
echo "3. Fixed signed arithmetic and scaling"
echo "4. Added detailed debug output"
echo ""

# Test with pneumonia image
if [ -f "real_pneumonia_xray.mem" ]; then
    echo "Testing with pneumonia image..."
    cp real_pneumonia_xray.mem test_image.mem
    
    echo "Running test with improved debug output..."
    cd FULL_TOP
    
    # Run quick test with more verbose output
    vsim -c -do "
    vlib work;
    vlog -work work ../First_layer/*.sv;
    vlog -work work ../BNECK/*.sv;
    vlog -work work ../final_layer/*.sv;
    vlog -work work full_system_top.sv;
    vlog -work work tb_full_system_top.sv;
    vsim tb_full_system_top;
    run -all;
    quit -f" > ../test_debug_output.log 2>&1
    
    cd ..
    
    echo ""
    echo "=== DEBUG OUTPUT ANALYSIS ==="
    echo ""
    
    # Check if weights were loaded
    if grep -q "Loaded real trained weights" test_debug_output.log; then
        echo "✅ Weights loaded successfully"
        grep "Sample weights:" test_debug_output.log
        grep "Sample biases:" test_debug_output.log
    else
        echo "❌ Weights not loaded"
    fi
    
    # Check accumulator values
    echo ""
    echo "Accumulator values:"
    grep "Accumulator\[" test_debug_output.log | tail -1
    
    # Check bias values
    echo ""
    echo "Bias values:"
    grep "Bias\[" test_debug_output.log | tail -1
    
    # Check final scores
    echo ""
    echo "Final scores:"
    grep "score:" test_debug_output.log | tail -3
    
    # Check if all scores are still zero
    if grep -q "score: 0x0000 (0)" test_debug_output.log; then
        echo ""
        echo "❌ PROBLEM: Scores are still zero!"
        echo "   This indicates either:"
        echo "   1. Accumulator is zero (no data flowing)"
        echo "   2. Weights are zero"
        echo "   3. Computation logic error"
    else
        echo ""
        echo "✅ IMPROVEMENT: Scores are non-zero!"
    fi
    
    echo ""
    echo "📋 Full debug log saved to: test_debug_output.log"
    echo "📋 To view full log: cat test_debug_output.log"
    
else
    echo "❌ Error: real_pneumonia_xray.mem not found"
    echo "   Run: ./convert_all_diseases_working.sh first"
fi

echo ""
echo "🔧 If scores are still zero, the issue is likely:"
echo "   1. BNECK outputting zeros (fake weights problem)"
echo "   2. Data flow issue between layers"
echo "   3. Weight file format mismatch"
