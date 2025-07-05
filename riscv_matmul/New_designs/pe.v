`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 15:02:00
// Design Name: 
// Module Name: pe
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


module PE #(
    parameter WIDTH = 16
)(
    input clk,
    input reset,
    input [WIDTH-1:0] a_in,
    input [WIDTH-1:0] b_in,
    input [2*WIDTH-1:0] c_in,
    output reg [WIDTH-1:0] a_out,
    output reg [WIDTH-1:0] b_out,
    output reg [2*WIDTH-1:0] c_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_out <= 0;
            b_out <= 0;
            c_out <= 0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
            c_out <= c_in + a_in * b_in;
        end
    end
endmodule
