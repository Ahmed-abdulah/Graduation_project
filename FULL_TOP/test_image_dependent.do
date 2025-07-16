# TEST IMAGE-DEPENDENT PROCESSING
# This will verify that different images produce different predictions

echo "🔍 TESTING IMAGE-DEPENDENT PROCESSING"
echo "====================================="
echo ""
echo "This test will:"
echo "1. Test the same disease (pneumonia) with different input patterns"
echo "2. Verify that different inputs produce different scores"
echo "3. Check that predictions vary based on input image"
echo ""

# Clean start
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Go to parent directory
cd ..

# Create different test patterns to simulate different X-ray images
echo "Creating different test patterns..."

# Pattern 1: Low values (simulating normal lung)
set fp [open test_pattern_1.mem w]
for {set i 0} {$i < 1000} {incr i} {
    puts $fp [format "%04x" [expr 0x0100 + ($i % 256)]]
}
close $fp

# Pattern 2: High values (simulating diseased lung)
set fp [open test_pattern_2.mem w]
for {set i 0} {$i < 1000} {incr i} {
    puts $fp [format "%04x" [expr 0x0800 + ($i % 512)]]
}
close $fp

# Pattern 3: Mixed values (simulating different disease)
set fp [open test_pattern_3.mem w]
for {set i 0} {$i < 1000} {incr i} {
    puts $fp [format "%04x" [expr 0x0400 + (($i * 3) % 1024)]]
}
close $fp

# Compile system
echo "Compiling system..."
vlog First_layer/accelerator.sv
vlog BNECK/mobilenetv3_top_real_weights.sv
vlog final_layer/final_layer_top.sv
vlog FULL_TOP/full_system_top.sv
vlog FULL_TOP/tb_full_system_top.sv

echo "✅ System compiled"
echo ""

# Test Pattern 1
echo "🧪 Testing Pattern 1 (Low values - Normal lung simulation)..."
file copy -force test_pattern_1.mem test_image.mem
vsim -c tb_full_system_top
run -all
quit -sim

echo ""

# Test Pattern 2  
echo "🧪 Testing Pattern 2 (High values - Diseased lung simulation)..."
file copy -force test_pattern_2.mem test_image.mem
vsim -c tb_full_system_top
run -all
quit -sim

echo ""

# Test Pattern 3
echo "🧪 Testing Pattern 3 (Mixed values - Different disease simulation)..."
file copy -force test_pattern_3.mem test_image.mem
vsim -c tb_full_system_top
run -all
quit -sim

echo ""
echo "🎯 IMAGE-DEPENDENT TEST COMPLETE!"
echo ""
echo "✅ SUCCESS INDICATORS:"
echo "1. Different BNECK outputs for each pattern"
echo "2. Different final scores for each pattern"
echo "3. Different predictions (not always Hernia)"
echo ""
echo "❌ FAILURE INDICATORS:"
echo "1. Same scores for all patterns"
echo "2. Always predicting the same disease"
echo "3. BNECK outputs don't vary with input"
echo ""
echo "If successful, run the full 15-disease test:"
echo "   do comprehensive_test.do"
