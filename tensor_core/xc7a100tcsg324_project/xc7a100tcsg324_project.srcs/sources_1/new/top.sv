
module top(
    input sys_clk,
    input sys_rst
    );
    
localparam SYSTOL_ACTIVATION_COUNT = 256;
localparam SYSTOL_WEIGHT_COUNT = 256;
localparam ACTIVATION_QUEUE_DEPTH = 256;
localparam WEIGHT_QUEUE_DEPTH = 256;
localparam OFFSET_QUEUE_DEPTH = 256;

logic cu_rst_busy;
logic cu_weight_update_busy;

logic cu_weight_update;

data_type cu_activation [0:SYSTOL_ACTIVATION_COUNT - 1];
logic cu_activation_wr_en;
logic cu_activation_full;

data_type cu_weight [0:SYSTOL_WEIGHT_COUNT - 1];
logic cu_weight_wr_en;
logic cu_weight_full;

logic [2:SYSTOL_WEIGHT_COUNT - 1] cu_accum_adder_chain_set;
logic [1:SYSTOL_WEIGHT_COUNT - 1] cu_accum_out_data_mux;

data_type cu_offset [0:SYSTOL_WEIGHT_COUNT - 1];
logic cu_offset_wr_en;
logic cu_offset_full;

data_type cu_result [0:SYSTOL_WEIGHT_COUNT - 1];


computing_unit #(
    .SYSTOL_ACTIVATION_COUNT(SYSTOL_ACTIVATION_COUNT)
    , .ACTIVATION_QUEUE_DEPTH(ACTIVATION_QUEUE_DEPTH)
    , .SYSTOL_WEIGHT_COUNT(SYSTOL_WEIGHT_COUNT)
    , .WEIGHT_QUEUE_DEPTH(WEIGHT_QUEUE_DEPTH)
    , .OFFSET_QUEUE_DEPTH(OFFSET_QUEUE_DEPTH)
    )
cu (
    .clk_i(sys_clk)
    , .rst_i(sys_rst)
    , .rst_busy(cu_rst_busy)
    , .weight_update_busy(cu_weight_update_busy)

    //systolic array control
    , .weight_update_i(cu_weight_update)
    , .activation_i(cu_activation)
    , .activation_wr_en_i(cu_activation_wr_en)
    , .activation_full_o(cu_activation_full)
    , .weight_i(cu_weight)
    , .weight_wr_en_i(cu_weight_wr_en)
    , .weight_full_o(cu_weight_full)

    //accumulators control
    , .accum_adder_chain_set_i(cu_accum_adder_chain_set)
    , .accum_out_data_mux_i(cu_accum_out_data_mux)

    //offsets control
    , .offset_i(cu_offset)
    , .offset_wr_en_i(cu_offset_wr_en)
    , .offset_full_o(cu_offset_full)

    , .result_o(cu_result)
);
integer weight_column_num, activation_column_num; 

always @(posedge sys_clk) begin
    if(sys_rst) begin
        cu_weight_update <= 0;
        weight_column_num <= 0;
        activation_column_num <= 0;
        cu_accum_adder_chain_set <= 14'b10_0100_1001_0010; 
        cu_accum_out_data_mux <= 15'b010_0100_1001_0010;
    end else begin
        if(cu_weight_full == 0) begin
            if(weight_column_num == 0) begin
                cu_weight_update <= 1;
            end
            else begin
                cu_weight_update <= 0;
            end

            cu_weight_wr_en = 1;
            for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
                cu_weight[i] = weight_column_num;
            end
            weight_column_num = weight_column_num + 1;
        end else begin
            cu_weight_wr_en = 0;
        end
        
        if(cu_activation_full == 0) begin

            cu_activation_wr_en = 1;
            for(integer i=0; i<SYSTOL_ACTIVATION_COUNT;i++)	begin
                cu_activation[i] = activation_column_num;
            end
            activation_column_num = activation_column_num + 1;
        end else begin
            cu_activation_wr_en = 0;
        end
        
        if(cu_offset_full == 0) begin

            cu_offset_wr_en = 1;
            for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
                cu_offset[i] = activation_column_num;
            end
            activation_column_num = activation_column_num + 1;
        end else begin
            cu_offset_wr_en = 0;
        end
    end
end
endmodule
