`timescale 1ns/1ps

module tb_single_test;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FRAC = 8;
    parameter IN_CHANNELS = 1;
    parameter FIRST_OUT_CHANNELS = 16;
    parameter BNECK_OUT_CHANNELS = 16;
    parameter FINAL_NUM_CLASSES = 15;
    parameter IMG_SIZE = 224;

    // Medical condition class names
    string medical_conditions [0:14] = {
        "No Finding", "Infiltration", "Atelectasis", "Effusion", "Nodule",
        "Pneumothorax", "Mass", "Consolidation", "Pleural Thickening", 
        "Cardiomegaly", "Emphysema", "Fibrosis", "Edema", "Pneumonia", "Hernia"
    };

    // Medical recommendations
    string medical_recommendations [0:14] = {
        "The X-ray appears normal. Continue regular health checkups.",
        "Possible fluid or infection in lungs. Consult a pulmonologist.",
        "Partial lung collapse suspected. Immediate evaluation is advised.",
        "Fluid around lungs detected. You should see a physician promptly.",
        "A small spot was found. Further imaging or biopsy may be required.",
        "Air in lung cavity. This could be urgent – seek ER care.",
        "Abnormal tissue detected. Specialist referral is needed.",
        "Signs of infection or pneumonia. Medical evaluation required.",
        "Scarring detected. Monitor regularly with your doctor.",
        "Heart appears enlarged. Cardiologist follow-up recommended.",
        "Signs of chronic lung disease. Pulmonary care advised.",
        "Lung scarring seen. Long-term monitoring may be needed.",
        "Fluid buildup in lungs. Heart function check is essential.",
        "Infection detected. Prompt antibiotic treatment recommended.",
        "Possible diaphragm hernia. Consult a surgeon for evaluation."
    };

    // Function to convert fixed-point to probability
    function automatic real fixed_to_probability(input logic signed [DATA_WIDTH-1:0] fixed_val);
        real temp_real;
        temp_real = real'($signed(fixed_val)) / 256.0;
        if (temp_real > 5.0) temp_real = 1.0;
        else if (temp_real < -5.0) temp_real = 0.0;
        else temp_real = 1.0 / (1.0 + $exp(-temp_real));
        return temp_real;
    endfunction

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk; // 100MHz

    // DUT signals
    reg en = 0;
    reg [DATA_WIDTH-1:0] pixel_in;
    wire signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] class_scores;
    wire valid_out;

    // Test data
    reg [DATA_WIDTH-1:0] test_image [0:IMG_SIZE*IMG_SIZE-1];
    integer current_pixel = 0;
    integer cycle_count = 0;
    integer pixel_count = 0;

    // DUT instantiation
    full_system_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC),
        .IN_CHANNELS(IN_CHANNELS),
        .FIRST_OUT_CHANNELS(FIRST_OUT_CHANNELS),
        .BNECK_OUT_CHANNELS(BNECK_OUT_CHANNELS),
        .FINAL_NUM_CLASSES(FINAL_NUM_CLASSES),
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
        $display("Loading test image from test_image.mem...");
        $readmemh("test_image.mem", test_image);
        $display("Test image loaded successfully");
    end

    // Main test sequence
    initial begin
        $display("🏥 SINGLE TEST MEDICAL AI SYSTEM");
        $display("================================");
        $display("System: MobileNetV3 Chest X-ray Classifier");
        $display("Input: 224x224 grayscale X-ray image");
        $display("Output: 15-class medical condition classification");
        $display("");

        // Initialize
        rst = 1;
        en = 0;
        pixel_in = 0;
        current_pixel = 0;
        cycle_count = 0;
        pixel_count = 0;

        // Reset sequence
        #100;
        rst = 0;
        #50;

        $display("🚀 Starting image processing...");
        $display("Sending %0d pixels to neural network...", IMG_SIZE*IMG_SIZE);

        // Send image data
        en = 1;
        for (int i = 0; i < IMG_SIZE*IMG_SIZE; i++) begin
            pixel_in = test_image[i];
            current_pixel = i;
            pixel_count++;
            
            // Debug output for first few pixels
            if (i < 10) begin
                $display("Pixel %0d: 0x%04x", i, pixel_in);
            end
            
            @(posedge clk);
            cycle_count++;
        end

        // Wait for processing to complete
        $display("All pixels sent. Waiting for neural network to complete...");
        en = 0;
        
        // Wait for valid output with timeout
        fork
            begin
                wait(valid_out);
                $display("✅ Neural network processing complete!");
            end
            begin
                #1000000; // 1ms timeout
                $display("⚠️ Timeout waiting for neural network completion");
            end
        join_any
        disable fork;

        // Process results if valid
        if (valid_out) begin
            // Extract individual class scores
            logic signed [DATA_WIDTH-1:0] scores [0:FINAL_NUM_CLASSES-1];
            real probabilities [0:FINAL_NUM_CLASSES-1];
            integer max_class = 0;
            real max_prob = 0.0;
            
            for (int i = 0; i < FINAL_NUM_CLASSES; i++) begin
                scores[i] = class_scores[i*DATA_WIDTH +: DATA_WIDTH];
                probabilities[i] = fixed_to_probability(scores[i]);
                if (probabilities[i] > max_prob) begin
                    max_prob = probabilities[i];
                    max_class = i;
                end
            end

            // Display results
            $display("");
            $display("🎯 MEDICAL AI CLASSIFICATION RESULTS");
            $display("====================================");
            $display("");
            
            // Show all class scores
            $display("📊 DETAILED CLASSIFICATION SCORES:");
            for (int i = 0; i < FINAL_NUM_CLASSES; i++) begin
                $display("%-20s |   %.4f   |   %0d", 
                        medical_conditions[i], probabilities[i], scores[i]);
            end
            
            $display("");
            $display("🏆 PRIMARY DIAGNOSIS: %s (%.2f%%)", 
                    medical_conditions[max_class], max_prob * 100.0);
            $display("💡 RECOMMENDATION: %s", medical_recommendations[max_class]);
            
            // Performance metrics
            $display("");
            $display("⚡ PERFORMANCE METRICS:");
            $display("Processing time: %0d cycles", cycle_count);
            $display("Pixels processed: %0d", pixel_count);
            $display("Clock frequency: 100 MHz");
            $display("Real-time latency: %.3f ms", cycle_count / 100000.0);
            $display("Throughput: %.2f images/second", 100000000.0 / cycle_count);
            
            // Test validation
            $display("");
            $display("✅ TEST COMPLETED SUCCESSFULLY");
            
        end else begin
            $display("❌ TEST FAILED - No valid output received");
        end

        $display("");
        $display("🏥 Medical AI Single Test Complete");
        $finish;
    end

    // Cycle counter
    always @(posedge clk) begin
        if (!rst && en) begin
            cycle_count <= cycle_count + 1;
        end
    end

    // Monitor for debugging
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Valid output detected at cycle %0d", cycle_count);
        end
    end

endmodule
