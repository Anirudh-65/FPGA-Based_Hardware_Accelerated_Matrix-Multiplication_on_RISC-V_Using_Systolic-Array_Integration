`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//Testbench for RISC-V with Clocking Wizard
//////////////////////////////////////////////////////////////////////////////////

module riscv_tb;

 
   reg clk;
    reg rst;
    wire out;
    // Clock generation: 1ns period
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end
    
    // DUT instantiation
    riscv_top uut (
        .clk_100mhz_i(clk),
        .rst_i(rst),
        .intr_i(1'b0),
        .tx_o(out)// No interrupt for now
    );
    
    // Simulation sequence
    initial begin
        // Initial reset
        rst = 1;
        #1000;
        rst = 0;
    
        $display("=======================================");
        $display("   RISC-V Core Simulation Started");
        $display("=======================================");
    
        // Let the processor run for some time
        #10000;
    
        $display("=======================================");
        $display("   Simulation Completed");
        $display("=======================================");
    
        $finish;
    end
endmodule