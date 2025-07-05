`timescale 1ns / 1ps
module instruction_memory (
    input       	clk_i,
    input       	reset_i,
    input  [31:0]   iaddr_i,
    input       	ird_i,
    output      	accept,
    output reg [31:0] irdata_o
);
    assign accept = 1;
    reg [31:0] data;
    
// Halt Instruction
    localparam HALT_INSTRUCTION = 32'hFFFFFFFF;
    
    always @* begin
        case (iaddr_i[31:2])
            30'd0: data = 32'h00000013; // nop
            30'd1: data = 32'h2400493; // addi x9 x0 64 --> 36
            30'd2:  data = 32'h00100293; // addi x5, x0, 1
            30'd3:  data = 32'h00542023; // sw x5, 0(x8)
            30'd4:  data = 32'h0054a023; // sw x5, 0(x9)
            30'd5:  data = 32'h00200293; // addi x5, x0, 2
            30'd6:  data = 32'h00542223; // sw x5, 4(x8)
            30'd7:  data = 32'h0054a223; // sw x5, 4(x8)
//            30'd8:  data = 32'h00300293; // addi x5, x0, 3
//            30'd9:  data = 32'h00542423; // sw x5, 8(x8)
//            30'd10: data = 32'h0054a423; // sw x5, 8(x8)
//            30'd11: data = 32'h00400293; // addi x5, x0, 4
//            30'd12: data = 32'h00542623; // sw x5, 12(x8)
//            30'd13: data = 32'h0054a623; // sw x5, 12(x8)
//            30'd14: data = 32'h00500293; // addi x5, x0, 5
//            30'd15: data = 32'h00542823; // sw x5, 16(x8)
//            30'd16: data = 32'h0054a823; // sw x5, 16(x8)
//            30'd17: data = 32'h00600293; // addi x5, x0, 6
//            30'd18: data = 32'h00542a23; // sw x5, 20(x8)
//            30'd19: data = 32'h0054aa23; // sw x5, 20(x8)
//            30'd20: data = 32'h00700293; // addi x5, x0, 7
//            30'd21: data = 32'h00542c23; // sw x5, 24(x8)
//            30'd22: data = 32'h0054ac23; // sw x5, 24(x8)
//            30'd23: data = 32'h00800293; // addi x5, x0, 8
//            30'd24: data = 32'h00542e23; // sw x5, 28(x8)
//            30'd25: data = 32'h0054ae23; // sw x5, 28(x8)
//            30'd26: data = 32'h00900293; // addi x5, x0, 9
//            30'd27: data = 32'h02542023; // sw x5, 32(x8)
//            30'd28: data = 32'h0254a023; // sw x5, 32(x8)
//            30'd29: data = 32'h00a00293; // addi x5, x0, 10            
//            30'd30: data = 32'h02542223; // sw x5, 36(x8)
//            30'd31: data = 32'h0254a223; // sw x5, 36(x9)
//            30'd32: data = 32'h00b00293; // addi x5, x0, 11
//            30'd33: data = 32'h02542423; // sw x5, 40(x8)
//            30'd34: data = 32'h0254a423; // sw x5, 40(x9)
//            30'd35: data = 32'h00c00293; // addi x5, x0, 12
//            30'd36: data = 32'h02542623; // sw x5, 44(x8)
//            30'd37: data = 32'h0254a623; // sw x5, 44(x9)
//            30'd38: data = 32'h00d00293; // addi x5, x0, 13
//            30'd39: data = 32'h02542823; // sw x5, 48(x8)
//            30'd40: data = 32'h0254a823; // sw x5, 48(x9)
//            30'd41: data = 32'h00e00293; // addi x5, x0, 14
//            30'd42: data = 32'h02542a23; // sw x5, 52(x8)
//            30'd43: data = 32'h0254aa23; // sw x5, 52(x9)
//            30'd44: data = 32'h00f00293; // addi x5, x0, 15
//            30'd45: data = 32'h02542c23; // sw x5, 56(x8)
//            30'd46: data = 32'h0254ac23; // sw x5, 56(x9)
//            30'd47: data = 32'h01000293; // addi x5, x0, 16
//            30'd48: data = 32'h02542e23; // sw x5, 60(x8)
//            30'd49: data = 32'h0254ae23; // sw x5, 60(x9)
            
//            // Matrix multiplication instructions
            30'd8: data = 32'h4800e13; // addi x28 0 128
            30'd9: data = 32'h00940e0b; // MATMUL instruction (custom)
//            30'd31: data = 32'h00000013; // nop
            // HALT instruction immediately after MATMUL
  
            
           
            
            default: data = 32'h00000013; // nop
        endcase
    end
    
    always @(posedge clk_i) begin
        if (reset_i) begin
            irdata_o <= 32'h00000013;
        end else if (ird_i) begin
            irdata_o <= data;
        end
    end
    
endmodule