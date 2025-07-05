
module MemoryUartDumper #(
    parameter MEM_DUMP_SIZE = 256,      // Dump first 256 bytes
    parameter ADDR_WIDTH = 12,          // Address width for memory
    parameter CLK_FREQ_HZ = 50_000_000, // System clock frequency
    parameter BAUD_RATE = 115200        // Desired baud rate
)(
    input clk,
    input reset,
    input start_dump,
    output reg dump_in_progress,
    output reg [ADDR_WIDTH-1:0] mem_addr,
    input  [7:0] mem_rdata,
    output tx,
    output reg [7:0] bytes_sent_debug  // Debug output
);
    // UART transmitter signals
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    
    // FSM states
    localparam [3:0] S_IDLE         = 4'd0;
    localparam [3:0] S_START_HEADER = 4'd1;
    localparam [3:0] S_SEND_HEADER  = 4'd2;
    localparam [3:0] S_WAIT_HEADER  = 4'd3;
    localparam [3:0] S_READ_MEM     = 4'd4;
    localparam [3:0] S_SEND_HEX_H   = 4'd5;
    localparam [3:0] S_WAIT_HEX_H   = 4'd6;
    localparam [3:0] S_SEND_HEX_L   = 4'd7;
    localparam [3:0] S_WAIT_HEX_L   = 4'd8;
    localparam [3:0] S_SEND_SPACE   = 4'd9;
    localparam [3:0] S_WAIT_SPACE   = 4'd10;
    localparam [3:0] S_SEND_NEWLINE = 4'd11;
    localparam [3:0] S_WAIT_NEWLINE = 4'd12;
    localparam [3:0] S_FINISH       = 4'd13;
    
    reg [3:0] state;
    reg [ADDR_WIDTH-1:0] byte_counter;
    reg [3:0] header_counter;
    reg [7:0] current_byte;
    
    // UART transmitter instance
    uart_tx uart_tx_inst (
        .clk(clk), 
        .reset(reset), 
        .tx_start(tx_start), 
        .data(tx_data), 
        .tx(tx), 
        .tx_busy(tx_busy)
    );
    
    // Function to convert 4-bit nibble to ASCII hex
    function [7:0] nibble_to_hex;
        input [3:0] nibble;
        begin
            if (nibble < 4'hA)
                nibble_to_hex = 8'h30 + nibble;        // '0' to '9'
            else
                nibble_to_hex = 8'h41 + nibble - 4'hA; // 'A' to 'F'
        end
    endfunction
    
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            tx_start <= 1'b0;
            mem_addr <= 0;
            dump_in_progress <= 1'b0;
            tx_data <= 8'h00;
            byte_counter <= 0;
            header_counter <= 0;
            current_byte <= 8'h00;
            bytes_sent_debug <= 8'h00;
        end else begin
            tx_start <= 1'b0; // Default de-assertion
            
            case (state)
                S_IDLE: begin
                    if (start_dump) begin
                        dump_in_progress <= 1'b1;
                        mem_addr <= 0;
                        byte_counter <= 0;
                        header_counter <= 0;
                        bytes_sent_debug <= 8'h00;
                        state <= S_START_HEADER;
                    end
                end
                
                S_START_HEADER: begin
                    if (!tx_busy) begin
                        case(header_counter)
                            0:  tx_data <= "M";
                            1:  tx_data <= "e";
                            2:  tx_data <= "m";
                            3:  tx_data <= "o";
                            4:  tx_data <= "r";
                            5:  tx_data <= "y";
                            6:  tx_data <= " ";
                            7:  tx_data <= "D";
                            8:  tx_data <= "u";
                            9:  tx_data <= "m";
                            10: tx_data <= "p";
                            11: tx_data <= ":";
                            12: tx_data <= 8'h0D; // Carriage Return
                            13: tx_data <= 8'h0A; // Line Feed
                            default: tx_data <= " ";
                        endcase
                        tx_start <= 1'b1;
                        state <= S_SEND_HEADER;
                    end
                end
                
                S_SEND_HEADER: begin
                    state <= S_WAIT_HEADER;
                end
                
                S_WAIT_HEADER: begin
                    if (!tx_busy) begin
                        if (header_counter == 13) begin
                            state <= S_READ_MEM;
                        end else begin
                            header_counter <= header_counter + 1;
                            state <= S_START_HEADER;
                        end
                    end
                end
                
                S_READ_MEM: begin
                    // Give one clock cycle for memory read to complete
                    current_byte <= mem_rdata;
                    state <= S_SEND_HEX_H;
                end
                
                S_SEND_HEX_H: begin
                    if (!tx_busy) begin
                        tx_data <= nibble_to_hex(current_byte[7:4]);
                        tx_start <= 1'b1;
                        state <= S_WAIT_HEX_H;
                    end
                end
                
                S_WAIT_HEX_H: begin
                    if (!tx_busy) begin
                        state <= S_SEND_HEX_L;
                    end
                end
                
                S_SEND_HEX_L: begin
                    if (!tx_busy) begin
                        tx_data <= nibble_to_hex(current_byte[3:0]);
                        tx_start <= 1'b1;
                        state <= S_WAIT_HEX_L;
                    end
                end
                
                S_WAIT_HEX_L: begin
                    if (!tx_busy) begin
                        bytes_sent_debug <= bytes_sent_debug + 1;
                        
                        // Add newline every 16 bytes
                        if ((byte_counter + 1) % 16 == 0 && byte_counter > 0) begin
                            state <= S_SEND_NEWLINE;
                        end else begin
                            state <= S_SEND_SPACE;
                        end
                    end
                end
                
                S_SEND_SPACE: begin
                    if (!tx_busy) begin
                        tx_data <= 8'h20; // Space character
                        tx_start <= 1'b1;
                        state <= S_WAIT_SPACE;
                    end
                end
                
                S_WAIT_SPACE: begin
                    if (!tx_busy) begin
                        if (byte_counter == MEM_DUMP_SIZE - 1) begin
                            state <= S_FINISH;
                        end else begin
                            byte_counter <= byte_counter + 1;
                            mem_addr <= byte_counter + 1;
                            state <= S_READ_MEM;
                        end
                    end
                end
                
                S_SEND_NEWLINE: begin
                    if (!tx_busy) begin
                        tx_data <= 8'h0A; // Newline character
                        tx_start <= 1'b1;
                        state <= S_WAIT_NEWLINE;
                    end
                end
                
                S_WAIT_NEWLINE: begin
                    if (!tx_busy) begin
                        if (byte_counter == MEM_DUMP_SIZE - 1) begin
                            state <= S_FINISH;
                        end else begin
                            byte_counter <= byte_counter + 1;
                            mem_addr <= byte_counter + 1;
                            state <= S_READ_MEM;
                        end
                    end
                end
                
                S_FINISH: begin
                    if (!tx_busy) begin
                        dump_in_progress <= 1'b0;
                        state <= S_IDLE;
                    end
                end
                
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
