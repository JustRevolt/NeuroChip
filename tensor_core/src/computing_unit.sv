`ifndef VIVADO_PRJ_USE
`include "types.vh"
`endif

import types::*;

module computing_unit#(  
        parameter SYSTOL_ACTIVATION_COUNT = 16
        , parameter ACTIVATION_QUEUE_DEPTH = 16
		, parameter SYSTOL_WEIGHT_COUNT = 16
		, parameter WEIGHT_QUEUE_DEPTH = 16
        , parameter OFFSET_QUEUE_DEPTH = 16)
	(
		input clk_i
		, input rst_i
        , output rst_busy
        , output weight_update_busy

        //systolic array control
		, input weight_update_i

		, input data_type activation_i [0:SYSTOL_ACTIVATION_COUNT-1]
        , input activation_wr_en_i
        , output activation_full_o

		, input data_type weight_i [0:SYSTOL_WEIGHT_COUNT-1]
        , input weight_wr_en_i
        , output weight_full_o

        //accumulators control
        , input [2:SYSTOL_WEIGHT_COUNT-1] accum_adder_chain_set_i
        , input [1:SYSTOL_WEIGHT_COUNT-1] accum_out_data_mux_i

        //offsets control
        , input data_type offset_i [0:SYSTOL_WEIGHT_COUNT-1]
        , input offset_wr_en_i
        , output offset_full_o

		, output data_type result_o [0:SYSTOL_WEIGHT_COUNT-1]
	);

//activation_fifo signals
data_type activation_fifo_din [0:SYSTOL_ACTIVATION_COUNT-1];
logic activation_fifo_wr_en;
logic activation_fifo_rd_en;
data_type activation_fifo_dout [0:SYSTOL_ACTIVATION_COUNT-1];
logic [0:SYSTOL_ACTIVATION_COUNT-1] activation_fifo_full;
logic [0:SYSTOL_ACTIVATION_COUNT-1] activation_fifo_empty;
logic [0:SYSTOL_ACTIVATION_COUNT-1] activation_fifo_busy;

assign activation_fifo_wr_en = activation_wr_en_i;
assign activation_fifo_din = activation_i;
assign activation_full_o = |activation_fifo_full;

//weight_fifo signals
data_type weight_fifo_din [0:SYSTOL_WEIGHT_COUNT-1];
logic weight_fifo_wr_en;
logic weight_fifo_rd_en;
data_type weight_fifo_dout [0:SYSTOL_WEIGHT_COUNT-1];
logic [0:SYSTOL_WEIGHT_COUNT-1] weight_fifo_full;
logic [0:SYSTOL_WEIGHT_COUNT-1] weight_fifo_empty;
logic [0:SYSTOL_WEIGHT_COUNT-1] weight_fifo_busy;

assign weight_fifo_wr_en = weight_wr_en_i;
assign weight_fifo_din = weight_i;
assign weight_full_o = |weight_fifo_full;

//offset_fifo signals
data_type offset_fifo_din [0:SYSTOL_WEIGHT_COUNT-1];
logic offset_fifo_wr_en;
logic offset_fifo_rd_en;
data_type offset_fifo_dout [0:SYSTOL_WEIGHT_COUNT-1];
logic [0:SYSTOL_WEIGHT_COUNT-1] offset_fifo_full;
logic [0:SYSTOL_WEIGHT_COUNT-1] offset_fifo_empty;
logic [0:SYSTOL_WEIGHT_COUNT-1] offset_fifo_busy;

assign offset_fifo_wr_en = offset_wr_en_i;
assign offset_fifo_din = offset_i;
assign offset_full_o = |offset_fifo_full;

//systolic_array signals
data_type systol_arr_dout [0:SYSTOL_WEIGHT_COUNT-1];
logic systol_arr_weight_update;

data_type accum_dout [0:SYSTOL_WEIGHT_COUNT-1];

data_type offsets_dout [0:SYSTOL_WEIGHT_COUNT-1];

data_type activation_dout [0:SYSTOL_WEIGHT_COUNT-1];

//weight_fifo_control signals
logic [$clog2(SYSTOL_ACTIVATION_COUNT):0] weight_update_ctr;

assign rst_busy = (|activation_fifo_busy) | (|weight_fifo_busy) | (|offset_fifo_busy);
assign weight_update_busy = systol_arr_weight_update;

assign result_o = activation_dout;

genvar i, j, k;
generate
    for(i=0; i<SYSTOL_ACTIVATION_COUNT; i++) begin
        
        xilinx_fifo_wrapper #(  
            .FIFO_DEPTH(ACTIVATION_QUEUE_DEPTH)
            , .DATA_WIDTH(`DATA_TYPE_SIZE))
        activation_fifo (
            .clk_i(clk_i)
            , .rst_i(rst_i)
            , .rst_busy_o(activation_fifo_busy[i])
            , .wr_en_i(activation_fifo_wr_en)
            , .din_i(activation_fifo_din[i])
            , .rd_en_i(activation_fifo_rd_en)
            , .dout_o(activation_fifo_dout[i])
            , .full_o(activation_fifo_full[i])
            , .empty_o(activation_fifo_empty[i])
        );
    end
    
    for(j=0; j<SYSTOL_WEIGHT_COUNT; j++) begin
        
        xilinx_fifo_wrapper #(  
            .FIFO_DEPTH(WEIGHT_QUEUE_DEPTH)
            , .DATA_WIDTH(`DATA_TYPE_SIZE))
        weight_fifo (
            .clk_i(clk_i)
            , .rst_i(rst_i)
            , .rst_busy_o(weight_fifo_busy[j])
            , .wr_en_i(weight_fifo_wr_en)
            , .din_i(weight_fifo_din[j])
            , .rd_en_i(weight_fifo_rd_en)
            , .dout_o(weight_fifo_dout[j])
            , .full_o(weight_fifo_full[j])
            , .empty_o(weight_fifo_empty[j])
        );
    end

    for(k = 0; k < SYSTOL_WEIGHT_COUNT; k++) begin
        
        xilinx_fifo_wrapper #(  
            .FIFO_DEPTH(OFFSET_QUEUE_DEPTH)
            , .DATA_WIDTH(`DATA_TYPE_SIZE))
        offset_fifo (
            .clk_i(clk_i)
            , .rst_i(rst_i)
            , .rst_busy_o(offset_fifo_busy[k])
            , .wr_en_i(offset_fifo_wr_en)
            , .din_i(offset_fifo_din[k])
            , .rd_en_i(offset_fifo_rd_en)
            , .dout_o(offset_fifo_dout[k])
            , .full_o(offset_fifo_full[k])
            , .empty_o(offset_fifo_empty[k])
        );
    end
