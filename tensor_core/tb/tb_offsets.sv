`timescale 1ps / 1ps

`ifndef VIVADO_PRJ_USE
    `include "types.vh"
`endif

import types::*;

`define SYSTEM_CLK_HALF_PERIOD 5000

module tb_offsets;

localparam OFFSET_SIZE = 16;

logic offset_clk;
logic offset_rst;

data_type offset_in_data [0:OFFSET_SIZE-1];
data_type offset_offset_data [0:OFFSET_SIZE-1];
data_type offset_out_data [0:OFFSET_SIZE-1];

offsets #(
    .IN_SIZE(OFFSET_SIZE))
dut (
    .clk_i(offset_clk)
    , .rst_i(offset_rst)
   
    , .data_i(offset_in_data)
    , .offset_i(offset_offset_data)
    , .data_o(offset_out_data)
);

//reset generation
initial begin
    offset_clk = 0;
    offset_rst = 1;

    #(`SYSTEM_CLK_HALF_PERIOD * 10);
    offset_rst = 0;
end

always #(`SYSTEM_CLK_HALF_PERIOD) offset_clk = ~offset_clk;

data_type offset_res [0:OFFSET_SIZE-1];

//data generation
initial begin
    for(integer i=0; i<OFFSET_SIZE; i++) begin
        offset_in_data[i] = 0;
        offset_offset_data[i] = 0;
    end
    
    @(negedge offset_rst);
    
    @(posedge offset_clk);
    #1;
    for(integer i=0; i<OFFSET_SIZE; i++) begin
        offset_in_data[i] = $random;
        offset_offset_data[i] = $random;
        
        offset_res[i] = offset_in_data[i] + offset_offset_data[i];
    end
    
    @(posedge offset_clk);
    #1;
    
    for(integer i=0; i<OFFSET_SIZE; i++) begin
        if(offset_out_data[i] == offset_res[i]) begin
            $display("TRUE  | Offset_res[%0d] = %0d | Offset_res_gold[%0d] = %0d", i, offset_out_data[i], i, offset_res[i]);
        end
        else begin
            $display("FALSE | Offset_res[%0d] = %0d | Offset_res_gold[%0d] = %0d", i, offset_out_data[i], i, offset_res[i]);
        end
    end
    
    @(posedge offset_clk);
    $finish;
end

endmodule
