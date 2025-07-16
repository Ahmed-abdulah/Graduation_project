# Simple test for first layer only
quit -sim
vlib work
vmap work work

# Compile first layer only
vlog -sv First_layer/accelerator.sv
vlog -sv First_layer/batchnorm_accumulator.sv
vlog -sv First_layer/batchnorm_normalizer.sv
vlog -sv First_layer/batchnorm_top.sv
vlog -sv First_layer/convolver.sv
vlog -sv First_layer/HSwish.sv

# Simple testbench for first layer
vlog -sv test_first_layer.sv

# Run simulation
vsim -t ps -novopt work.test_first_layer
run -all 