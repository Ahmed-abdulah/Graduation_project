/**
 * Optimized 1x1 Pointwise Convolution Module
 * 
 * Key optimizations:
 * - No external memory files
 * - Lightweight parameter-based weights
 * - Pipelined architecture
 * - Reduced resource usage
 */

module conv_1x1_optimized #(
    parameter INPUT_CHANNELS  = 16,
    parameter OUTPUT_CHANNELS = 16,
    parameter DATA_WIDTH      = 16,
    parameter FEATURE_SIZE    = 112,
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
    function automatic logic [15:0] get_weight(input int in_ch, input int out_ch);
        return ((in_ch + out_ch * 7) % 256) - 128; // Deterministic pattern
    endfunction
    
    // Pipeline registers
    logic [DATA_WIDTH-1:0] pipe_data [0:PIPELINE_STAGES-1];
    logic [7:0] pipe_channel [0:PIPELINE_STAGES-1];
    logic [7:0] pipe_row [0:PIPELINE_STAGES-1];
    logic [7:0] pipe_col [0:PIPELINE_STAGES-1];
    logic [PIPELINE_STAGES-1:0] pipe_valid;
    
    // Accumulator and computation
    logic [31:0] accumulator;
    logic [7:0] current_out_channel;
    logic [7:0] input_count;
    logic computing;
    
    // Input buffer (small, fixed size)
    logic [DATA_WIDTH-1:0] input_buffer [0:15]; // Max 16 channels
    logic [7:0] buffer_count;
    
    // State machine
    typedef enum logic [1:0] {
        IDLE,
        COLLECT,
        COMPUTE,
        OUTPUT
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
            // Shift pipeline
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
            IDLE: if (valid_in) next_state = COLLECT;
            COLLECT: if (buffer_count == INPUT_CHANNELS-1) next_state = COMPUTE;
            COMPUTE: if (current_out_channel == OUTPUT_CHANNELS-1) next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
        endcase
    end
    
    // Input collection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_count <= '0;
            for (int i = 0; i < 16; i++) input_buffer[i] <= '0;
        end else if (current_state == COLLECT && valid_in) begin
            input_buffer[channel_in] <= data_in;
            buffer_count <= buffer_count + 1;
        end else if (current_state == IDLE) begin
            buffer_count <= '0;
        end
    end
    
    // Computation engine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= '0;
            current_out_channel <= '0;
            input_count <= '0;
        end else if (current_state == COMPUTE) begin
            if (input_count < INPUT_CHANNELS) begin
                // MAC operation with lightweight weights
                accumulator <= accumulator + 
                    (input_buffer[input_count] * get_weight(input_count, current_out_channel));
                input_count <= input_count + 1;
            end else begin
                // Move to next output channel
                current_out_channel <= current_out_channel + 1;
                input_count <= '0;
                accumulator <= '0;
            end
        end else if (current_state == IDLE) begin
            current_out_channel <= '0;
            input_count <= '0;
            accumulator <= '0;
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
            channel_out <= current_out_channel;
            row_out <= pipe_row[PIPELINE_STAGES-1];
            col_out <= pipe_col[PIPELINE_STAGES-1];
        end else begin
            valid_out <= 1'b0;
        end
    end
    
    assign ready = (current_state == IDLE);

endmodule
