// Dual-port memory module for RISC-V + Memory Dumper
`timescale 1ns / 1ps
module memory (
// Port 0: For the CPU (with handshake)
input               clk_i,
input               reset_i,
output reg          accept,
output reg          acknowledge,
input   [31:0]      daddr_i,
input   [31:0]      dwdata_i,
output reg [31:0]   drdata_o,
input               drd_i,
input   [3:0]       dbe_w,


// Port 1: For Memory Dumper (read-only)
input   [11:0]      dump_addr,    // Byte address for dumper
output  [7:0]       dump_data     // Byte data output
);


// ADDR_BITS = 10 gives 2^10 = 1024 words. 1024 * 4 bytes/word = 4096 bytes.
localparam ADDR_BITS = 10;
reg [31:0] data_mem [0:(2**ADDR_BITS)-1];

// Initialize memory with some test data
initial begin
    // Initialize first few words with test pattern
    data_mem[0] = 32'h48656C6C;  // "Hell" in ASCII
    data_mem[1] = 32'h6F20576F;  // "o Wo" in ASCII  
    data_mem[2] = 32'h726C6421;  // "rld!" in ASCII
    data_mem[3] = 32'h0A0D0000;  // "\r\n" + padding
    data_mem[4] = 32'h12345678;  // Test hex pattern
    data_mem[5] = 32'hABCDEF00;  // Test hex pattern
    data_mem[6] = 32'hDEADBEEF;  // Test hex pattern
    data_mem[7] = 32'hCAFEBABE;  // Test hex pattern
    
    // Initialize remaining memory to incrementing pattern
    for (integer i = 8; i < (2**ADDR_BITS); i = i + 1) begin
        data_mem[i] = i;
    end
end

// --- Logic for CPU Port ---
wire [ADDR_BITS-1:0] word_address = daddr_i[ADDR_BITS+1:2];
wire write_request = |dbe_w;

always @(posedge clk_i) begin
    if (write_request) begin
        if (dbe_w[0]) data_mem[word_address][7:0]   <= dwdata_i[7:0];
        if (dbe_w[1]) data_mem[word_address][15:8]  <= dwdata_i[15:8];
        if (dbe_w[2]) data_mem[word_address][23:16] <= dwdata_i[23:16];
        if (dbe_w[3]) data_mem[word_address][31:24] <= dwdata_i[31:24];
    end
    if (drd_i) begin
        drdata_o <= data_mem[word_address];
    end
end

reg request_pending_q;
always @(posedge clk_i) begin
    if (reset_i) begin
        accept <= 1'b1;
        acknowledge <= 1'b0;
        request_pending_q <= 1'b0;
    end else begin
        acknowledge <= 1'b0;
        if (request_pending_q) begin
            acknowledge <= 1'b1;
            request_pending_q <= 1'b0;
            accept <= 1'b1;
        end else if (accept && (drd_i || write_request)) begin
            request_pending_q <= 1'b1;
            accept <= 1'b0;
        end
    end
end

// --- Logic for Memory Dumper Port ---
// Convert byte address to word address and byte select
wire [ADDR_BITS-1:0] dump_word_addr = dump_addr[ADDR_BITS+1:2];
wire [1:0] dump_byte_select = dump_addr[1:0];

// Byte selection from 32-bit word
reg [7:0] selected_byte;
always @(*) begin
    case (dump_byte_select)
        2'b00: selected_byte = data_mem[dump_word_addr][7:0];
        2'b01: selected_byte = data_mem[dump_word_addr][15:8];
        2'b10: selected_byte = data_mem[dump_word_addr][23:16];
        2'b11: selected_byte = data_mem[dump_word_addr][31:24];
    endcase
end

assign dump_data = selected_byte;

endmodule