# DEBUG TEST - FOCUS ON THE CORE ISSUES
# This will help us identify exactly what's wrong

echo "🔍 DEBUG TEST - FINDING THE REAL PROBLEM"
echo "========================================"

# Clean start
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Go to parent directory
cd ..

# Create a simple test pattern
echo "Creating test pattern..."
set fp [open test_image.mem w]
for {set i 0} {$i < 100} {incr i} {
    puts $fp [format "%04x" [expr 0x1000 + $i]]
}
close $fp

# Compile only what we need
echo "Compiling minimal system..."
vlog -work work First_layer/accelerator.sv
vlog -work work BNECK/mobilenetv3_top_real_weights.sv  
vlog -work work final_layer/final_layer_top.sv
vlog -work work FULL_TOP/full_system_top.sv

# Create a minimal testbench
echo "Creating minimal testbench..."
set fp [open minimal_tb.sv w]
puts $fp {
module minimal_tb;
    reg clk = 0;
    reg rst = 1;
    reg en = 0;
    reg [15:0] pixel_in = 16'h1234;
    wire [239:0] class_scores;
    wire valid_out;
    
    always #5 clk = ~clk;
    
    full_system_top dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .pixel_in(pixel_in),
        .class_scores(class_scores),
        .valid_out(valid_out)
    );
    
    initial begin
        $display("=== MINIMAL DEBUG TEST ===");
        #20 rst = 0;
        #10 en = 1;
        pixel_in = 16'h1234;
        
        wait(valid_out);
        $display("Output received!");
        
        // Check scores
        for (int i = 0; i < 15; i++) begin
            $display("Class %0d: 0x%04x (%0d)", i, 
                    class_scores[i*16 +: 16], 
                    class_scores[i*16 +: 16]);
        end
        
        // Find max manually
        reg [15:0] max_score = 0;
        reg [3:0] max_class = 0;
        for (int i = 0; i < 15; i++) begin
            if (class_scores[i*16 +: 16] > max_score) begin
                max_score = class_scores[i*16 +: 16];
                max_class = i;
            end
        end
        
        $display("MANUAL MAX: Class %0d with score %0d", max_class, max_score);
        
        if (max_class != 0) begin
            $display("✅ SUCCESS: Not predicting Class 0!");
        end else begin
            $display("❌ PROBLEM: Still predicting Class 0");
        end
        
        #100 $finish;
    end
endmodule
}
close $fp

vlog -work work minimal_tb.sv

echo "Running minimal test..."
vsim minimal_tb
run -all

echo ""
echo "🎯 MINIMAL TEST COMPLETE!"
echo "This shows exactly what the neural network is doing."

quit -sim
