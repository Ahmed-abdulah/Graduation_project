`timescale 1ns/1ps

module tb_final_layer_top;
    // Parameters (match your DUT)
    parameter WIDTH = 16;
    parameter FRAC = 8;
    parameter IN_CHANNELS = 16;
    parameter MID_CHANNELS = 32;
    parameter LINEAR_FEATURES_IN = 32;
    parameter LINEAR_FEATURES_MID = 64;
    parameter NUM_CLASSES = 15;
    parameter FEATURE_SIZE = 7;
    parameter NUM_TESTS = 8; // Number of testcases to run

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk; // 100MHz

    // DUT signals
    reg en = 0;
    reg signed [WIDTH-1:0] data_in;
    reg [$clog2(IN_CHANNELS)-1:0] channel_in;
    reg valid_in;
    wire signed [NUM_CLASSES*WIDTH-1:0] data_out;
    wire valid_out;

    // Test data storage
    reg signed [WIDTH-1:0] test_inputs [0:NUM_TESTS-1][0:IN_CHANNELS-1];
    reg signed [WIDTH-1:0] expected_outputs [0:NUM_TESTS-1][0:NUM_CLASSES-1];
    reg [7:0] test_names [0:NUM_TESTS-1][0:31]; // Test case names
    integer test_results [0:NUM_TESTS-1]; // 0=pass, 1=fail
    integer test_cycles [0:NUM_TESTS-1]; // Cycle count per test

    // Test control
    integer current_test = 0;
    integer cycle_count = 0;
    integer total_passed = 0;
    integer total_failed = 0;
    integer total_cycles = 0;

    // Output files
    integer logfile, outfile;
    integer i, j;

    // Instantiate DUT
    final_layer_top #(
        .WIDTH(WIDTH), .FRAC(FRAC), .IN_CHANNELS(IN_CHANNELS), .MID_CHANNELS(MID_CHANNELS),
        .LINEAR_FEATURES_IN(LINEAR_FEATURES_IN), .LINEAR_FEATURES_MID(LINEAR_FEATURES_MID),
        .NUM_CLASSES(NUM_CLASSES), .FEATURE_SIZE(FEATURE_SIZE)
    ) dut (
        .clk(clk), .rst(rst), .en(en),
        .data_in(data_in), .channel_in(channel_in), .valid_in(valid_in),
        .data_out(data_out), .valid_out(valid_out)
    );

    // Test case generation
    task generate_test_cases;
        // Test 0: Real image data
        $readmemh("../test_image.mem", test_inputs[0]);
        $sformat(test_names[0], "Real Image Data");
        
        // Test 1: All zeros
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[1][i] = 0;
        end
        $sformat(test_names[1], "All Zeros");
        
        // Test 2: All ones
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[2][i] = 16'h0100; // 1.0 in fixed-point
        end
        $sformat(test_names[2], "All Ones");
        
        // Test 3: Maximum values
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[3][i] = 16'h7FFF; // Max positive
        end
        $sformat(test_names[3], "Max Values");
        
        // Test 4: Minimum values
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[4][i] = 16'h8000; // Max negative
        end
        $sformat(test_names[4], "Min Values");
        
        // Test 5: Random pattern
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[5][i] = $random % 16'h1000; // Random values
        end
        $sformat(test_names[5], "Random Pattern");
        
        // Test 6: Checkerboard pattern
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[6][i] = (i % 2 == 0) ? 16'h0100 : 16'hFF00; // Alternating
        end
        $sformat(test_names[6], "Checkerboard");
        
        // Test 7: Single pixel on
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            test_inputs[7][i] = (i == 0) ? 16'h0100 : 0; // Only first pixel
        end
        $sformat(test_names[7], "Single Pixel");
    endtask

    // Run a single test case
    task run_test_case(input integer test_num);
        integer start_time, end_time;
        reg signed [NUM_CLASSES*WIDTH-1:0] output_data;
        integer output_valid_count;
        
        $display("=== Running Test %0d: %s ===", test_num, test_names[test_num]);
        $fdisplay(logfile, "=== Test %0d: %s ===", test_num, test_names[test_num]);
        
        // Reset for new test
        rst = 1; en = 0; valid_in = 0; data_in = 0; channel_in = 0;
        #20;
        rst = 0; en = 1;
        #10;
        
        start_time = $time;
        output_valid_count = 0;
        
        // Feed input data
        for (i = 0; i < IN_CHANNELS; i = i + 1) begin
            data_in = test_inputs[test_num][i];
            channel_in = i[$clog2(IN_CHANNELS)-1:0];
            valid_in = 1;
            #10;
            valid_in = 0;
            #10;
        end
        
        // Wait for output with timeout
        for (j = 0; j < 1000; j = j + 1) begin // 10us timeout
            if (valid_out) begin
                output_data = data_out;
                output_valid_count = output_valid_count + 1;
                break;
            end
            #10;
        end
        
        end_time = $time;
        test_cycles[test_num] = (end_time - start_time) / 10; // Convert to cycles
        
        // Log results
        $fdisplay(logfile, "Test %0d completed in %0d cycles", test_num, test_cycles[test_num]);
        $fdisplay(logfile, "Output valid count: %0d", output_valid_count);
        
        // Write output to file
        $fdisplay(outfile, "=== Test %0d: %s ===", test_num, test_names[test_num]);
        for (i = 0; i < NUM_CLASSES; i = i + 1) begin
            $fdisplay(outfile, "%04x", output_data[i*WIDTH +: WIDTH]);
        end
        
        // Basic validation (check for reasonable output)
        if (output_valid_count == 0) begin
            $display("ERROR: Test %0d failed - no valid output", test_num);
            $fdisplay(logfile, "ERROR: Test %0d failed - no valid output", test_num);
            test_results[test_num] = 1; // Fail
        end else begin
            $display("Test %0d passed", test_num);
            $fdisplay(logfile, "Test %0d passed", test_num);
            test_results[test_num] = 0; // Pass
        end
    endtask

    // Main testbench procedure
    initial begin
        // Open log files
        logfile = $fopen("testbench.log", "w");
        outfile = $fopen("all_test_outputs.txt", "w");
        
        if (logfile == 0 || outfile == 0) begin
            $display("ERROR: Could not open log files");
            $finish;
        end
        
        $fdisplay(logfile, "=== Final Layer Testbench Started ===");
        $fdisplay(logfile, "Parameters: WIDTH=%0d, IN_CHANNELS=%0d, NUM_CLASSES=%0d", WIDTH, IN_CHANNELS, NUM_CLASSES);
        
        // Generate test cases
        generate_test_cases();
        
        // Run all test cases
        for (current_test = 0; current_test < NUM_TESTS; current_test = current_test + 1) begin
            run_test_case(current_test);
            total_cycles = total_cycles + test_cycles[current_test];
            
            if (test_results[current_test] == 0) begin
                total_passed = total_passed + 1;
            end else begin
                total_failed = total_failed + 1;
            end
        end
        
        // Final summary
        $display("\n=== TESTBENCH SUMMARY ===");
        $display("Total tests: %0d", NUM_TESTS);
        $display("Passed: %0d", total_passed);
        $display("Failed: %0d", total_failed);
        $display("Total cycles: %0d", total_cycles);
        $display("Average cycles per test: %0d", total_cycles / NUM_TESTS);
        
        $fdisplay(logfile, "\n=== TESTBENCH SUMMARY ===");
        $fdisplay(logfile, "Total tests: %0d", NUM_TESTS);
        $fdisplay(logfile, "Passed: %0d", total_passed);
        $fdisplay(logfile, "Failed: %0d", total_failed);
        $fdisplay(logfile, "Total cycles: %0d", total_cycles);
        $fdisplay(logfile, "Average cycles per test: %0d", total_cycles / NUM_TESTS);
        
        $fclose(logfile);
        $fclose(outfile);
        
        $display("Testbench completed. Check testbench.log and all_test_outputs.txt for details.");
        $finish;
    end

    // Monitor for simulation timeout
    initial begin
        #1000000; // 1ms timeout
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule 