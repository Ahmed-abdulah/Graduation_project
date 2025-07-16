/**
 * Optimized MobileNetV3 Top Module - Fast Synthesis Version
 * 
 * Key optimizations:
 * - Uses optimized sequence module
 * - Simplified control logic
 * - No memory file dependencies
 * - Fast synthesis targeting <10 minutes
 */

module mobilenetv3_top_optimized #(
    parameter DATA_WIDTH = 16,
    parameter INPUT_SIZE = 224
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Control signals
    input  logic                    start,
    input  logic                    enable,
    
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
    output logic                    ready,
    output logic                    done,
    
    // Enhanced debug outputs
    output logic [1:0]              debug_bneck_state,
    output logic                    debug_sequence_valid_in,
    output logic                    debug_buffer_valid,
    output logic [7:0]              debug_buffer_count,
    output logic                    debug_block0_valid_out
);

    // Internal state
    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        COMPLETE
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal signals
    logic sequence_valid_in, sequence_ready, sequence_done;
    logic [DATA_WIDTH-1:0] sequence_data_in;
    logic [7:0] sequence_channel_in, sequence_row_in, sequence_col_in;
    
    // Debug tracking signals
    logic debug_buffer_valid_internal;
    logic [7:0] debug_buffer_count_internal;
    logic debug_block0_valid_internal;
    
    // State machine - simplified without start pulse
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
            IDLE: if (start && enable && valid_in) next_state = PROCESSING;  // Data-driven transition
            PROCESSING: if (sequence_done) next_state = COMPLETE;
            COMPLETE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Simple channel tracking for debug
    logic [3:0] channel_counter;
    logic channel_complete;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            channel_counter <= 0;
            channel_complete <= 0;
            debug_buffer_count_internal <= 0;
            debug_buffer_valid_internal <= 0;
        end else if (sequence_valid_in) begin
            if (sequence_channel_in[3:0] == 15) begin
                channel_counter <= 0;
                channel_complete <= 1;
                debug_buffer_count_internal <= 16;
            end else begin
                channel_counter <= channel_counter + 1;
                channel_complete <= 0;
                debug_buffer_count_internal <= channel_counter + 1;
            end
            debug_buffer_valid_internal <= channel_complete;
        end else begin
            channel_complete <= 0;
            debug_buffer_valid_internal <= 0;
        end
    end
    
    // Input control - remove circular dependency
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sequence_valid_in <= 1'b0;
            sequence_data_in <= '0;
            sequence_channel_in <= '0;
            sequence_row_in <= '0;
            sequence_col_in <= '0;
        end else if (enable) begin  // Always pass through when enabled
            sequence_valid_in <= valid_in;
            sequence_data_in <= data_in;
            sequence_channel_in <= channel_in;
            sequence_row_in <= row_in;
            sequence_col_in <= col_in;
        end else begin
            sequence_valid_in <= 1'b0;
        end
    end
    
    // Instantiate optimized sequence (defined in same file as bneck_block_optimized)
    mobilenetv3_sequence_optimized #(
        .DATA_WIDTH(DATA_WIDTH)
    ) sequence_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(sequence_valid_in),
        .data_in(sequence_data_in),
        .channel_in(sequence_channel_in),
        .row_in(sequence_row_in),
        .col_in(sequence_col_in),
        .valid_out(valid_out),
        .data_out(data_out),
        .channel_out(channel_out),
        .row_out(row_out),
        .col_out(col_out),
        .ready(sequence_ready),
        .done(sequence_done)
    );
    
    // Output control
    assign ready = (current_state == IDLE) || sequence_ready;
    assign done = (current_state == COMPLETE);
    
    // Enhanced debug assignments
    assign debug_bneck_state = current_state;
    assign debug_sequence_valid_in = sequence_valid_in;
    assign debug_buffer_valid = debug_buffer_valid_internal;
    assign debug_buffer_count = debug_buffer_count_internal;
    assign debug_block0_valid_out = debug_block0_valid_internal;
    
    // Connect debug signal from sequence
    assign debug_block0_valid_internal = sequence_inst.block_valid_out[0];
    
    // Debug: Monitor state transitions
    always @(posedge clk) begin
        if (current_state != next_state) begin
            $display("BNeck state transition: %s -> %s at time %0t", 
                     current_state.name(), next_state.name(), $time);
        end
    end

endmodule
