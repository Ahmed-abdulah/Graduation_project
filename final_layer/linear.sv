// Synthesis-friendly version of linear layer
module linear #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter IN_FEATURES = 576,
    parameter OUT_FEATURES = 1280
) (
    input wire clk,
    input wire rst,
    input wire en,
    input wire signed [WIDTH-1:0] data_in [0:IN_FEATURES-1],
    input wire signed [WIDTH-1:0] weights [0:OUT_FEATURES*IN_FEATURES-1], // Changed to 1D array
    input wire signed [WIDTH-1:0] biases [0:OUT_FEATURES-1],
    input wire valid_in,
    output reg signed [WIDTH-1:0] data_out [0:OUT_FEATURES-1],
    output reg valid_out
);

    typedef enum logic [1:0] { IDLE, PROCESSING, DONE } state_t;
    state_t state;

    reg signed [WIDTH-1:0] data_in_buf [0:IN_FEATURES-1];
    reg signed [2*WIDTH+12:0] accum;
    reg [$clog2(IN_FEATURES):0] in_f_count;
    reg [$clog2(OUT_FEATURES):0] out_f_count;

    localparam signed [WIDTH-1:0] MAX_VAL = (1 << (WIDTH-1)) - 1;
    localparam signed [WIDTH-1:0] MIN_VAL = -(1 << (WIDTH-1));

    // Function to convert 2D weight indexing to 1D
    function automatic [$clog2(OUT_FEATURES*IN_FEATURES)-1:0] weight_index;
        input [$clog2(OUT_FEATURES)-1:0] out_idx;
        input [$clog2(IN_FEATURES)-1:0] in_idx;
        weight_index = out_idx * IN_FEATURES + in_idx;
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            valid_out <= 1'b0;
            in_f_count <= 0;
            out_f_count <= 0;
            accum <= 0;
            for (int i = 0; i < OUT_FEATURES; i++) begin
                data_out[i] <= 0;
            end
        end else if (en) begin
            if (state == IDLE) begin
                if (valid_in) begin
                    data_in_buf <= data_in;
                    state <= PROCESSING;
                    out_f_count <= 0;
                    in_f_count <= 0;
                    accum <= biases[0] << FRAC; // Load bias for the first output feature
                end
            end else if (state == PROCESSING) begin
                // MAC operation using 1D weight indexing
                accum <= accum + (data_in_buf[in_f_count] * weights[weight_index(out_f_count, in_f_count)]);

                if (in_f_count == IN_FEATURES - 1) begin
                    // Finished one output feature, store result
                    if (accum > (MAX_VAL << FRAC)) begin
                        data_out[out_f_count] <= MAX_VAL;
                    end else if (accum < (MIN_VAL << FRAC)) begin
                        data_out[out_f_count] <= MIN_VAL;
                    end else begin
                        data_out[out_f_count] <= accum >>> FRAC;
                    end

                    // Move to next output feature
                    in_f_count <= 0;
                    if (out_f_count == OUT_FEATURES - 1) begin
                        state <= DONE;
                    end else begin
                        out_f_count <= out_f_count + 1;
                        accum <= biases[out_f_count + 1] << FRAC; // Pre-load next bias
                    end
                end else begin
                    in_f_count <= in_f_count + 1;
                end
            end else if (state == DONE) begin
                valid_out <= 1'b1;
                state <= IDLE;
            end

            if (state != DONE) begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