endgenerate
    
systolic_array
#(  .ACTIVATION_COUNT(SYSTOL_ACTIVATION_COUNT)
    , .WEIGHT_COUNT(SYSTOL_WEIGHT_COUNT)) 
systol_arr(
        .clk_i(clk_i)
        , .rst_i(rst_i)
        , .weight_update_i(systol_arr_weight_update)
        , .activation_i(activation_fifo_dout)
        , .weight_i(weight_fifo_dout)
        , .result_o(systol_arr_dout)
    );

accumulators
    #(.IN_SIZE(SYSTOL_WEIGHT_COUNT))
accum (
        .clk_i(clk_i)
        , .rst_i(rst_i)
        , .data_i(systol_arr_dout)
        , .adder_chain_set_i(accum_adder_chain_set_i)
        , .out_data_mux_i(accum_out_data_mux_i)
        , .data_o(accum_dout)
    );

offsets
    #(.IN_SIZE(SYSTOL_WEIGHT_COUNT))
offsets (
    .clk_i(clk_i)
    , .rst_i(rst_i)
    
    , .data_i(accum_dout)
    , .offset_i(offset_fifo_dout)
    
    , .data_o(offsets_dout) 
);

activation
    #(.IN_SIZE(SYSTOL_WEIGHT_COUNT))
activation (
        .clk_i(clk_i)
        , .rst_i(rst_i)
       
        , .data_i(offsets_dout)
        , .data_o(activation_dout)
    );

always_ff @(posedge clk_i) begin : activation_fifo_control
    if(rst_i) begin
        activation_fifo_rd_en <= 0;
    end
    else begin
        //Default
        activation_fifo_rd_en <= 0;

        if(activation_fifo_busy == 0) begin
            if(activation_fifo_empty == 0) begin
                if(weight_update_ctr == (SYSTOL_ACTIVATION_COUNT)) begin
                    activation_fifo_rd_en <= 1;
                end
            end
        end
    end
end

always_ff @(posedge clk_i) begin : weight_fifo_control
    if(rst_i) begin
        weight_fifo_rd_en <= 0;
        systol_arr_weight_update <= 0;
        weight_update_ctr <= SYSTOL_ACTIVATION_COUNT;
    end
    else begin
        //Default
        weight_fifo_rd_en <= 0;
        systol_arr_weight_update <= 0;

        if(weight_fifo_busy == 0) begin
            if(weight_update_ctr == (SYSTOL_ACTIVATION_COUNT)) begin
                if(weight_update_i == 1) begin
                    weight_update_ctr <= 0;
                end
            end
            else begin
                if(weight_fifo_empty == 0) begin
                    weight_fifo_rd_en <= 1;
                    systol_arr_weight_update <= 1;
                    weight_update_ctr <= weight_update_ctr + 1;
                end
            end
        end
    end
end

always_ff @(posedge clk_i) begin : offset_fifo_control
    if(rst_i) begin
        offset_fifo_rd_en <= 0;
    end
    else begin
        //Default
        offset_fifo_rd_en <= 0;

        if(offset_fifo_busy == 0) begin
            if(offset_fifo_empty == 0) begin
                if(weight_update_ctr == (SYSTOL_ACTIVATION_COUNT)) begin
                    offset_fifo_rd_en <= 1;
                end
            end
        end
    end
end

endmodule
