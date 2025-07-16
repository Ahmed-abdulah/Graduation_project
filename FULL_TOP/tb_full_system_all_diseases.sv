`timescale 1ns/1ps

module tb_full_system_all_diseases;
    // Parameters (match your DUT)
    parameter DATA_WIDTH = 16;
    parameter FRAC = 8;
    parameter IN_CHANNELS = 1;
    parameter FIRST_OUT_CHANNELS = 16;
    parameter BNECK_OUT_CHANNELS = 16;
    parameter FINAL_NUM_CLASSES = 15;
    parameter IMG_SIZE = 224;
    parameter NUM_DISEASES = 15;  // All 15 disease test cases

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk; // 100MHz

    // DUT signals
    reg en = 0;
    reg [DATA_WIDTH-1:0] pixel_in;
    wire signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] class_scores;
    wire valid_out;

    // Disease information arrays
    string disease_names [0:FINAL_NUM_CLASSES-1];
    string disease_files [0:NUM_DISEASES-1];
    integer expected_classes [0:NUM_DISEASES-1];
    
    // Test data storage
    reg [DATA_WIDTH-1:0] disease_images [0:NUM_DISEASES-1][0:IMG_SIZE*IMG_SIZE-1];
    integer test_results [0:NUM_DISEASES-1];
    integer test_cycles [0:NUM_DISEASES-1];
    integer predicted_classes [0:NUM_DISEASES-1];
    integer confidence_scores [0:NUM_DISEASES-1];
    integer correct_predictions = 0;
    integer total_tests = 0;

    // Test control
    integer current_test = 0;
    integer current_pixel = 0;
    integer total_cycles = 0;

    // Output files
    integer logfile, outfile, disease_logfile, summary_file;
    integer i, j;

    // Instantiate DUT
    full_system_top #(
        .DATA_WIDTH(DATA_WIDTH), .FRAC(FRAC), .IN_CHANNELS(IN_CHANNELS),
        .FIRST_OUT_CHANNELS(FIRST_OUT_CHANNELS), .BNECK_OUT_CHANNELS(BNECK_OUT_CHANNELS),
        .FINAL_NUM_CLASSES(FINAL_NUM_CLASSES), .IMG_SIZE(IMG_SIZE)
    ) dut (
        .clk(clk), .rst(rst), .en(en),
        .pixel_in(pixel_in),
        .class_scores(class_scores), .valid_out(valid_out)
    );

    // Initialize disease names and expected classifications
    task initialize_disease_data;
        // Disease class names
        disease_names[0]  = "No Finding";
        disease_names[1]  = "Infiltration";
        disease_names[2]  = "Atelectasis";
        disease_names[3]  = "Effusion";
        disease_names[4]  = "Nodule";
        disease_names[5]  = "Pneumothorax";
        disease_names[6]  = "Mass";
        disease_names[7]  = "Consolidation";
        disease_names[8]  = "Pleural Thickening";
        disease_names[9]  = "Cardiomegaly";
        disease_names[10] = "Emphysema";
        disease_names[11] = "Fibrosis";
        disease_names[12] = "Edema";
        disease_names[13] = "Pneumonia";
        disease_names[14] = "Hernia";
        
        // Disease memory files and expected classes
        disease_files[0]  = "real_normal_xray.mem";        expected_classes[0]  = 0;  // No Finding
        disease_files[1]  = "real_infiltration_xray.mem";  expected_classes[1]  = 1;  // Infiltration
        disease_files[2]  = "real_atelectasis_xray.mem";   expected_classes[2]  = 2;  // Atelectasis
        disease_files[3]  = "real_effusion_xray.mem";      expected_classes[3]  = 3;  // Effusion
        disease_files[4]  = "real_nodule_xray.mem";        expected_classes[4]  = 4;  // Nodule
        disease_files[5]  = "real_pneumothorax_xray.mem";  expected_classes[5]  = 5;  // Pneumothorax
        disease_files[6]  = "real_mass_xray.mem";          expected_classes[6]  = 6;  // Mass
        disease_files[7]  = "real_consolidation_xray.mem"; expected_classes[7]  = 7;  // Consolidation
        disease_files[8]  = "real_pleural_thickening_xray.mem"; expected_classes[8] = 8; // Pleural Thickening
        disease_files[9]  = "real_cardiomegaly_xray.mem";  expected_classes[9]  = 9;  // Cardiomegaly
        disease_files[10] = "real_emphysema_xray.mem";     expected_classes[10] = 10; // Emphysema
        disease_files[11] = "real_fibrosis_xray.mem";      expected_classes[11] = 11; // Fibrosis
        disease_files[12] = "real_edema_xray.mem";         expected_classes[12] = 12; // Edema
        disease_files[13] = "real_pneumonia_xray.mem";     expected_classes[13] = 13; // Pneumonia
        disease_files[14] = "real_hernia_xray.mem";        expected_classes[14] = 14; // Hernia
    endtask

    // Load all disease images
    task load_disease_images;
        integer file_handle;
        integer load_success;
        
        $display("Loading all disease images...");
        $fdisplay(logfile, "Loading all disease images...");
        
        for (i = 0; i < NUM_DISEASES; i = i + 1) begin
            $display("Loading %s for %s (Expected Class: %0d)", 
                    disease_files[i], disease_names[expected_classes[i]], expected_classes[i]);
            
            // Try to load the file
            file_handle = $fopen(disease_files[i], "r");
            if (file_handle != 0) begin
                $fclose(file_handle);
                $readmemh(disease_files[i], disease_images[i]);
                $display("✅ Successfully loaded %s", disease_files[i]);
                $fdisplay(logfile, "✅ Successfully loaded %s", disease_files[i]);
            end else begin
                $display("❌ Failed to load %s - using zeros", disease_files[i]);
                $fdisplay(logfile, "❌ Failed to load %s - using zeros", disease_files[i]);
                // Fill with zeros if file not found
                for (j = 0; j < IMG_SIZE*IMG_SIZE; j = j + 1) begin
                    disease_images[i][j] = 0;
                end
            end
        end
        
        $display("All disease images loaded.");
        $fdisplay(logfile, "All disease images loaded.");
    endtask

    // Function to find the highest scoring disease
    function automatic [3:0] find_max_score;
        input [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] scores;
        reg [3:0] max_index;
        reg [DATA_WIDTH-1:0] max_score;
        reg [DATA_WIDTH-1:0] current_score;
        integer k;
        begin
            max_index = 0;
            max_score = scores[DATA_WIDTH-1:0];

            // Debug: Show all scores
            $display("FIND_MAX_SCORE DEBUG:");
            for (k = 0; k < FINAL_NUM_CLASSES; k = k + 1) begin
                current_score = scores[k*DATA_WIDTH +: DATA_WIDTH];
                $display("  Class %0d: %0d", k, current_score);
            end

            // Find maximum score (unsigned comparison)
            for (k = 1; k < FINAL_NUM_CLASSES; k = k + 1) begin
                current_score = scores[k*DATA_WIDTH +: DATA_WIDTH];
                if (current_score > max_score) begin
                    max_score = current_score;
                    max_index = k;
                end
            end

            $display("  MAXIMUM: Class %0d with score %0d", max_index, max_score);
            find_max_score = max_index;
        end
    endfunction

    // Run a single disease test case
    task run_disease_test(input integer test_num);
        integer start_time, end_time;
        reg signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] output_scores;
        integer output_valid_count;
        integer pixels_sent;
        reg [3:0] predicted_disease_index;
        string predicted_disease_name;
        string expected_disease_name;
        integer is_correct;
        
        expected_disease_name = disease_names[expected_classes[test_num]];
        
        $display("\n=== Testing Disease %0d/%0d: %s ===", 
                test_num+1, NUM_DISEASES, expected_disease_name);
        $display("File: %s", disease_files[test_num]);
        $display("Expected Class: %0d (%s)", expected_classes[test_num], expected_disease_name);
        
        $fdisplay(logfile, "\n=== Testing Disease %0d/%0d: %s ===", 
                 test_num+1, NUM_DISEASES, expected_disease_name);
        $fdisplay(logfile, "File: %s", disease_files[test_num]);
        $fdisplay(logfile, "Expected Class: %0d (%s)", expected_classes[test_num], expected_disease_name);
        
        $fdisplay(disease_logfile, "\n=== DISEASE TEST %0d: %s ===", 
                 test_num+1, expected_disease_name);
        
        // Reset for new test
        rst = 1; en = 0; pixel_in = 0;
        #20;
        rst = 0; en = 1;
        #10;
        
        start_time = $time;
        output_valid_count = 0;
        pixels_sent = 0;
        
        // Feed image pixels one by one
        for (current_pixel = 0; current_pixel < IMG_SIZE*IMG_SIZE; current_pixel = current_pixel + 1) begin
            pixel_in = disease_images[test_num][current_pixel];
            pixels_sent = pixels_sent + 1;
            #10;
        end
        
        // Wait for output with timeout
        for (j = 0; j < 100000; j = j + 1) begin
            if (valid_out) begin
                output_scores = class_scores;
                output_valid_count = output_valid_count + 1;
                break;
            end
            #10;
        end
        
        end_time = $time;
        test_cycles[test_num] = (end_time - start_time) / 10;
        total_cycles = total_cycles + test_cycles[test_num];
        
        // Analyze results
        if (output_valid_count > 0) begin
            predicted_disease_index = find_max_score(output_scores);
            predicted_disease_name = disease_names[predicted_disease_index];
            predicted_classes[test_num] = predicted_disease_index;
            confidence_scores[test_num] = output_scores[predicted_disease_index*DATA_WIDTH +: DATA_WIDTH];
            
            is_correct = (predicted_disease_index == expected_classes[test_num]);
            if (is_correct) correct_predictions = correct_predictions + 1;
            
            $display("RESULT: %s", is_correct ? "✅ CORRECT" : "❌ INCORRECT");
            $display("  Expected: %s (Class %0d)", expected_disease_name, expected_classes[test_num]);
            $display("  Predicted: %s (Class %0d)", predicted_disease_name, predicted_disease_index);
            $display("  Confidence: %0d", confidence_scores[test_num]);
            $display("  Cycles: %0d", test_cycles[test_num]);
            
            $fdisplay(disease_logfile, "EXPECTED: %s (Class %0d)", expected_disease_name, expected_classes[test_num]);
            $fdisplay(disease_logfile, "PREDICTED: %s (Class %0d)", predicted_disease_name, predicted_disease_index);
            $fdisplay(disease_logfile, "CONFIDENCE: %0d", confidence_scores[test_num]);
            $fdisplay(disease_logfile, "RESULT: %s", is_correct ? "CORRECT" : "INCORRECT");
            $fdisplay(disease_logfile, "CYCLES: %0d", test_cycles[test_num]);
            
            // Log all disease scores for detailed analysis
            $fdisplay(disease_logfile, "ALL SCORES:");
            for (i = 0; i < FINAL_NUM_CLASSES; i = i + 1) begin
                $fdisplay(disease_logfile, "  %s: %0d", disease_names[i], 
                         output_scores[i*DATA_WIDTH +: DATA_WIDTH]);
            end
            
            test_results[test_num] = is_correct ? 0 : 1;
        end else begin
            $display("❌ ERROR: No valid output received");
            $fdisplay(logfile, "❌ ERROR: No valid output received");
            $fdisplay(disease_logfile, "ERROR: No valid output received");
            test_results[test_num] = 1;
            predicted_classes[test_num] = -1;
            confidence_scores[test_num] = 0;
        end
        
        total_tests = total_tests + 1;
    endtask

    // Generate comprehensive summary report
    task generate_summary_report;
        real accuracy_percentage;
        integer top1_correct, top3_correct;

        accuracy_percentage = (real'(correct_predictions) / real'(total_tests)) * 100.0;

        $display("\n============================================================");
        $display("COMPREHENSIVE DISEASE CLASSIFICATION SUMMARY");
        $display("============================================================");
        $display("Total Diseases Tested: %0d", total_tests);
        $display("Correct Predictions: %0d", correct_predictions);
        $display("Incorrect Predictions: %0d", total_tests - correct_predictions);
        $display("Overall Accuracy: %.2f%%", accuracy_percentage);
        $display("Total Simulation Cycles: %0d", total_cycles);
        $display("Average Cycles per Disease: %0d", total_cycles / total_tests);

        // Write detailed summary to file
        $fdisplay(summary_file, "COMPREHENSIVE DISEASE CLASSIFICATION SUMMARY");
        $fdisplay(summary_file, "============================================================");
        $fdisplay(summary_file, "Test Date: %0t", $time);
        $fdisplay(summary_file, "Neural Network: MobileNetV3 Medical Classifier");
        $fdisplay(summary_file, "Image Size: %0dx%0d pixels", IMG_SIZE, IMG_SIZE);
        $fdisplay(summary_file, "Data Width: %0d bits", DATA_WIDTH);
        $fdisplay(summary_file, "Number of Classes: %0d", FINAL_NUM_CLASSES);
        $fdisplay(summary_file, "");
        $fdisplay(summary_file, "OVERALL RESULTS:");
        $fdisplay(summary_file, "Total Diseases Tested: %0d", total_tests);
        $fdisplay(summary_file, "Correct Predictions: %0d", correct_predictions);
        $fdisplay(summary_file, "Incorrect Predictions: %0d", total_tests - correct_predictions);
        $fdisplay(summary_file, "Overall Accuracy: %.2f%%", accuracy_percentage);
        $fdisplay(summary_file, "Total Simulation Cycles: %0d", total_cycles);
        $fdisplay(summary_file, "Average Cycles per Disease: %0d", total_cycles / total_tests);
        $fdisplay(summary_file, "");

        // Detailed per-disease results
        $fdisplay(summary_file, "DETAILED RESULTS BY DISEASE:");
        $fdisplay(summary_file, "%-20s | %-15s | %-15s | %-10s | %-8s",
                 "Expected", "Predicted", "Result", "Confidence", "Cycles");
        $fdisplay(summary_file, "--------------------------------------------------------------------------------");

        for (i = 0; i < NUM_DISEASES; i = i + 1) begin
            automatic string result_str = (test_results[i] == 0) ? "CORRECT" : "INCORRECT";
            automatic string predicted_name = (predicted_classes[i] >= 0) ?
                                   disease_names[predicted_classes[i]] : "NONE";

            $fdisplay(summary_file, "%-20s | %-15s | %-15s | %-10d | %-8d",
                     disease_names[expected_classes[i]], predicted_name,
                     result_str, confidence_scores[i], test_cycles[i]);
        end

        // Performance analysis
        $fdisplay(summary_file, "");
        $fdisplay(summary_file, "PERFORMANCE ANALYSIS:");
        $fdisplay(summary_file, "Fastest Test: %0d cycles", test_cycles[0]);
        $fdisplay(summary_file, "Slowest Test: %0d cycles", test_cycles[0]);

        // Find min/max cycles
        for (i = 1; i < NUM_DISEASES; i = i + 1) begin
            if (test_cycles[i] < test_cycles[0]) begin
                $fdisplay(summary_file, "Fastest Test: %0d cycles", test_cycles[i]);
            end
            if (test_cycles[i] > test_cycles[0]) begin
                $fdisplay(summary_file, "Slowest Test: %0d cycles", test_cycles[i]);
            end
        end

        // Recommendations
        $fdisplay(summary_file, "");
        $fdisplay(summary_file, "RECOMMENDATIONS:");
        if (accuracy_percentage >= 80.0) begin
            $fdisplay(summary_file, "✅ Good performance - Model is working well");
        end else if (accuracy_percentage >= 60.0) begin
            $fdisplay(summary_file, "⚠️  Moderate performance - Consider model tuning");
        end else begin
            $fdisplay(summary_file, "❌ Poor performance - Model needs retraining");
        end

        if (total_cycles > 1000000) begin
            $fdisplay(summary_file, "⚠️  High cycle count - Consider optimization");
        end else begin
            $fdisplay(summary_file, "✅ Reasonable performance timing");
        end
    endtask

    // Main testbench procedure
    initial begin
        // Open log files
        logfile = $fopen("all_diseases_testbench.log", "w");
        outfile = $fopen("all_diseases_outputs.txt", "w");
        disease_logfile = $fopen("all_diseases_diagnosis.txt", "w");
        summary_file = $fopen("disease_classification_summary.txt", "w");

        if (logfile == 0 || outfile == 0 || disease_logfile == 0 || summary_file == 0) begin
            $display("ERROR: Could not open log files");
            $finish;
        end

        $display("=== COMPREHENSIVE DISEASE CLASSIFICATION TEST ===");
        $display("Testing all %0d diseases with real X-ray images", NUM_DISEASES);

        $fdisplay(logfile, "=== COMPREHENSIVE DISEASE CLASSIFICATION TEST ===");
        $fdisplay(logfile, "Start Time: %0t", $time);
        $fdisplay(logfile, "Parameters: DATA_WIDTH=%0d, IMG_SIZE=%0d, FINAL_NUM_CLASSES=%0d",
                 DATA_WIDTH, IMG_SIZE, FINAL_NUM_CLASSES);

        $fdisplay(disease_logfile, "=== MEDICAL AI DIAGNOSIS SYSTEM TEST ===");
        $fdisplay(disease_logfile, "MobileNetV3 Neural Network for Medical X-ray Classification");
        $fdisplay(disease_logfile, "Testing %0d disease categories", NUM_DISEASES);

        // Initialize disease data
        initialize_disease_data();

        // Load all disease images
        load_disease_images();

        // Run all disease tests
        $display("\nStarting disease classification tests...");
        for (current_test = 0; current_test < NUM_DISEASES; current_test = current_test + 1) begin
            run_disease_test(current_test);
        end

        // Generate comprehensive summary
        generate_summary_report();

        // Close files
        $fclose(logfile);
        $fclose(outfile);
        $fclose(disease_logfile);
        $fclose(summary_file);

        $display("\n🎯 TESTING COMPLETE!");
        $display("📊 Check these files for results:");
        $display("   - disease_classification_summary.txt (Main Results)");
        $display("   - all_diseases_diagnosis.txt (Detailed Analysis)");
        $display("   - all_diseases_testbench.log (Technical Log)");

        $finish;
    end

    // Monitor for simulation timeout
    initial begin
        #50000000;  // Increased timeout for 15 tests
        $display("ERROR: Simulation timeout after testing %0d diseases", total_tests);
        if (total_tests > 0) begin
            generate_summary_report();
        end
        $finish;
    end

endmodule
