`timescale 1ns/1ps

module tb_simple_test;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FRAC = 8;
    parameter IMG_SIZE = 224;
    parameter NUM_CLASSES = 15;

    // Disease names
    string diseases [0:14] = {
        "No Finding", "Infiltration", "Atelectasis", "Effusion", "Nodule",
        "Pneumothorax", "Mass", "Consolidation", "Pleural Thickening", 
        "Cardiomegaly", "Emphysema", "Fibrosis", "Edema", "Pneumonia", "Hernia"
    };

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk; // 100MHz

    // DUT signals
    reg en = 0;
    reg [DATA_WIDTH-1:0] pixel_in = 0;
    wire signed [NUM_CLASSES*DATA_WIDTH-1:0] class_scores;
    wire valid_out;

    // Test control
    integer pixel_count = 0;
    integer cycle_count = 0;
    reg [DATA_WIDTH-1:0] test_image [0:50175]; // 224*224 = 50176

    // DUT instantiation
    full_system_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC),
        .IN_CHANNELS(1),
        .FIRST_OUT_CHANNELS(16),
        .BNECK_OUT_CHANNELS(16),
        .FINAL_NUM_CLASSES(NUM_CLASSES),
        .IMG_SIZE(IMG_SIZE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .pixel_in(pixel_in),
        .class_scores(class_scores),
        .valid_out(valid_out)
    );

    // Load test image
    initial begin
        if ($test$plusargs("image")) begin
            $readmemh("test_image.mem", test_image);
            $display("✅ Loaded test_image.mem");
        end else begin
            // Create simple test pattern
            for (int i = 0; i < 50176; i++) begin
                test_image[i] = 16'h1000 + (i % 256);
            end
            $display("✅ Created default test pattern");
        end
    end

    // Main test
    initial begin
        $display("🏥 SIMPLE MEDICAL AI TEST");
        $display("========================");
        
        // Reset
        #100;
        rst = 0;
        #50;
        
        $display("🚀 Processing X-ray image...");
        
        // Send pixels
        en = 1;
        for (int i = 0; i < 50176; i++) begin
            pixel_in = test_image[i];
            @(posedge clk);
            pixel_count++;
            
            if (i % 10000 == 0) begin
                $display("Progress: %0d/50176 pixels", i);
            end
        end
        
        $display("✅ All pixels sent");
        en = 0;
        
        // Wait for result
        $display("⏳ Waiting for neural network...");
        wait(valid_out);
        
        // Show results
        $display("");
        $display("🎯 RESULTS:");
        $display("===========");
        
        // Find max score
        integer max_class = 0;
        logic signed [DATA_WIDTH-1:0] max_score = class_scores[15:0];
        
        for (int i = 1; i < NUM_CLASSES; i++) begin
            logic signed [DATA_WIDTH-1:0] current_score = class_scores[i*DATA_WIDTH +: DATA_WIDTH];
            if (current_score > max_score) begin
                max_score = current_score;
                max_class = i;
            end
        end
        
        // Display all scores
        for (int i = 0; i < NUM_CLASSES; i++) begin
            logic signed [DATA_WIDTH-1:0] score = class_scores[i*DATA_WIDTH +: DATA_WIDTH];
            string marker = (i == max_class) ? " ← PREDICTED" : "";
            $display("Class %2d (%s): %0d%s", i, diseases[i], score, marker);
        end
        
        $display("");
        $display("🏆 DIAGNOSIS: %s", diseases[max_class]);
        $display("📊 CONFIDENCE: %0d", max_score);
        $display("⏱️ CYCLES: %0d", cycle_count);
        $display("🚀 THROUGHPUT: %.1f images/sec", 100000000.0 / cycle_count);
        
        $display("");
        $display("✅ TEST COMPLETE");
        $finish;
    end

    // Cycle counter
    always @(posedge clk) begin
        if (!rst) cycle_count <= cycle_count + 1;
    end

endmodule
