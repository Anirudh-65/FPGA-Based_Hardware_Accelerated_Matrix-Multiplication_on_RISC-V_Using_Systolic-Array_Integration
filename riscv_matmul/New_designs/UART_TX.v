// UART Transmitter Module
// Baud rate: 9600, 8 data bits, 1 stop bit, no parity
module uart_tx (
    input wire clk,           // 100MHz system clock
    input wire reset,         // Reset signal
    input wire [7:0] data,    // 8-bit data to transmit
    input wire tx_start,      // Start transmission
    output reg tx,            // UART TX line
    output reg tx_busy        // Transmission busy flag
);

    // Baud rate generation
    // For 9600 baud at 50MHz: 100,000,000 / 9600 = 5209
    parameter BAUD_RATE_DIV = 7292;
    
    // States
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    
    reg [1:0] state;
    reg [13:0] baud_counter;
    reg [2:0] bit_counter;
    reg [7:0] tx_data;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            baud_counter <= 0;
            bit_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    baud_counter <= 0;
                    bit_counter <= 0;
                    if (tx_start) begin
                        tx_data <= data;
                        tx_busy <= 1'b1;
                        state <= START;
                    end
                end
                
                START: begin
                    tx <= 1'b0;  // Start bit
                    if (baud_counter == BAUD_RATE_DIV - 1) begin
                        baud_counter <= 0;
                        state <= DATA;
                    end else begin
                        baud_counter <= baud_counter + 1;
                    end
                end
                
                DATA: begin
                    tx <= tx_data[bit_counter];
                    if (baud_counter == BAUD_RATE_DIV - 1) begin
                        baud_counter <= 0;
                        if (bit_counter == 7) begin
                            bit_counter <= 0;
                            state <= STOP;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end else begin
                        baud_counter <= baud_counter + 1;
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;  // Stop bit
                    if (baud_counter == BAUD_RATE_DIV - 1) begin
                        baud_counter <= 0;
                        state <= IDLE;
                    end else begin
                        baud_counter <= baud_counter + 1;
                    end
                end
            endcase
        end
    end
endmodule
