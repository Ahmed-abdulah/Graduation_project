#!/bin/bash

echo "🔧 TESTING PIPELINE FIX"
echo "======================"
echo ""
echo "FIXES APPLIED:"
echo "1. ✅ Simplified BNECK state machines (no more hanging)"
echo "2. ✅ Direct data flow through pipeline"
echo "3. ✅ Real weights still used (0xffb6 visible in debug)"
echo "4. ✅ Fixed output generation"
echo ""

# Test with pneumonia
if [ -f "real_pneumonia_xray.mem" ]; then
    echo "Testing with pneumonia image..."
    cp real_pneumonia_xray.mem test_image.mem
    
    echo "Running quick test..."
    cd FULL_TOP
    
    vsim -c -do "
    vlib work;
    vlog -work work ../First_layer/*.sv;
    vlog -work work ../BNECK/conv_1x1_real_weights.sv;
    vlog -work work ../BNECK/conv_3x3_dw_real_weights.sv;
    vlog -work work ../BNECK/bneck_block_real_weights.sv;
    vlog -work work ../BNECK/mobilenetv3_top_real_weights.sv;
    vlog -work work ../final_layer/*.sv;
    vlog -work work full_system_top.sv;
    vlog -work work tb_full_system_top.sv;
    vsim tb_full_system_top;
    run -all;
    quit -f" > ../pipeline_fix_test.log 2>&1
    
    cd ..
    
    echo ""
    echo "=== PIPELINE FIX TEST RESULTS ==="
    
    # Check if it completes without hanging
    if grep -q "RESULT:" pipeline_fix_test.log; then
        echo "✅ SUCCESS: Pipeline completed without hanging!"
        echo ""
        echo "Results:"
        grep "RESULT:" pipeline_fix_test.log
        grep "Expected:" pipeline_fix_test.log
        grep "Predicted:" pipeline_fix_test.log
        grep "Confidence:" pipeline_fix_test.log
    else
        echo "❌ Pipeline still hanging or not completing"
    fi
    
    # Check for real weights usage
    if grep -q "REAL WEIGHTS" pipeline_fix_test.log; then
        echo "✅ Real weights are being used"
    else
        echo "❌ Real weights not detected"
    fi
    
    echo ""
    echo "📋 Full log: pipeline_fix_test.log"
    
else
    echo "❌ real_pneumonia_xray.mem not found"
fi

echo ""
echo "🎯 If test shows completion, run full comprehensive test:"
echo "   ./run_comprehensive_test.sh"
