`timescale 1ns/1ps

module tb_full_system_top_with_diseases;
    // Parameters (match your DUT)
    parameter DATA_WIDTH = 16;
    parameter FRAC = 8;
    parameter IN_CHANNELS = 1;
    parameter FIRST_OUT_CHANNELS = 16;
    parameter BNECK_OUT_CHANNELS = 16;
    parameter FINAL_NUM_CLASSES = 15;
    parameter IMG_SIZE = 224;
    parameter NUM_TESTS = 5;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk; // 100MHz

    // DUT signals
    reg en = 0;
    reg [DATA_WIDTH-1:0] pixel_in;
    wire signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] class_scores;
    wire valid_out;

    // Disease names array
    string disease_names [0:FINAL_NUM_CLASSES-1];
    
    // Test data storage
    reg [DATA_WIDTH-1:0] test_images [0:NUM_TESTS-1][0:IMG_SIZE*IMG_SIZE-1];
    string test_names [0:NUM_TESTS-1];
    integer test_results [0:NUM_TESTS-1];
    integer test_cycles [0:NUM_TESTS-1];
    integer pixel_count [0:NUM_TESTS-1];

    // Test control
    integer current_test = 0;
    integer current_pixel = 0;
    integer total_passed = 0;
    integer total_failed = 0;
    integer total_cycles = 0;
    integer total_pixels = 0;

    // Output files
    integer logfile, outfile, disease_logfile;
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

    // Initialize disease names
    task initialize_disease_names;
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
    endtask

    // Test case generation
    task generate_test_cases;
        // Test 0: Real image data (224x224)
        $readmemh("test_image.mem", test_images[0]);
        test_names[0] = "Real Image Data (224x224)";
        
        // Test 1: All zeros
        for (i = 0; i < IMG_SIZE*IMG_SIZE; i = i + 1) begin
            test_images[1][i] = 0;
        end
        test_names[1] = "All Zeros Image";
        
        // Test 2: All ones (normalized)
        for (i = 0; i < IMG_SIZE*IMG_SIZE; i = i + 1) begin
            test_images[2][i] = 16'h0100; // 1.0 in fixed-point
        end
        test_names[2] = "All Ones Image";
        
        // Test 3: Checkerboard pattern
        for (i = 0; i < IMG_SIZE*IMG_SIZE; i = i + 1) begin
            automatic integer row = i / IMG_SIZE;
            automatic integer col = i % IMG_SIZE;
            test_images[3][i] = ((row + col) % 2 == 0) ? 16'h0100 : 16'h0000;
        end
        test_names[3] = "Checkerboard Pattern";
        
        // Test 4: Gradient pattern
        for (i = 0; i < IMG_SIZE*IMG_SIZE; i = i + 1) begin
            automatic integer row = i / IMG_SIZE;
            automatic integer col = i % IMG_SIZE;
            test_images[4][i] = ((row + col) * 16'h0010) & 16'hFF00;
        end
        test_names[4] = "Gradient Pattern";
    endtask

    // Function to find the highest scoring disease
    function automatic [3:0] find_max_score;
        input signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] scores;
        reg [3:0] max_index;
        reg signed [DATA_WIDTH-1:0] max_score;
        integer k;
        begin
            max_index = 0;
            max_score = scores[DATA_WIDTH-1:0];
            for (k = 1; k < FINAL_NUM_CLASSES; k = k + 1) begin
                if (scores[k*DATA_WIDTH +: DATA_WIDTH] > max_score) begin
                    max_score = scores[k*DATA_WIDTH +: DATA_WIDTH];
                    max_index = k;
                end
            end
            find_max_score = max_index;
        end
    endfunction

    // Run a single test case with disease analysis
    task run_test_case(input integer test_num);
        integer start_time, end_time;
        reg signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] output_scores;
        integer output_valid_count;
        integer pixels_sent;
        reg [3:0] predicted_disease_index;
        string predicted_disease_name;
        
        $display("=== Running Test %0d: %s ===", test_num, test_names[test_num]);
        $fdisplay(logfile, "=== Test %0d: %s ===", test_num, test_names[test_num]);
        $fdisplay(disease_logfile, "=== Test %0d: %s ===", test_num, test_names[test_num]);
        
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
            pixel_in = test_images[test_num][current_pixel];
            pixels_sent = pixels_sent + 1;
            #10;
        end
        
        // Wait for output with timeout
        for (j = 0; j < 50000; j = j + 1) begin
            if (valid_out) begin
                output_scores = class_scores;
                output_valid_count = output_valid_count + 1;
                break;
            end
            #10;
        end
        
        end_time = $time;
        test_cycles[test_num] = (end_time - start_time) / 10;
        pixel_count[test_num] = pixels_sent;
        
        // Analyze results with disease names
        if (output_valid_count > 0) begin
            predicted_disease_index = find_max_score(output_scores);
            predicted_disease_name = disease_names[predicted_disease_index];
            
            $display("DIAGNOSIS RESULT:");
            $display("  Predicted Disease: %s (Index: %0d)", predicted_disease_name, predicted_disease_index);
            $display("  Confidence Score: %0d", output_scores[predicted_disease_index*DATA_WIDTH +: DATA_WIDTH]);
            
            $fdisplay(disease_logfile, "DIAGNOSIS RESULT:");
            $fdisplay(disease_logfile, "  Predicted Disease: %s (Index: %0d)", predicted_disease_name, predicted_disease_index);
            $fdisplay(disease_logfile, "  Confidence Score: %0d", output_scores[predicted_disease_index*DATA_WIDTH +: DATA_WIDTH]);
            
            // Log all disease scores
            $fdisplay(disease_logfile, "ALL DISEASE SCORES:");
            for (i = 0; i < FINAL_NUM_CLASSES; i = i + 1) begin
                $fdisplay(disease_logfile, "  %s: %0d", disease_names[i], output_scores[i*DATA_WIDTH +: DATA_WIDTH]);
            end
        end
        
        // Log results
        $fdisplay(logfile, "Test %0d completed in %0d cycles", test_num, test_cycles[test_num]);
        $fdisplay(logfile, "Pixels sent: %0d", pixels_sent);
        $fdisplay(logfile, "Output valid count: %0d", output_valid_count);
        
        // Write output to file
        $fdisplay(outfile, "=== Test %0d: %s ===", test_num, test_names[test_num]);
        for (i = 0; i < FINAL_NUM_CLASSES; i = i + 1) begin
            $fdisplay(outfile, "%04x", output_scores[i*DATA_WIDTH +: DATA_WIDTH]);
        end
        
        // Basic validation
        if (output_valid_count == 0) begin
            $display("ERROR: Test %0d failed - no valid output", test_num);
            $fdisplay(logfile, "ERROR: Test %0d failed - no valid output", test_num);
            test_results[test_num] = 1;
        end else begin
            $display("Test %0d passed - Predicted: %s", test_num, predicted_disease_name);
            $fdisplay(logfile, "Test %0d passed - Predicted: %s", test_num, predicted_disease_name);
            test_results[test_num] = 0;
        end
    endtask

    // Main testbench procedure
    initial begin
        // Open log files
        logfile = $fopen("full_system_testbench.log", "w");
        outfile = $fopen("full_system_outputs.txt", "w");
        disease_logfile = $fopen("disease_diagnosis_results.txt", "w");
        
        if (logfile == 0 || outfile == 0 || disease_logfile == 0) begin
            $display("ERROR: Could not open log files");
            $finish;
        end
        
        $fdisplay(logfile, "=== Full System Testbench Started ===");
        $fdisplay(logfile, "Parameters: DATA_WIDTH=%0d, IMG_SIZE=%0d, FINAL_NUM_CLASSES=%0d", 
                 DATA_WIDTH, IMG_SIZE, FINAL_NUM_CLASSES);
        $fdisplay(logfile, "System: First Layer -> BNeck Blocks -> Final Layer");
        
        $fdisplay(disease_logfile, "=== MEDICAL DIAGNOSIS SYSTEM ===");
        $fdisplay(disease_logfile, "Disease Classes: %0d", FINAL_NUM_CLASSES);
        $fdisplay(disease_logfile, "Bit Width: %0d", DATA_WIDTH);
        
        // Initialize disease names
        initialize_disease_names();
        
        // Generate test cases
        generate_test_cases();
        
        // Run all test cases
        for (current_test = 0; current_test < NUM_TESTS; current_test = current_test + 1) begin
            run_test_case(current_test);
            total_cycles = total_cycles + test_cycles[current_test];
            total_pixels = total_pixels + pixel_count[current_test];
            
            if (test_results[current_test] == 0) begin
                total_passed = total_passed + 1;
            end else begin
                total_failed = total_failed + 1;
            end
        end
        
        // Final summary
        $display("\n=== FULL SYSTEM TESTBENCH SUMMARY ===");
        $display("Total tests: %0d", NUM_TESTS);
        $display("Passed: %0d", total_passed);
        $display("Failed: %0d", total_failed);
        $display("Total cycles: %0d", total_cycles);
        $display("Total pixels processed: %0d", total_pixels);
        
        $fclose(logfile);
        $fclose(outfile);
        $fclose(disease_logfile);
        
        $display("Full system testbench completed. Check disease_diagnosis_results.txt for medical analysis.");
        $finish;
    end

    // Monitor for simulation timeout
    initial begin
        #5000000;
        $display("ERROR: Full system simulation timeout");
        $finish;
    end

endmodule 