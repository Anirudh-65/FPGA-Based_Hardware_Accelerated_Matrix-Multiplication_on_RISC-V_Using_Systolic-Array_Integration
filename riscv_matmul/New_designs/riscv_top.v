// RISC-V Top Module with Clock Wizard, Performance Counter and LED Display
module riscv_top
#(
    parameter SUPPORT_MULDIV   = 1,
    parameter SUPPORT_SUPER    = 0,
    parameter SUPPORT_MMU      = 0,
    parameter SUPPORT_LOAD_BYPASS = 1,
    parameter SUPPORT_MUL_BYPASS = 1,
    parameter SUPPORT_REGFILE_XILINX = 0,
    parameter EXTRA_DECODE_STAGE = 0,
    parameter MEM_CACHE_ADDR_MIN = 32'h80000000,
    parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff
)
(
    input clk_100mhz_i,  // 100MHz input clock
    input rst_i,
    input intr_i,
    output wire tx_o,
    output wire [15:0] led_o        
);

wire clk_50mhz;        
wire clk_locked;       
wire rst_internal;     


assign rst_internal = rst_i | ~clk_locked;


clk_wiz_0 clock_wizard_inst (
    .clk_out1(clk_50mhz),      
    .reset(rst_i),             
    .locked(clk_locked),       
    .clk_in1(clk_100mhz_i)     // 100MHz input clock
);


reg [25:0] startup_counter;
reg dump_trigger;
reg startup_complete;

