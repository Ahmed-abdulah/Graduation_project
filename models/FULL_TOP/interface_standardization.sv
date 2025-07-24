// Standardized interface adapter
module array_dimension_adapter #(
    parameter DATA_WIDTH = 16,
    parameter IN_CHANNELS = 160,
    parameter IN_HEIGHT = 7,
    parameter IN_WIDTH = 7,
    parameter OUT_CHANNELS = 160
)(
    input  wire clk, rst,
    input  wire [DATA_WIDTH-1:0] data_in [IN_CHANNELS-1:0][IN_HEIGHT-1:0][IN_WIDTH-1:0],
    input  wire valid_in,
    output wire [DATA_WIDTH-1:0] data_out [OUT_CHANNELS-1:0],
    output wire valid_out
);
    // Flattening 3D array to 1D for next module
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else if (valid_in) begin
            for (int c = 0; c < OUT_CHANNELS; c++) begin
                // Global average pooling to convert spatial dimensions to single value
                data_out[c] <= calculate_avg(data_in[c]);
            end
            valid_out <= valid_in;
        end
    end

