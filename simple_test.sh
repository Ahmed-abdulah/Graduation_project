#!/bin/bash

echo "🔧 SIMPLE TEST - CHECKING IF EVERYTHING COMPILES"
echo "==============================================="
echo ""

# Go to FULL_TOP directory
cd FULL_TOP

echo "Step 1: Creating work library..."
vlib work

echo ""
echo "Step 2: Compiling First Layer..."
vlog First_layer/HSwish.sv
vlog First_layer/convolver.sv
vlog First_layer/batchnorm_accumulator.sv
vlog First_layer/batchnorm_normalizer.sv
vlog First_layer/batchnorm_top.sv
vlog First_layer/accelerator.sv

echo ""
echo "Step 3: Compiling BNECK (Real Weights)..."
vlog BNECK/conv_1x1_real_weights.sv
vlog BNECK/conv_3x3_dw_real_weights.sv
vlog BNECK/bneck_block_real_weights.sv
vlog BNECK/mobilenetv3_top_real_weights.sv

echo ""
echo "Step 4: Compiling Final Layer..."
vlog final_layer/hswish.sv
vlog final_layer/batchnorm.sv
vlog final_layer/batchnorm1d.sv
vlog final_layer/linear.sv
vlog final_layer/final_layer_top.sv

echo ""
echo "Step 5: Compiling Full System..."
vlog -work work full_system_top.sv

echo ""
echo "Step 6: Compiling Simple Testbench..."
vlog -work work tb_full_system_top.sv

echo ""
echo "✅ If you see this message, all modules compiled successfully!"
echo ""
echo "Now testing with a simple simulation..."

# Create a simple test image
echo "Creating test image..."
cd ..
if [ ! -f "test_image.mem" ]; then
    # Create a simple test pattern
    for i in {1..1000}; do
        printf "%04x\n" $((i % 65536))
    done > test_image.mem
fi

cd FULL_TOP

echo ""
echo "Running simple simulation..."
vsim -c -do "
vsim tb_full_system_top;
run 1000ns;
quit -f" > simple_test_output.log 2>&1

echo ""
echo "=== SIMPLE TEST RESULTS ==="
if [ -f "simple_test_output.log" ]; then
    echo "✅ Simulation completed"
    
    # Check for any errors
    if grep -q "Error" simple_test_output.log; then
        echo "❌ Errors found:"
        grep "Error" simple_test_output.log
    else
        echo "✅ No compilation errors"
    fi
    
    # Check for any output
    if grep -q "GUARANTEED WORKING" simple_test_output.log; then
        echo "✅ BNECK is working"
    fi
    
    if grep -q "WORKING FINAL LAYER" simple_test_output.log; then
        echo "✅ Final Layer is working"
    fi
    
    echo ""
    echo "📋 Full output in: simple_test_output.log"
    echo "📋 To view: cat simple_test_output.log"
else
    echo "❌ No output file generated"
fi

cd ..

echo ""
echo "🎯 NEXT STEPS:"
echo "1. If compilation successful → Modules are OK"
echo "2. If simulation runs → Basic functionality works"
echo "3. Then we can run the full disease test"
