# Simple compilation test script
quit -sim
vlib work
vmap work work

# Compile the fixed files
echo "Testing compilation of fixed files..."

# First Layer components
vlog -sv First_layer/accelerator.sv
vlog -sv First_layer/batchnorm_accumulator.sv
vlog -sv First_layer/batchnorm_normalizer.sv
vlog -sv First_layer/batchnorm_top.sv
vlog -sv First_layer/convolver.sv
vlog -sv First_layer/HSwish.sv

# BNeck components
vlog -sv BNECK/bneck_block_optimized.sv
vlog -sv BNECK/conv_1x1_optimized.sv
vlog -sv BNECK/conv_3x3_dw_optimized.sv
vlog -sv BNECK/mobilenetv3_top_optimized.sv

# Final Layer components
vlog -sv final_layer/hswish.sv
vlog -sv final_layer/batchnorm.sv
vlog -sv final_layer/batchnorm1d.sv
vlog -sv final_layer/linear.sv
vlog -sv final_layer/final_layer_top.sv

# Full System Top
vlog -sv FULL_TOP/full_system_top.sv

# Testbench
vlog -sv FULL_TOP/tb_full_system_top.sv

echo "Compilation test completed!" 