# Simple test for new final layer
quit -sim
vdel -all
vlib work
vmap work work

echo "Testing NEW Final Layer..."

# Compile only essential files
vlog -sv final_layer/final_layer_top.sv

# Create simple testbench
vlog -sv -timescale=1ns/1ps << 'EOF'
module test_final_layer;
    reg clk = 0;
    reg rst = 1;
    reg en = 1;
    reg valid_in = 0;
    reg [15:0] data_in = 16'h1234;
    reg [3:0] channel_in = 0;
    reg [7:0] row_in = 10;
    reg [7:0] col_in = 20;
    
    wire signed [15*16-1:0] class_scores;
    wire valid_out;
    wire done;
    
    always #5 clk = ~clk;
    
    final_layer_top dut (
        .clk(clk), .rst(rst), .en(en),
        .valid_in(valid_in), .data_in(data_in),
        .channel_in(channel_in), .row_in(row_in), .col_in(col_in),
        .class_scores(class_scores), .valid_out(valid_out), .done(done)
    );
    
    initial begin
        #20 rst = 0;
        #10 valid_in = 1;
        
        // Send some data
        repeat(20) begin
            data_in = data_in + 16'h0100;
            #10;
        end
        
        valid_in = 0;
        
        // Wait for result
        wait(valid_out);
        
        $display("SUCCESS: New final layer generated output!");
        $display("Pneumonia score: 0x%04x", class_scores[13*16 +: 16]);
        $display("No Finding score: 0x%04x", class_scores[0*16 +: 16]);
        
        #100;
        $finish;
    end
    
    initial begin
        #10000;
        $display("TIMEOUT: Test failed");
        $finish;
    end
endmodule
EOF

echo "Running test..."
vsim -c work.test_final_layer
run -all
