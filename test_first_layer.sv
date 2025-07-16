`timescale 1ns/1ps

module test_first_layer;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FRAC = 8;
    parameter IN_CHANNELS = 1;
    parameter OUT_CHANNELS = 16;
    parameter IMG_SIZE = 224;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk; // 100MHz

    // DUT signals
    reg en = 0;
    reg [DATA_WIDTH-1:0] pixel_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire [7:0] channel_out;
    wire [7:0] row_out;
    wire [7:0] col_out;
    wire valid_out;
    wire done;
    wire ready_for_data;

    // Instantiate DUT
    accelerator #(
        .N(DATA_WIDTH),
        .Q(FRAC),
        .n(IMG_SIZE),
        .k(3),
        .s(2),
        .p(1),
        .IN_CHANNELS(IN_CHANNELS),
        .OUT_CHANNELS(OUT_CHANNELS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .pixel(pixel_in),
        .data_out(data_out),
        .channel_out(channel_out),
        .row_out(row_out),
        .col_out(col_out),
        .valid_out(valid_out),
        .done(done),
        .ready_for_data(ready_for_data)
    );

    // Test stimulus
    initial begin
        // Reset
        rst = 1;
        en = 0;
        pixel_in = 0;
        #20;
        rst = 0;
        en = 1;
        #10;

        $display("Starting to send pixels...");
        
        // Send enough pixels for the first layer to produce outputs
        // For 224x224 image with stride 2, we need to send the full image
        for (int i = 0; i < IMG_SIZE*IMG_SIZE; i++) begin
            pixel_in = 16'h0100; // 1.0 in fixed-point
            #10;
        end

        $display("Finished sending %d pixels", IMG_SIZE*IMG_SIZE);
        
        // Wait for outputs with longer timeout
        for (int i = 0; i < 10000; i++) begin
            if (valid_out) begin
                $display("Valid output: data=%h, channel=%d, row=%d, col=%d", data_out, channel_out, row_out, col_out);
            end
            #10;
        end

        $display("Test completed");
        $finish;
    end

    // Monitor
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time %0t: Valid output - data=%h, channel=%d, row=%d, col=%d", $time, data_out, channel_out, row_out, col_out);
        end
        
        // Debug: Monitor ready_for_data signal
        if (ready_for_data) begin
            $display("Time %0t: Ready for data", $time);
        end
        
        // Debug: Monitor done signal
        if (done) begin
            $display("Time %0t: Done signal asserted", $time);
        end
    end

endmodule 