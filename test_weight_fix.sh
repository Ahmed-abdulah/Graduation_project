#!/bin/bash

echo "TESTING WEIGHT LOADING FIX"
echo "=========================="
echo ""
echo "CHANGES MADE:"
echo "1. First Layer: Already uses real weights"
echo "2. BNECK: Still uses fake weights (optimized versions)"
echo "3. Final Layer: NOW USES REAL WEIGHTS (FIXED!)"
echo ""
echo "Expected improvement: Better than 6.67% but not perfect"
echo "Perfect accuracy requires fixing BNECK weights too"
echo ""

# Test with a single disease first
echo "Testing with pneumonia image..."
if [ -f "real_pneumonia_xray.mem" ]; then
    cp real_pneumonia_xray.mem test_image.mem
    echo "Running quick test..."
    
    # Run a quick test
    cd FULL_TOP
    vsim -c -do "
    vlib work;
    vlog -work work ../First_layer/*.sv;
    vlog -work work ../BNECK/*.sv;
    vlog -work work ../final_layer/*.sv;
    vlog -work work full_system_top.sv;
    vlog -work work tb_full_system_top.sv;
    vsim tb_full_system_top;
    run -all;
    quit -f"
    cd ..
    
    echo ""
    echo "Check the output to see if final layer now shows:"
    echo "'REAL WEIGHTS FINAL LAYER: Generated medical predictions using trained weights'"
    echo ""
    echo "If accuracy improves from 6.67%, the fix is working!"
    echo "For perfect accuracy, BNECK weights also need to be fixed."
else
    echo "Error: real_pneumonia_xray.mem not found"
    echo "Run: ./convert_all_diseases_working.sh first"
fi
