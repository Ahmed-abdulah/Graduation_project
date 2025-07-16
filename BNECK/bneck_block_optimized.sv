/**
 * Optimized Bottleneck Block - Using Optimized Convolution Modules
 *
 * Key optimizations:
 * - Uses optimized conv_1x1_optimized and conv_3x3_dw_optimized modules
 * - No external memory files
 * - Pipelined processing
 * - Reduced resource usage
 * - Fast synthesis
 */

module bneck_block_optimized #(
    parameter INPUT_CHANNELS    = 16,
    parameter OUTPUT_CHANNELS   = 16,
    parameter EXPAND_CHANNELS   = 16,
    parameter STRIDE            = 1,
    parameter USE_SE            = 0,
    parameter USE_RESIDUAL      = 1,
    parameter ACTIVATION        = "RELU", // "RELU" or "HSWISH"
    parameter DATA_WIDTH        = 16,
    parameter FEATURE_SIZE      = 112
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // Input interface
    input  logic                    valid_in,
    input  logic [DATA_WIDTH-1:0]   data_in,
    input  logic [7:0]              channel_in,
    input  logic [7:0]              row_in,
    input  logic [7:0]              col_in,

    // Output interface
    output logic                    valid_out,
    output logic [DATA_WIDTH-1:0]   data_out,
    output logic [7:0]              channel_out,
    output logic [7:0]              row_out,
    output logic [7:0]              col_out,
    output logic                    ready
);

    // Inter-stage signals
    logic expand_valid_out, expand_ready;
    logic [DATA_WIDTH-1:0] expand_data_out;
    logic [7:0] expand_channel_out, expand_row_out, expand_col_out;

    logic dw_valid_out, dw_ready;
    logic [DATA_WIDTH-1:0] dw_data_out;
    logic [7:0] dw_channel_out, dw_row_out, dw_col_out;

    logic se_valid_out, se_ready;
    logic [DATA_WIDTH-1:0] se_data_out;
    logic [7:0] se_channel_out, se_row_out, se_col_out;

    logic proj_valid_out, proj_ready;
    logic [DATA_WIDTH-1:0] proj_data_out;
    logic [7:0] proj_channel_out, proj_row_out, proj_col_out;

    // Residual connection buffer
    logic [DATA_WIDTH-1:0] residual_data;
    logic [7:0] residual_channel, residual_row, residual_col;
    logic residual_valid;
    
    // Store residual connection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            residual_data <= '0;
            residual_channel <= '0;
            residual_row <= '0;
            residual_col <= '0;
            residual_valid <= 1'b0;
        end else if (valid_in && USE_RESIDUAL) begin
            residual_data <= data_in;
            residual_channel <= channel_in;
            residual_row <= row_in;
            residual_col <= col_in;
            residual_valid <= 1'b1;
        end
    end
    
    // 1. Expansion Convolution (1x1)
    generate
        if (EXPAND_CHANNELS > INPUT_CHANNELS) begin : gen_expand_conv
            conv_1x1_optimized #(
                .INPUT_CHANNELS(INPUT_CHANNELS),
                .OUTPUT_CHANNELS(EXPAND_CHANNELS),
                .DATA_WIDTH(DATA_WIDTH),
                .FEATURE_SIZE(FEATURE_SIZE)
            ) expand_conv (
                .clk(clk),
                .rst_n(rst_n),
                .valid_in(valid_in),
                .data_in(data_in),
                .channel_in(channel_in),
                .row_in(row_in),
                .col_in(col_in),
                .valid_out(expand_valid_out),
                .data_out(expand_data_out),
                .channel_out(expand_channel_out),
                .row_out(expand_row_out),
                .col_out(expand_col_out),
                .ready(expand_ready)
            );
        end else begin : gen_expand_bypass
            // No expansion needed - direct passthrough
            assign expand_valid_out = valid_in;
            assign expand_data_out = data_in;
            assign expand_channel_out = channel_in;
            assign expand_row_out = row_in;
            assign expand_col_out = col_in;
            assign expand_ready = 1'b1;
        end
    endgenerate
    
    // 2. Depthwise Convolution (3x3)
    conv_3x3_dw_optimized #(
        .CHANNELS(EXPAND_CHANNELS),
        .DATA_WIDTH(DATA_WIDTH),
        .FEATURE_SIZE(FEATURE_SIZE),
        .STRIDE(STRIDE)
    ) dw_conv (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(expand_valid_out),
        .data_in(expand_data_out),
        .channel_in(expand_channel_out),
        .row_in(expand_row_out),
        .col_in(expand_col_out),
        .valid_out(dw_valid_out),
        .data_out(dw_data_out),
        .channel_out(dw_channel_out),
        .row_out(dw_row_out),
        .col_out(dw_col_out),
        .ready(dw_ready)
    );
    
    // 3. Squeeze-and-Excitation (if enabled)
    generate
        if (USE_SE) begin : gen_se_module
            // Simplified SE module - just applies scaling
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    se_valid_out <= 1'b0;
                    se_data_out <= '0;
                    se_channel_out <= '0;
                    se_row_out <= '0;
                    se_col_out <= '0;
                end else begin
                    se_valid_out <= dw_valid_out;
                    se_data_out <= (dw_data_out * 3) >> 2; // Scale by 0.75
                    se_channel_out <= dw_channel_out;
                    se_row_out <= dw_row_out;
                    se_col_out <= dw_col_out;
                end
            end
            assign se_ready = 1'b1;
        end else begin : gen_se_bypass
            // No SE - direct passthrough
            assign se_valid_out = dw_valid_out;
            assign se_data_out = dw_data_out;
            assign se_channel_out = dw_channel_out;
            assign se_row_out = dw_row_out;
            assign se_col_out = dw_col_out;
            assign se_ready = 1'b1;
        end
    endgenerate
    
    // 4. Projection Convolution (1x1)
    conv_1x1_optimized #(
        .INPUT_CHANNELS(EXPAND_CHANNELS),
        .OUTPUT_CHANNELS(OUTPUT_CHANNELS),
        .DATA_WIDTH(DATA_WIDTH),
        .FEATURE_SIZE(FEATURE_SIZE)
    ) proj_conv (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(se_valid_out),
        .data_in(se_data_out),
        .channel_in(se_channel_out),
        .row_in(se_row_out),
        .col_in(se_col_out),
        .valid_out(proj_valid_out),
        .data_out(proj_data_out),
        .channel_out(proj_channel_out),
        .row_out(proj_row_out),
        .col_out(proj_col_out),
        .ready(proj_ready)
    );

    // 5. Residual Addition and Activation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= '0;
            channel_out <= '0;
            row_out <= '0;
            col_out <= '0;
        end else if (proj_valid_out) begin
            valid_out <= 1'b1;

            // Apply residual connection if enabled and conditions are met
            if (USE_RESIDUAL && (INPUT_CHANNELS == OUTPUT_CHANNELS) && (STRIDE == 1) && residual_valid) begin
                data_out <= apply_activation(proj_data_out + residual_data);
            end else begin
                data_out <= apply_activation(proj_data_out);
            end

            channel_out <= proj_channel_out;
            row_out <= proj_row_out;
            col_out <= proj_col_out;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // Activation function
    function automatic logic [DATA_WIDTH-1:0] apply_activation(input logic [DATA_WIDTH-1:0] data);
        if (ACTIVATION == "RELU") begin
            return (data[DATA_WIDTH-1]) ? '0 : data; // ReLU
        end else begin
            // Simplified H-Swish: x * (x + 3) / 6, approximated
            logic [DATA_WIDTH-1:0] x_plus_3 = data + 3;
            return (data * x_plus_3) >> 3; // Divide by 8 instead of 6 for simplicity
        end
    endfunction

    assign ready = expand_ready && dw_ready && se_ready && proj_ready;

endmodule


