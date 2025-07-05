


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2025 16:18:26
// Design Name: 
// Module Name: riscv_performance_counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
module riscv_performance_counter (
    input wire clk_i,
    input wire reset_i,
    input wire [31:0] pc_i,              
    input wire [31:0] instruction_i,     // Current instruction
    input wire instruction_valid_i,      // Valid instruction signal
    output reg [31:0] cycle_count_o,     // Total cycles counted
    output reg counting_active_o,        // Indicates if counter is running
    output reg measurement_done_o,       // Indicates measurement is complete
    output wire halt_detected_o          // HALT detection output
);
    // States for the counter FSM
    localparam IDLE = 2'b00;
    localparam COUNTING = 2'b01;
    localparam DONE = 2'b10;

    // Define HALT instruction pattern
    localparam HALT_INSTRUCTION = 32'hFFFFFFFF;

    reg [1:0] state, next_state;
    reg [31:0] counter;
    reg first_instruction_detected;
    reg halt_flag;

    // Detect HALT instruction
    wire halt_instruction;
    assign halt_instruction = (pc_i == 32'd168) && instruction_valid_i;
    assign halt_detected_o = halt_flag;

    // Detect start condition (PC = 0)
    wire start_condition;
    assign start_condition = (pc_i == 32'h00000000) && instruction_valid_i;

    // State register
    always @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            state <= IDLE;
            counter <= 32'b0;
            first_instruction_detected <= 1'b0;
            halt_flag <= 1'b0;
        end else begin
            state <= next_state;

            // Increment counter when counting
            if (state == COUNTING && instruction_valid_i) begin
                counter <= counter + 1;
            end

            // Set halt flag when HALT detected
            if (halt_instruction) begin
                halt_flag <= 1'b1;
            end

            // Track first instruction
            if (start_condition && !first_instruction_detected) begin
                first_instruction_detected <= 1'b1;
            end
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_condition && !first_instruction_detected) begin
                    next_state = COUNTING;
                end
            end
            COUNTING: begin
                if (halt_instruction) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                // Stay in done state until reset
                next_state = DONE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output assignments
    always @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            cycle_count_o <= 32'b0;
            counting_active_o <= 1'b0;
            measurement_done_o <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    counting_active_o <= 1'b0;
                    measurement_done_o <= 1'b0;
                end
                COUNTING: begin
                    counting_active_o <= 1'b1;
                    measurement_done_o <= 1'b0;
                end
                DONE: begin
                    counting_active_o <= 1'b0;
                    measurement_done_o <= 1'b1;
                    cycle_count_o <= counter;
                end
                default: begin
                    counting_active_o <= 1'b0;
                    measurement_done_o <= 1'b0;
                end
            endcase
        end
    end

endmodule