always @(posedge clk_50mhz) begin
    if (rst_internal) begin
        startup_counter <= 0;
        dump_trigger <= 1'b0;
        startup_complete <= 1'b0;
    end else begin
        dump_trigger <= 1'b0;
        
        if (!startup_complete) begin
         
            if (startup_counter == 26'd25_000_000) begin 
                dump_trigger <= 1'b1;
                startup_complete <= 1'b1;
            end else begin
                startup_counter <= startup_counter + 1;
            end
        end
    end
end

wire mem_d_accept_i;
wire mem_d_ack_i;
wire [31:0] mem_d_data_rd_i;
wire mem_i_accept_i;
wire mem_i_valid_i;
wire [31:0] mem_i_inst_i;
wire [31:0] mem_d_addr_o;
wire [31:0] mem_d_data_wr_o;
wire mem_d_rd_o;
wire [3:0]  mem_d_wr_o;
wire mem_d_cacheable_o;
wire [10:0] mem_d_req_tag_o;
wire mem_d_invalidate_o;
wire mem_d_writeback_o;
wire mem_d_flush_o;
wire mem_i_rd_o;
wire mem_i_flush_o;
wire mem_i_invalidate_o;
wire [31:0] mem_i_pc_o;

wire dump_in_progress;
wire [11:0] dump_mem_addr;
wire [7:0] dump_mem_data;
wire [7:0] bytes_sent_debug;

wire [31:0] cycle_count;
wire counting_active;
wire measurement_done;
wire halt_detected;

reg [15:0] led_display;
reg [25:0] blink_counter;
reg blink_state;

always @(posedge clk_50mhz) begin
    if (rst_internal) begin
        blink_counter <= 0;
        blink_state <= 0;
    end else begin
       
        if (blink_counter == 26'd27_000_000) begin 
            blink_counter <= 0;
            blink_state <= ~blink_state;
        end else begin
            blink_counter <= blink_counter + 1;
        end
    end
end

// LED Display Logic
always @(posedge clk_50mhz) begin
    if (rst_internal) begin
        led_display <= 16'h0000;
    end else begin
        if (measurement_done && halt_detected) begin
      
            led_display[12:0] <= cycle_count[12:0];   
            led_display[13] <= measurement_done;      
            led_display[14] <= halt_detected;         
            led_display[15] <= 1'b1;                  
        end else if (counting_active) begin
    
            led_display[12:0] <= cycle_count[12:0];   
            led_display[13] <= blink_state;           
            led_display[14] <= counting_active;       
            led_display[15] <= blink_state;           
        end else begin
            // Idle state - show system status
            led_display[0] <= ~rst_internal;          
            led_display[1] <= startup_complete;       
            led_display[2] <= dump_in_progress;       
            led_display[3] <= clk_locked;             
            led_display[15:4] <= 12'b0;              
        end
    end
end

assign led_o = led_display;

// RISC-V Core - now uses 50MHz clock
riscv_core #(
    .SUPPORT_MULDIV(SUPPORT_MULDIV),
    .SUPPORT_SUPER(SUPPORT_SUPER),
    .SUPPORT_MMU(SUPPORT_MMU),
    .SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS),
    .SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS),
    .SUPPORT_REGFILE_XILINX(SUPPORT_REGFILE_XILINX),
    .EXTRA_DECODE_STAGE(EXTRA_DECODE_STAGE),
    .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN),
    .MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
) core_inst (
    .clk_i(clk_50mhz),          
    .rst_i(rst_internal),       
    .intr_i(intr_i),
    .mem_d_data_rd_i(mem_d_data_rd_i),
    .mem_d_accept_i(mem_d_accept_i),
    .mem_d_ack_i(mem_d_ack_i),
    .mem_d_error_i(1'b0),
    .mem_d_resp_tag_i(11'd0),
    .mem_i_accept_i(mem_i_accept_i),
    .mem_i_valid_i(mem_i_valid_i),
    .mem_i_error_i(1'b0),
    .mem_i_inst_i(mem_i_inst_i),
    .mem_d_addr_o(mem_d_addr_o),
    .mem_d_data_wr_o(mem_d_data_wr_o),
    .mem_d_rd_o(mem_d_rd_o),
    .mem_d_wr_o(mem_d_wr_o),
    .mem_d_cacheable_o(mem_d_cacheable_o),
    .mem_d_req_tag_o(mem_d_req_tag_o),
    .mem_d_invalidate_o(mem_d_invalidate_o),
    .mem_d_writeback_o(mem_d_writeback_o),
    .mem_d_flush_o(mem_d_flush_o),
    .mem_i_rd_o(mem_i_rd_o),
    .mem_i_flush_o(mem_i_flush_o),
    .mem_i_invalidate_o(mem_i_invalidate_o),
    .mem_i_pc_o(mem_i_pc_o)
);


riscv_performance_counter perf_counter (
    .clk_i(clk_50mhz),              
    .reset_i(rst_internal),         
    .pc_i(mem_i_pc_o),
    .instruction_i(mem_i_inst_i),
    .instruction_valid_i(mem_i_valid_i),
    .cycle_count_o(cycle_count),
    .counting_active_o(counting_active),
    .measurement_done_o(measurement_done),
    .halt_detected_o(halt_detected)
);


instruction_memory instruction_mem (
    .clk_i(clk_50mhz),          
    .reset_i(rst_internal),     
    .accept(mem_i_accept_i),
    .iaddr_i(mem_i_pc_o),
    .ird_i(mem_i_rd_o),
    .irdata_o(mem_i_inst_i)
);

assign mem_i_valid_i = 1'b1;

memory mem (
    // CPU Port
    .clk_i(clk_50mhz),          
    .reset_i(rst_internal),    
    .accept(mem_d_accept_i),
    .acknowledge(mem_d_ack_i),
    .daddr_i(mem_d_addr_o),
    .dwdata_i(mem_d_data_wr_o),
    .drdata_o(mem_d_data_rd_i),
    .drd_i(mem_d_rd_o),
    .dbe_w(mem_d_wr_o),
    

    .dump_addr(dump_mem_addr),
    .dump_data(dump_mem_data)
);

MemoryUartDumper #(
    .MEM_DUMP_SIZE(256),  
    .ADDR_WIDTH(12)
) mem_dumper (
    .clk(clk_50mhz),          
    .reset(rst_internal),       
    .start_dump(dump_trigger),
    .dump_in_progress(dump_in_progress),
    .mem_addr(dump_mem_addr),
    .mem_rdata(dump_mem_data),
    .tx(tx_o),
    .bytes_sent_debug(bytes_sent_debug)
);

endmodule