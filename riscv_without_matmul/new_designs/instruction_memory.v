module instruction_memory (
    input           clk_i,
    input           reset_i,
    input  [31:0]   iaddr_i,
    input           ird_i,
    output          accept,
    output reg [31:0] irdata_o
);

    assign accept = 1;
    reg [31:0] data;
    
    // Define HALT instruction - Using a custom instruction format
    // You can use an unused opcode or create a custom one
    // For RISC-V, we'll use a custom instruction: 32'hFFFFFFFF
    localparam HALT_INSTRUCTION = 32'hFFFFFFFF;


    // Combinatorial ROM:
    always @* begin
        case (iaddr_i[31:2])
                    30'd0: data = 32'h00000013; // nop
                    30'd1: data = 32'h02400493; // addi x9,x0,36
                    30'd2:  data = 32'h00100293; // addi x5, x0, 1
                    30'd3:  data = 32'h00542023; // sw x5, 0(x8)
                    30'd4:  data = 32'h0054a023; // sw x5, 0(x8)
                    30'd5:  data = 32'h00200293; // addi x5, x0, 2
                    30'd6:  data = 32'h00542223; // sw x5, 4(x8)
                    30'd7:  data = 32'h0054a223; // sw x5, 4(x8)
                    30'd8:  data = 32'h00300293; // addi x5, x0, 3
                    30'd9:  data = 32'h00542423; // sw x5, 8(x8)
                    30'd10: data = 32'h0054a423; // sw x5, 8(x8)
                    30'd11: data = 32'h00400293; // addi x5, x0, 4
                    30'd12: data = 32'h00542623; // sw x5, 12(x8)
                    30'd13: data = 32'h0054a623; // sw x5, 12(x8)
                    30'd14: data = 32'h00500293; // addi x5, x0, 5
                    30'd15: data = 32'h00542823; // sw x5, 16(x8)
                    30'd16: data = 32'h0054a823; // sw x5, 16(x8)
                    30'd17: data = 32'h00600293; // addi x5, x0, 6
                    30'd18: data = 32'h00542a23; // sw x5, 20(x8)
                    30'd19: data = 32'h0054aa23; // sw x5, 20(x8)
//                    30'd20: data = 32'h00700293; // addi x5, x0, 7
//                    30'd21: data = 32'h00542c23; // sw x5, 24(x8)
//                    30'd22: data = 32'h0054ac23; // sw x5, 24(x8)
//                    30'd23: data = 32'h00800293; // addi x5, x0, 8
//                    30'd24: data = 32'h00542e23; // sw x5, 28(x8)
//                    30'd25: data = 32'h0054ae23; // sw x5, 28(x8)
//                    30'd26: data = 32'h00900293; // addi x5, x0, 9
//                    30'd27: data = 32'h02542023; // sw x5, 32(x8)
//                    30'd28: data = 32'h0254a023; // sw x5, 32(x8)
                    30'd20: data = 32'h00040413; // addi s0, s0, 0
                    30'd21: data = 32'h02400493; // addi s1, s1, 36
                    30'd22: data = 32'h04890913; // addi s2, s2, 72
                    30'd23: data = 32'h00200b93; // addi s7, zero, 2 //k
                    30'd24: data = 32'h00300c13; //addi s8, zero, 3 //m
                    30'd25: data = 32'h00200c93; //addi s9,zero, 2, //n
                    30'd26: data = 32'h000009b3; // add s3, zero, zero
                    30'd27: data = 32'h00000a33; // add s4, zero, zero
                    30'd28: data = 32'h00000ab3; // add s5, zero, zero
                    30'd29: data = 32'h00000b33; // add s6, zero, zero
                   
                    30'd30: data = 32'h037982b3; // mul t0, s3, s7
                    30'd31: data = 32'h015282b3; // add t0, t0, s5
                    30'd32: data = 32'h00229293; // slli t0, t0, 2
                    30'd33: data = 32'h00828333; // add t1, s0, t0
                    30'd34: data = 32'h00032383; // lw t2, 0(t1)
                    
                    30'd35: data = 32'h037a82b3; // mul t0, s5, s7
                    30'd36: data = 32'h014282b3; // add t0, t0, s4
                    30'd37: data = 32'h00229293; // slli t0, t0, 2
                    30'd38: data = 32'h00928333; // add t1, s1, t0
                    30'd39: data = 32'h00032e03; // lw t3, 0(t1)
                    
                    30'd40: data = 32'h03c38eb3; // mul t4, t2, t3
                    30'd41: data = 32'h01db0b33; // add s6, s6, t4
                    30'd42: data = 32'h001a8a93; // addi s5, s5, 1
                    30'd43: data = 32'hfd7ac6e3; // blt s5, s7, loop_k
                    30'd44: data = 32'h037982b3; // mul t0, s3, s7
                    30'd45: data = 32'h014282b3; // add t0, t0, s4
                    30'd46: data = 32'h00229293; // slli t0, t0, 2
                    30'd47: data = 32'h00590333; // add t1, s2, t0
                    30'd48: data = 32'h01632023; // sw s6, 0(t1)
                    30'd49: data = 32'h001a0a13; // addi s4, s4, 1
                    30'd50: data = 32'hfb9a44e3; // blt s4, s9, loop_j
                    30'd51: data = 32'h00198993; // addi s3, s3, 1
                    30'd52: data = 32'hf989cee3; // blt s3, s8, loop_i
                    // HALT instruction immediately after MATMUL
                    30'd53: data = HALT_INSTRUCTION; // HALT - Stop execution here
                    default: data = 32'h00000013; // nop
             
        endcase
    end

    // Synchronous output:
    always @(posedge clk_i) begin
        if (reset_i) begin
            irdata_o <= 32'h00000013;
        end else if (ird_i) begin
            irdata_o <= data;
        end
    end
    
    

    

endmodule
