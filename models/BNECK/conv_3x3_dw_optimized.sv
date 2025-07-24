/**
 * Optimized 3x3 Depthwise Convolution Module
 * 
 * Key optimizations:
 * - No external memory files
 * - Reduced line buffer size
 * - Pipelined architecture
 * - Lightweight weight generation
 */

module conv_3x3_dw_optimized #(
    parameter CHANNELS      = 16,
    parameter DATA_WIDTH    = 16,
    parameter FEATURE_SIZE  = 112,
    parameter STRIDE        = 1,
    parameter PIPELINE_STAGES = 2
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

    // Lightweight weight generation (no memory files)
    function automatic logic [15:0] get_dw_weight(input int ch, input int pos);
        return ((ch * 9 + pos + 13) % 256) - 128; // Deterministic 3x3 pattern
    endfunction
    
    // Reduced line buffers (only store what we need)
    logic [DATA_WIDTH-1:0] line_buffer_0 [0:FEATURE_SIZE-1];
    logic [DATA_WIDTH-1:0] line_buffer_1 [0:FEATURE_SIZE-1];
    
    // 3x3 convolution window
    logic [DATA_WIDTH-1:0] window [0:8];
    
    // Pipeline registers
    logic [DATA_WIDTH-1:0] pipe_data [0:PIPELINE_STAGES-1];
    logic [7:0] pipe_channel [0:PIPELINE_STAGES-1];
    logic [7:0] pipe_row [0:PIPELINE_STAGES-1];
    logic [7:0] pipe_col [0:PIPELINE_STAGES-1];
    logic [PIPELINE_STAGES-1:0] pipe_valid;
    
    // Internal state
    logic [7:0] current_row, current_col;
    logic [7:0] output_row, output_col;
    logic [31:0] accumulator;
    logic [3:0] conv_step; // 0-8 for 3x3 convolution
    logic processing;
    
    // State machine
    typedef enum logic [2:0] {
        IDLE,
        LOAD_WINDOW,
        CONVOLVE,
        OUTPUT,
        SHIFT_BUFFERS
    } state_t;
    
    state_t current_state, next_state;
    
    // Pipeline advancement
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid <= '0;
            for (int i = 0; i < PIPELINE_STAGES; i++) begin
                pipe_data[i] <= '0;
                pipe_channel[i] <= '0;
                pipe_row[i] <= '0;
                pipe_col[i] <= '0;
            end
        end else begin
            pipe_valid <= {pipe_valid[PIPELINE_STAGES-2:0], valid_in};
            pipe_data[0] <= data_in;
            pipe_channel[0] <= channel_in;
            pipe_row[0] <= row_in;
            pipe_col[0] <= col_in;
            
            for (int i = 1; i < PIPELINE_STAGES; i++) begin
                pipe_data[i] <= pipe_data[i-1];
                pipe_channel[i] <= pipe_channel[i-1];
                pipe_row[i] <= pipe_row[i-1];
                pipe_col[i] <= pipe_col[i-1];
            end
        end
    end
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: if (valid_in) next_state = LOAD_WINDOW;
            LOAD_WINDOW: next_state = CONVOLVE;
            CONVOLVE: if (conv_step == 8) next_state = OUTPUT;
            OUTPUT: next_state = SHIFT_BUFFERS;
            SHIFT_BUFFERS: next_state = IDLE;
        endcase
    end
    
    // Line buffer management (simplified)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < FEATURE_SIZE; i++) begin
                line_buffer_0[i] <= '0;
                line_buffer_1[i] <= '0;
            end
        end else if (current_state == SHIFT_BUFFERS && valid_in) begin
            // Shift line buffers
            line_buffer_1[col_in] <= line_buffer_0[col_in];
            line_buffer_0[col_in] <= data_in;
        end
    end
    
    // 3x3 window loading
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 9; i++) window[i] <= '0;
        end else if (current_state == LOAD_WINDOW) begin
            // Load 3x3 window from line buffers and current input
            if (row_in > 0 && col_in > 0) begin
                window[0] <= line_buffer_1[col_in-1]; // Top-left
                window[1] <= line_buffer_1[col_in];   // Top-center
                window[2] <= (col_in < FEATURE_SIZE-1) ? line_buffer_1[col_in+1] : '0; // Top-right
                window[3] <= line_buffer_0[col_in-1]; // Mid-left
                window[4] <= line_buffer_0[col_in];   // Mid-center
                window[5] <= (col_in < FEATURE_SIZE-1) ? line_buffer_0[col_in+1] : '0; // Mid-right
                window[6] <= (col_in > 0) ? data_in : '0; // Bottom-left (current input shifted)
                window[7] <= data_in;                 // Bottom-center
                window[8] <= '0;                      // Bottom-right (next input)
            end else begin
                // Handle edge cases with zero padding
                for (int i = 0; i < 9; i++) window[i] <= (i == 4) ? data_in : '0;
            end
        end
    end
    
    // Convolution computation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= '0;
            conv_step <= '0;
        end else if (current_state == CONVOLVE) begin
            if (conv_step < 9) begin
                accumulator <= accumulator + 
                    (window[conv_step] * get_dw_weight(channel_in, conv_step));
                conv_step <= conv_step + 1;
            end
        end else if (current_state == IDLE) begin
            accumulator <= '0;
            conv_step <= '0;
        end
    end
    
    // Output generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= '0;
            channel_out <= '0;
            row_out <= '0;
            col_out <= '0;
        end else if (current_state == OUTPUT) begin
            valid_out <= 1'b1;
            data_out <= accumulator[DATA_WIDTH-1:0];
            channel_out <= pipe_channel[PIPELINE_STAGES-1];
            // Handle stride
            row_out <= (STRIDE == 2) ? pipe_row[PIPELINE_STAGES-1] >> 1 : pipe_row[PIPELINE_STAGES-1];
            col_out <= (STRIDE == 2) ? pipe_col[PIPELINE_STAGES-1] >> 1 : pipe_col[PIPELINE_STAGES-1];
        end else begin
            valid_out <= 1'b0;
        end
    end
    
    assign ready = (current_state == IDLE);

endmodule
