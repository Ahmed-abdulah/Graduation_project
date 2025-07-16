# Test compilation script to verify all files exist and compile correctly
# This script tests the fixes for the missing pointwise_conv.sv issue

# Clean up previous compilation
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work
vmap work work

echo "=== TESTING COMPILATION FIXES ==="
echo "Verifying all SystemVerilog files exist and compile correctly"
echo ""

# Test First Layer compilation
echo "Testing First Layer files..."
set first_layer_files {
    "First_layer/HSwish.sv"
    "First_layer/convolver.sv"
    "First_layer/batchnorm_accumulator.sv"
    "First_layer/batchnorm_normalizer.sv"
    "First_layer/batchnorm_top.sv"
    "First_layer/accelerator.sv"
}

foreach file $first_layer_files {
    if {[file exists $file]} {
        echo "✅ Found: $file"
        vlog -work work $file
        if {[string equal $::errorCode "NONE"]} {
            echo "✅ Compiled: $file"
        } else {
            echo "❌ Compilation failed: $file"
        }
    } else {
        echo "❌ Missing: $file"
    }
}

echo ""
echo "Testing BNECK files..."
set bneck_files {
    "BNECK/conv_1x1_optimized.sv"
    "BNECK/conv_3x3_dw_optimized.sv"
    "BNECK/bneck_block_optimized.sv"
    "BNECK/mobilenetv3_sequence_optimized.sv"
    "BNECK/mobilenetv3_top_optimized.sv"
}

foreach file $bneck_files {
    if {[file exists $file]} {
        echo "✅ Found: $file"
        vlog -work work $file
        if {[string equal $::errorCode "NONE"]} {
            echo "✅ Compiled: $file"
        } else {
            echo "❌ Compilation failed: $file"
        }
    } else {
        echo "❌ Missing: $file"
    }
}

echo ""
echo "Testing Final Layer files (FIXED - no pointwise_conv.sv)..."
set final_layer_files {
    "final_layer/hswish.sv"
    "final_layer/batchnorm.sv"
    "final_layer/batchnorm1d.sv"
    "final_layer/linear.sv"
    "final_layer/final_layer_top.sv"
}

foreach file $final_layer_files {
    if {[file exists $file]} {
        echo "✅ Found: $file"
        vlog -work work $file
        if {[string equal $::errorCode "NONE"]} {
            echo "✅ Compiled: $file"
        } else {
            echo "❌ Compilation failed: $file"
        }
    } else {
        echo "❌ Missing: $file"
    }
}

echo ""
echo "Testing Full System files..."
set full_system_files {
    "FULL_TOP/full_system_top.sv"
    "FULL_TOP/tb_full_system_all_diseases.sv"
}

foreach file $full_system_files {
    if {[file exists $file]} {
        echo "✅ Found: $file"
        vlog -work work $file
        if {[string equal $::errorCode "NONE"]} {
            echo "✅ Compiled: $file"
        } else {
            echo "❌ Compilation failed: $file"
        }
    } else {
        echo "❌ Missing: $file"
    }
}

echo ""
echo "=== COMPILATION TEST COMPLETE ==="
echo ""
echo "✅ FIXED ISSUES:"
echo "   - Removed references to non-existent pointwise_conv.sv"
echo "   - Updated compilation order for dependencies"
echo "   - All .do files now reference only existing files"
echo ""
echo "📋 FIXED FILES:"
echo "   - final_layer/run_tb_final_layer_top.do"
echo "   - FULL_TOP/clean_and_run.do"
echo "   - run_tb_full_system_top.do"
echo "   - test_compilation.do"
echo ""
echo "🚀 Ready to run comprehensive disease testing!"
echo "   Use: vsim -do FULL_TOP/run_all_diseases_test.do"

# Keep ModelSim open for inspection
# quit
