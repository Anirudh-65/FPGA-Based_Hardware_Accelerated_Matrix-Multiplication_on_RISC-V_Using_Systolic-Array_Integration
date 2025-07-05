`timescale 1ns / 1ps

    module systolic_array#(
    parameter ELEMENT_WIDTH = 16,
    parameter ROW_A = 2,
    parameter COL_A = 2,
    parameter ROW_B = 2,
    parameter COL_B = 2
)(
    input clk,
    input reset,
    input [ELEMENT_WIDTH-1:0] matrix_A [0:ROW_A-1][0:COL_A-1],
    input [ELEMENT_WIDTH-1:0] matrix_B [0:ROW_B-1][0:COL_B-1],
    input initiateCompute,
    output reg computeDone,
    output reg [2*ELEMENT_WIDTH-1:0] resMatrix [0:ROW_A-1][0:COL_B-1]
);
    localparam PADDED_A_COLS = COL_A + (ROW_A-1) + 2*(COL_B-1) + 1;
    localparam PADDED_B_COLS = ROW_B + (COL_B-1) + 2*(ROW_A-1) + 1;
    reg [ELEMENT_WIDTH-1:0] temp_A [0:ROW_A-1][0:COL_B-1];
    reg [ELEMENT_WIDTH-1:0] temp_B [0:ROW_A-1][0:COL_B-1];
    reg [ELEMENT_WIDTH-1:0] A [0:ROW_A-1][0:PADDED_A_COLS-1];
    reg [ELEMENT_WIDTH-1:0] B [0:COL_B-1][0:PADDED_B_COLS-1];
    integer count;
    reg busy;
    localparam COMPUTE_CYCLES = ROW_B + (COL_B-1) + ROW_A -1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0; computeDone <= 0; busy <= 0;
            for (int i=0; i<ROW_A; i=i+1) for (int j=0; j<COL_B; j=j+1) resMatrix[i][j] <= 0;
        end else begin
            if (initiateCompute) begin
                busy <= 1; computeDone <= 0; count <= 0;
                for(int i=0; i<ROW_A; i=i+1) for(int j=0; j<COL_B; j=j+1) resMatrix[i][j] <= 0;
                for (int i=0; i<ROW_A; i=i+1) for (int j=0; j<PADDED_A_COLS; j=j+1) A[i][j] = 0;
                for (int i=0; i<COL_B; i=i+1) for (int j=0; j<PADDED_B_COLS; j=j+1) B[i][j] = 0;
                for(int i=0; i<ROW_A; i++) for(int j=0; j<COL_A; j++) A[i][j+i+ROW_A-1] = matrix_A[i][j];
                for(int i=0; i<ROW_B; i++) for(int j=0; j<COL_B; j++) B[j][i+j+ROW_A-1] = matrix_B[i][j];
            end
            if (busy) begin
                for(int i=0; i<ROW_A; i++) for(int j=0; j<COL_B; j++) temp_A[i][j] = A[i][COL_B-1-j+count];
                for(int i=0; i<ROW_A; i++) for(int j=0; j<COL_B; j++) temp_B[i][j] = B[j][ROW_A-1-i+count];
                for(int i=0; i<ROW_A; i=i+1) for(int j=0; j<COL_B; j=j+1) resMatrix[i][j] <= resMatrix[i][j] + temp_A[i][j] * temp_B[i][j];
                if (count == COMPUTE_CYCLES) {computeDone, busy} <= {1'b1, 1'b0};
                else count <= count + 1;
            end
        end
    end
endmodule