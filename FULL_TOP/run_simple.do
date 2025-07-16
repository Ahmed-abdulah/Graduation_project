# Simple Test Script - Complete and Working

echo "🏥 SIMPLE MEDICAL AI TEST"
echo "========================"

# Clean start
quit -sim
if {[file exists work]} {vdel -lib work -all}
vlib work

echo "Compiling ALL required files..."

# First Layer components (COMPLETE)
echo "Compiling First Layer..."
vlog First_layer/accelerator.sv
vlog First_layer/batchnorm_accumulator.sv
vlog First_layer/batchnorm_normalizer.sv
vlog First_layer/batchnorm_top.sv
vlog First_layer/convolver.sv
vlog First_layer/HSwish.sv

# BNECK components (COMPLETE - this was missing!)
echo "Compiling BNECK components..."
vlog BNECK/conv_1x1_real_weights.sv
vlog BNECK/conv_3x3_dw_real_weights.sv
vlog BNECK/bneck_block_real_weights.sv
vlog BNECK/mobilenetv3_top_real_weights.sv

# Final Layer components (COMPLETE)
echo "Compiling Final Layer..."
vlog final_layer/hswish.sv
vlog final_layer/batchnorm.sv
vlog final_layer/batchnorm1d.sv
vlog final_layer/linear.sv
vlog final_layer/final_layer_top.sv

# Top level and testbench
echo "Compiling System..."
vlog full_system_top.sv
vlog tb_simple_test.sv

echo "✅ Compiled"

# Create test image if needed
if {![file exists "test_image.mem"]} {
    echo "Creating test image..."
    set fp [open "test_image.mem" w]
    for {set i 0} {$i < 50176} {incr i} {
        puts $fp [format "%04x" [expr {4096 + ($i % 256)}]]
    }
    close $fp
    echo "✅ Test image created"
}

echo "🚀 Running test..."
vsim -t 1ps tb_simple_test
run -all

echo "✅ Done!"
