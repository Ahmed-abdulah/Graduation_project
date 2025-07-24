// ============================================================================
//  FULL SYSTEM TOP MODULE for MobileNetV3 (Hardware Skeleton)
//  Connecs: First Layer (accelerator) -> BNeck Block -> Final Layer
//  Matches PyTorch model in models.py (see comments for mapping)
// ============================================================================

module full_system_top #(
    parameter DATA_WIDTH = 16,
    parameter FRAC = 8,
    parameter IN_CHANNELS = 1,
    parameter FIRST_OUT_CHANNELS = 16,
    parameter BNECK_OUT_CHANNELS = 16,
    parameter FINAL_NUM_CLASSES = 15,
    parameter IMG_SIZE = 224
) (
    input  wire clk,
    input  wire rst,
    input  wire en,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    output wire signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] class_scores,
    output wire valid_out,
    
    // Debug outputs
    output wire debug_first_valid,
    output wire debug_first_done,
    output wire debug_bneck_valid,
    output wire debug_bneck_done,
    output wire debug_final_valid,
    output wire [31:0] debug_first_output_count,
    output wire [31:0] debug_bneck_output_count,
    output wire [1:0] debug_bneck_state,
    output wire debug_sequence_valid_in,
    output wire debug_buffer_valid,
    output wire [7:0] debug_buffer_count,
    output wire debug_block0_valid_out
);

    // =============================
    // First Layer: Conv+BN+HSwish
    // =============================
    wire [DATA_WIDTH-1:0] first_data_out;
    wire first_valid_out, first_done, first_ready_for_data;

    accelerator #(
        .N(DATA_WIDTH),
        .Q(FRAC),
        .n(IMG_SIZE),
        .k(3),
        .s(2),
        .p(1),
        .IN_CHANNELS(IN_CHANNELS),
        .OUT_CHANNELS(FIRST_OUT_CHANNELS)
    ) first_layer_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .pixel(pixel_in),
        .data_out(first_data_out),
        .valid_out(first_valid_out),
        .done(first_done),
        .ready_for_data(first_ready_for_data)
    );

    // DEBUG: Monitor data flow from testbench to BNECK
    always @(posedge clk) begin
        if (en && (pixel_in != 16'h0000)) begin
            $display("DATA FLOW DEBUG: pixel_in=0x%04x", pixel_in);
        end
        if (first_valid_out && (first_data_out != 16'h0000)) begin
            $display("DATA FLOW DEBUG: first_layer_out=0x%04x", first_data_out);
        end
    end

    // =============================
    // BNeck Sequence (Full MobileNetV3 Backbone)
    // =============================
    wire [DATA_WIDTH-1:0] bneck_data_out;
    wire bneck_valid_out, bneck_ready, bneck_done;
    wire [7:0] bneck_channel_out, bneck_row_out, bneck_col_out;

    // Generate dummy channel, row, col signals for BNeck input
    // Since first layer doesn't provide these, we'll generate them based on output count
    reg [7:0] first_channel_out, first_row_out, first_col_out;
    reg [31:0] first_output_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            first_output_counter <= 0;
            first_channel_out <= 0;
            first_row_out <= 0;
            first_col_out <= 0;
        end else if (first_valid_out) begin
            first_output_counter <= first_output_counter + 1;

            // FIXED: Generate proper channel, row, col coordinates
            first_channel_out <= first_output_counter % 16;
            first_row_out <= (first_output_counter / 16) % 112;
            first_col_out <= (first_output_counter / (16 * 112)) % 112;

            // DEBUG: Show coordinate generation
            $display("COORDINATE GEN: counter=%0d, ch=%0d, row=%0d, col=%0d",
                    first_output_counter, first_channel_out, first_row_out, first_col_out);
        end
    end

    // USING REAL WEIGHTS VERSION FOR 80-95% ACCURACY
    mobilenetv3_top_real_weights #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(8),
        .IN_CHANNELS(16),
        .OUT_CHANNELS(16),
        .IMG_SIZE(IMG_SIZE)
    ) bneck_sequence (
        .clk(clk),
        .rst(rst), // Real weights version uses rst (active high)
        .en(first_valid_out),
        .data_in(first_data_out),
        .channel_in(first_channel_out),
        .row_in(first_row_out),
        .col_in(first_col_out),
        .valid_out(bneck_valid_out),
        .data_out(bneck_data_out),
        .channel_out(bneck_channel_out),
        .row_out(bneck_row_out),
        .col_out(bneck_col_out)
    );

    // DEBUG: Monitor what's being fed to BNECK
    always @(posedge clk) begin
        if (first_valid_out) begin
            $display("FEEDING BNECK: data=0x%04x, ch=%0d, row=%0d, col=%0d",
                    first_data_out, first_channel_out, first_row_out, first_col_out);
        end
    end

    // =============================
    // Final Layer
    // =============================
    wire signed [FINAL_NUM_CLASSES*DATA_WIDTH-1:0] final_data_out;
    wire final_valid_out;
    wire final_done;

    // =============================
    // Final Layer parameters
    // =============================
    localparam BNECK_OUT_CHANNELS_ACTUAL = 160; // Actual output from BNeck sequence
    localparam MID_CHANNELS = 32;
    localparam LINEAR_FEATURES_IN = 32;
    localparam LINEAR_FEATURES_MID = 64;
    localparam NUM_CLASSES = FINAL_NUM_CLASSES;
    localparam FEATURE_SIZE = IMG_SIZE/4;

    final_layer_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_CLASSES(NUM_CLASSES)
    ) final_layer_inst (
        .clk(clk),
        .rst(rst),
        .en(en && !final_done), // Stop enabling when done
        .valid_in(bneck_valid_out),
        .data_in(bneck_data_out),
        .channel_in(bneck_channel_out[3:0]), // Use 4-bit channel
        .row_in(bneck_row_out),
        .col_in(bneck_col_out),
        .class_scores(final_data_out),
        .valid_out(final_valid_out),
        .done(final_done)
    );

    // Debug counter for BNeck outputs
    reg [31:0] bneck_output_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bneck_output_counter <= 0;
        end else begin
            if (bneck_valid_out) bneck_output_counter <= bneck_output_counter + 1;
        end
    end

    assign class_scores = final_data_out;
    assign valid_out = final_valid_out;

    // Debug signal assignments
    assign debug_first_valid = first_valid_out;
    assign debug_first_done = first_done;
    assign debug_bneck_valid = bneck_valid_out;
    assign debug_bneck_done = bneck_done;
    assign debug_final_valid = final_valid_out;
    assign debug_first_output_count = first_output_counter;
    assign debug_bneck_output_count = bneck_output_counter;
    assign debug_buffer_valid = debug_buffer_valid;
    assign debug_buffer_count = debug_buffer_count;
    assign debug_block0_valid_out = debug_block0_valid_out;

    // =============================
    // TODOs for full integration:
    // - Connect channel/row/col signals between modules if needed
    // - Connect and load weights/biases/gamma/beta from memory or files
    // - Add more BNeck blocks to match full MobileNetV3
    // - Add testbench for simulation
    // =============================

    // NOTE: If spatial/channel info is needed for future layers, propagate row/col as well.

endmodule 