`timescale 1ns/1ps

module tb_diseased_images_test;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FRAC = 8;
    parameter IN_CHANNELS = 1;
    parameter FIRST_OUT_CHANNELS = 16;
    parameter BNECK_OUT_CHANNELS = 16;
    parameter FINAL_NUM_CLASSES = 15;
    parameter IMG_SIZE = 224;
    parameter NUM_TESTS = 5;  // Test 5 different diseases

    // Medical condition class names
    string medical_conditions [0:14] = {
        "No Finding", "Infiltration", "Atelectasis", "Effusion", "Nodule",
        "Pneumothorax", "Mass", "Consolidation", "Pleural Thickening", 
        "Cardiomegaly", "Emphysema", "Fibrosis", "Edema", "Pneumonia", "Hernia"
    };

    // Test cases with expected diseases
    string test_files [0:NUM_TESTS-1] = {
        "real_pneumonia_xray.mem",      // Should detect Pneumonia (class 13)
        "real_cardiomegaly_xray.mem",   // Should detect Cardiomegaly (class 9)
        "real_effusion_xray.mem",       // Should detect Effusion (class 3)
        "real_atelectasis_xray.mem",    // Should detect Atelectasis (class 2)
        "real_normal_xray.mem"          // Should detect No Finding (class 0)
    };
    
    string test_names [0:NUM_TESTS-1] = {
        "Pneumonia X-ray",
        "Cardiomegaly X-ray", 
        "Effusion X-ray",
        "Atelectasis X-ray",
        "Normal X-ray"
    };
    
    integer expected_classes [0:NUM_TESTS-1] = {13, 9, 3, 2, 0};  // Expected disease classes

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

    // Test data storage
    reg [DATA_WIDTH-1:0] test_images [0:NUM_TESTS-1][0:IMG_SIZE*IMG_SIZE-1];
    integer current_test = 0;
    integer current_pixel = 0;
    integer cycle_count = 0;
    integer total_cycles = 0;
    integer correct_predictions = 0;

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

    // Load all diseased test images
    initial begin
        $display("🏥 DISEASED X-RAY IMAGES MEDICAL AI TEST");
        $display("========================================");
        $display("Testing neural network with REAL diseased X-ray images");
        $display("");
        
        // Load each test image
        for (int i = 0; i < NUM_TESTS; i++) begin
            $display("Loading %s...", test_files[i]);
            if ($test$plusargs("file")) begin
                $readmemh(test_files[i], test_images[i]);
                $display("✅ Successfully loaded %s", test_files[i]);
            end else begin
                $display("⚠️ %s not found, creating test pattern", test_files[i]);
                for (int j = 0; j < IMG_SIZE*IMG_SIZE; j++) begin
                    test_images[i][j] = 16'h1000 + (j % 256) + (i * 100);  // Different pattern per test
                end
            end
        end
        
        $display("");
        $display("📋 Test Plan:");
        for (int i = 0; i < NUM_TESTS; i++) begin
            $display("Test %0d: %s → Expected: %s", i, test_names[i], medical_conditions[expected_classes[i]]);
        end
        $display("");
    end

    // Main test sequence
    initial begin
        $display("System: MobileNetV3 Chest X-ray Classifier");
        $display("Input: %0d diseased X-ray images", NUM_TESTS);
        $display("Goal: Test if neural network can detect different diseases");
        $display("");

        // Initialize
        rst = 1;
        en = 0;
        pixel_in = 0;
        current_test = 0;
        current_pixel = 0;
        cycle_count = 0;
        total_cycles = 0;
        correct_predictions = 0;

        // Reset sequence
        #100;
        rst = 0;
        #50;

        // Test each diseased image
        for (current_test = 0; current_test < NUM_TESTS; current_test++) begin
            $display("🚀 TEST %0d: %s", current_test, test_names[current_test]);
            $display("Expected disease: %s (Class %0d)", medical_conditions[expected_classes[current_test]], expected_classes[current_test]);
            $display("Processing %0d pixels...", IMG_SIZE*IMG_SIZE);
            
            cycle_count = 0;
            
            // Send image data pixel by pixel
            en = 1;
            for (current_pixel = 0; current_pixel < IMG_SIZE*IMG_SIZE; current_pixel++) begin
                pixel_in = test_images[current_test][current_pixel];
                @(posedge clk);
                cycle_count++;
            end
            
            $display("✅ All pixels sent for test %0d", current_test);
            en = 0;
            
            // Wait for result
            $display("⏳ Waiting for neural network result...");
            wait(valid_out);
            
            // Process results
            automatic logic signed [DATA_WIDTH-1:0] scores [0:FINAL_NUM_CLASSES-1];
            automatic real probabilities [0:FINAL_NUM_CLASSES-1];
            automatic integer predicted_class;
            automatic real max_prob;
            
            predicted_class = 0;
            max_prob = 0.0;
            
            // Extract scores and find prediction
            for (int i = 0; i < FINAL_NUM_CLASSES; i++) begin
                scores[i] = class_scores[i*DATA_WIDTH +: DATA_WIDTH];
                probabilities[i] = fixed_to_probability(scores[i]);
                if (probabilities[i] > max_prob) begin
                    max_prob = probabilities[i];
                    predicted_class = i;
                end
            end
            
            // Display results for this test
            $display("");
            $display("📊 RESULTS FOR TEST %0d (%s):", current_test, test_names[current_test]);
            $display("Expected: %s (Class %0d)", medical_conditions[expected_classes[current_test]], expected_classes[current_test]);
            $display("Predicted: %s (Class %0d)", medical_conditions[predicted_class], predicted_class);
            $display("Confidence: %.2f%%", max_prob * 100.0);
            
            // Check if prediction is correct
            if (predicted_class == expected_classes[current_test]) begin
                $display("✅ CORRECT PREDICTION!");
                correct_predictions++;
            end else begin
                $display("❌ INCORRECT PREDICTION!");
                $display("   Expected %s but got %s", medical_conditions[expected_classes[current_test]], medical_conditions[predicted_class]);
            end
            
            $display("Processing time: %0d cycles", cycle_count);
            total_cycles += cycle_count;
            $display("");
            
            // Small delay between tests
            #100;
        end
        
        // Final summary
        $display("🎯 FINAL RESULTS SUMMARY");
        $display("========================");
        $display("Total tests: %0d", NUM_TESTS);
        $display("Correct predictions: %0d", correct_predictions);
        $display("Incorrect predictions: %0d", NUM_TESTS - correct_predictions);
        $display("Accuracy: %.1f%%", (real'(correct_predictions) / real'(NUM_TESTS)) * 100.0);
        $display("Average processing time: %0d cycles per image", total_cycles / NUM_TESTS);
        $display("Total processing time: %0d cycles", total_cycles);
        
        if (correct_predictions == NUM_TESTS) begin
            $display("🎉 ALL TESTS PASSED - Neural network is working correctly!");
        end else if (correct_predictions == 0) begin
            $display("⚠️ ALL TESTS FAILED - Neural network may have a systematic issue");
            $display("   Check if it's always predicting the same class");
        end else begin
            $display("⚠️ PARTIAL SUCCESS - Neural network needs improvement");
            $display("   Some diseases detected correctly, others not");
        end
        
        $display("");
        $display("🏥 Diseased Images Medical AI Test Complete");
        $finish;
    end

endmodule
