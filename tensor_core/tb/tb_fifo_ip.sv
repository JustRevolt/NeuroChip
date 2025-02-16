`timescale 1ns / 1ps

`ifndef VIVADO_PRJ_USE
    `include "types.vh"
`endif
import types::*;

`define DATA_TYPE_SIZE 32

`define SYSTEM_CLK_HALF_PERIOD 5000

module tb_fifo_ip;

typedef logic signed [`DATA_TYPE_SIZE-1:0] data_type;

localparam SYSTOL_ACTIVATION_COUNT = 16;
localparam ACTIVATION_QUEUE_DEPTH = 16;
localparam SYSTOL_WEIGHT_COUNT = 16;
localparam WEIGHT_QUEUE_DEPTH = 16;

logic fifo_clk;
logic fifo_rst;

data_type activation_fifo_din;
logic activation_fifo_wr_en;
logic activation_fifo_rd_en;
data_type activation_fifo_dout;
logic activation_fifo_full;
logic activation_fifo_empty;

logic [$clog2(ACTIVATION_QUEUE_DEPTH):0] activation_fifo_rd_data_count;
logic [$clog2(ACTIVATION_QUEUE_DEPTH):0] activation_fifo_wr_data_count;

xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("block"), // String: "auto", "block", "distributed", "ultra"
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(ACTIVATION_QUEUE_DEPTH),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH($clog2(ACTIVATION_QUEUE_DEPTH)+1),   // DECIMAL
    .READ_DATA_WIDTH(`DATA_TYPE_SIZE),      // DECIMAL
    .READ_MODE("std"),         // String: "std", "fwft"
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("0404"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(`DATA_TYPE_SIZE),     // DECIMAL
    .WR_DATA_COUNT_WIDTH($clog2(ACTIVATION_QUEUE_DEPTH)+1)    // DECIMAL
)
xpm_fifo_sync_inst (
    .almost_empty(),    // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                    // only one more read can be performed before the FIFO goes to empty.
    .almost_full(),  // 1-bit output: Almost Full: When asserted, this signal indicates that
                                // only one more write can be performed before the FIFO is full.
    .data_valid(),    // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                // that valid data is available on the output bus (dout).
    .dbiterr(),  // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                        // a double-bit error and data in the FIFO core is corrupted.
    .dout(activation_fifo_dout),    // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                    // when reading the FIFO.
    .empty(activation_fifo_empty),  // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                    // FIFO is empty. Read requests are ignored when the FIFO is empty,
                    // initiating a read while empty is not destructive to the FIFO.
    .full(activation_fifo_full),    // 1-bit output: Full Flag: When asserted, this signal indicates that the
                    // FIFO is full. Write requests are ignored when the FIFO is full,
                    // initiating a write when the FIFO is full is not destructive to the
                    // contents of the FIFO.
    .overflow(),    // 1-bit output: Overflow: This signal indicates that a write request
                            // (wren) during the prior clock cycle was rejected, because the FIFO is
                            // full. Overflowing the FIFO is not destructive to the contents of the
                            // FIFO.
    .prog_empty(),    // 1-bit output: Programmable Empty: This signal is asserted when the
                                // number of words in the FIFO is less than or equal to the programmable
                                // empty threshold value. It is de-asserted when the number of words in
                                // the FIFO exceeds the programmable empty threshold value.
    .prog_full(),  // 1-bit output: Programmable Full: This signal is asserted when the
                            // number of words in the FIFO is greater than or equal to the
                            // programmable full threshold value. It is de-asserted when the number of
                            // words in the FIFO is less than the programmable full threshold value.
    .rd_data_count(activation_fifo_rd_data_count),  // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                    // number of words read from the FIFO.
    .rd_rst_busy(),  // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                // domain is currently in a reset state.
    .sbiterr(),  // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                        // and fixed a single-bit error.
    .underflow(),  // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                            // the previous clock cycle was rejected because the FIFO is empty. Under
                            // flowing the FIFO is not destructive to the FIFO.
    .wr_ack(),    // 1-bit output: Write Acknowledge: This signal indicates that a write
                        // request (wr_en) during the prior clock cycle is succeeded.
    .wr_data_count(activation_fifo_wr_data_count),  // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                    // the number of words written into the FIFO.
    .wr_rst_busy(),  // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                // write domain is currently in a reset state.
    .din(activation_fifo_din),  // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                // writing the FIFO.
    .injectdbiterr(),  // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                    // the ECC feature is used on block RAMs or UltraRAM macros.
    .injectsbiterr(),  // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                    // the ECC feature is used on block RAMs or UltraRAM macros.
    .rd_en(activation_fifo_rd_en),  // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                    // signal causes data (on dout) to be read from the FIFO. Must be held
                    // active-low when rd_rst_busy is active high.
    .rst(fifo_rst),  // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                // unstable at the time of applying reset, but reset must be released only
                // after the clock(s) is/are stable.
    .sleep(),  // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                    // block is in power saving mode.
    .wr_clk(fifo_clk),    // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                        // free running clock.
    .wr_en(activation_fifo_wr_en)   // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                    // signal causes data (on din) to be written to the FIFO Must be held
                    // active-low when rst or wr_rst_busy or rd_rst_busy is active high
);


//reset generation
initial begin
    fifo_clk = 0;   
    fifo_rst = 1;

    #(`SYSTEM_CLK_HALF_PERIOD*30);
    fifo_rst = 0;
end

always #(`SYSTEM_CLK_HALF_PERIOD) fifo_clk = ~fifo_clk;

//data generation
initial begin
    activation_fifo_din = 0;
    activation_fifo_wr_en = 0;
    activation_fifo_rd_en = 0;
    
    @(negedge fifo_rst);
    
    //WR/RD busy after reset during the 4 clock cycles
    @(posedge fifo_clk);
    @(posedge fifo_clk);
    @(posedge fifo_clk);
    
    while(!activation_fifo_full) begin
         @(posedge fifo_clk);
         #1;
         
         activation_fifo_din = activation_fifo_din + 1;
         activation_fifo_wr_en = 1;
    end
    
    @(posedge fifo_clk);
    #1;
    
    activation_fifo_wr_en = 0;
    
    while(!activation_fifo_empty) begin
         @(posedge fifo_clk);
         #1;
         
         activation_fifo_rd_en = 1;
    end
    
    @(posedge fifo_clk);
    #1;
    
    activation_fifo_rd_en = 0;
    
    @(posedge fifo_clk);
    #1;
    $finish; 
end

endmodule
