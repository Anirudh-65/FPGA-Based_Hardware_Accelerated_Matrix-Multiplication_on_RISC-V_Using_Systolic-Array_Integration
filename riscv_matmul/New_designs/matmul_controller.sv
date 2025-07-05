`timescale 1ns / 1ps

module matmul_controller #(
    parameter ROW_A = 2, parameter COL_A = 1,
    parameter ROW_B = 1, parameter COL_B = 2,
    parameter BUS_WIDTH = 32, parameter ELEMENT_WIDTH = 32
)(
    input               clk_i,
    input               rst_i,

    input               start_i,
    input [31:0]        addr_a_base_i,
    input [31:0]        addr_b_base_i,
    input [31:0]        addr_c_base_i,
    output reg          busy_o,

    output reg [31:0]   mem_addr_o,
    output reg          mem_rd_o,
    output reg [3:0]    mem_wr_o,
    output reg [31:0]   mem_data_wr_o,
    output reg          mem_req_o,
    input [31:0]        mem_data_rd_i,
    input               mem_gnt_i,
    input               mem_ack_i
);

    localparam S_IDLE       = 4'd0,
               S_FETCH_A    = 4'd1,
               S_FETCH_B    = 4'd2,
               S_COMPUTE    = 4'd3,
               S_WRITE_C    = 4'd4;

    reg [3:0] state_q, state_next;

    reg [ELEMENT_WIDTH-1:0] matrix_A [0:ROW_A-1][0:COL_A-1];
    reg [ELEMENT_WIDTH-1:0] matrix_B [0:ROW_B-1][0:COL_B-1];
    wire [2*ELEMENT_WIDTH-1:0] result_matrix [0:ROW_A-1][0:COL_B-1];

    localparam A_WORDS = ROW_A * COL_A;
    localparam B_WORDS = ROW_B * COL_B;
    localparam C_WORDS = ROW_A * COL_B;

    reg [$clog2(A_WORDS):0] read_a_count_q;
    reg [$clog2(B_WORDS):0] read_b_count_q;
    reg [$clog2(C_WORDS):0] write_c_count_q;

    reg [31:0] base_addr_a_q;
    reg [31:0] base_addr_b_q;
    reg [31:0] base_addr_c_q;

    reg systolic_initiate_q;
    wire systolic_done_w;

    systolic_array #(
        .ELEMENT_WIDTH(ELEMENT_WIDTH),
        .ROW_A(ROW_A), .COL_A(COL_A),
        .ROW_B(ROW_B), .COL_B(COL_B)
    ) u_systolic_array (
        .clk(clk_i),
        .reset(rst_i),
        .matrix_A(matrix_A),
        .matrix_B(matrix_B),
        .initiateCompute(systolic_initiate_q),
        .computeDone(systolic_done_w),
        .resMatrix(result_matrix)
    );

    // FSM Combinational Logic

    always @* begin
        state_next = state_q;
        mem_req_o = 0;
        mem_rd_o = 0;
        mem_wr_o = 0;
        mem_addr_o = 0;
        mem_data_wr_o = 0;

        case (state_q)
            S_IDLE: begin
                if (start_i)
                    state_next = S_FETCH_A;
            end

            S_FETCH_A: begin
                mem_req_o = 1;
                mem_rd_o  = 1;
                mem_addr_o = base_addr_a_q + (read_a_count_q * 4);
            end

            S_FETCH_B: begin
                mem_req_o = 1;
                mem_rd_o  = 1;
                mem_addr_o = base_addr_b_q + (read_b_count_q * 4);
            end

            S_COMPUTE: begin
                if (systolic_done_w)
                    state_next = S_WRITE_C;
            end

            S_WRITE_C: begin
                mem_req_o = 1;
                mem_wr_o  = 4'b1111;
                mem_addr_o = base_addr_c_q + (write_c_count_q * 4);
                mem_data_wr_o = result_matrix[write_c_count_q / COL_B][write_c_count_q % COL_B][31:0];
            end
        endcase
    end

    // FSM Sequential Logic + Pulse Logic
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_q <= S_IDLE;
            busy_o <= 0;
            read_a_count_q <= 0;
            read_b_count_q <= 0;
            write_c_count_q <= 0;
            systolic_initiate_q <= 0;
        end else begin
            state_q <= state_next;

            if (start_i) begin
                base_addr_a_q <= addr_a_base_i;
                base_addr_b_q <= addr_b_base_i;
                base_addr_c_q <= addr_c_base_i;
            end

            // pulse systolic_initiate_q for 1 cycle
            if (state_q == S_FETCH_B && read_b_count_q == B_WORDS - 1 && mem_ack_i)
                systolic_initiate_q <= 1;
            else
                systolic_initiate_q <= 0;

            if (mem_ack_i) begin
                if (state_q == S_FETCH_A) begin
                    matrix_A[read_a_count_q / COL_A][read_a_count_q % COL_A] <= mem_data_rd_i;
                    read_a_count_q <= read_a_count_q + 1;
                    if (read_a_count_q == A_WORDS - 1)
                        state_q <= S_FETCH_B;
                end
                else if (state_q == S_FETCH_B) begin
                    matrix_B[read_b_count_q / COL_B][read_b_count_q % COL_B] <= mem_data_rd_i;
                    read_b_count_q <= read_b_count_q + 1;
                    if (read_b_count_q == B_WORDS - 1)
                        state_q <= S_COMPUTE;
                end
                else if (state_q == S_WRITE_C) begin
                    write_c_count_q <= write_c_count_q + 1;
                    if (write_c_count_q == C_WORDS - 1)
                        state_q <= S_IDLE;
                end
            end

            if (state_next != state_q) begin
                if (state_next == S_FETCH_A) read_a_count_q <= 0;
                if (state_next == S_FETCH_B) read_b_count_q <= 0;
                if (state_next == S_WRITE_C) write_c_count_q <= 0;
            end

            busy_o <= (state_q != S_IDLE) || (state_next != S_IDLE);
        end
    end

endmodule