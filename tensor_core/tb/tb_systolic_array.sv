`timescale 1ps / 1ps

`ifndef VIVADO_PRJ_USE
`include "types.vh"
`endif

import types::*;

`define SYSTEM_CLK_HALF_PERIOD 5000

module tb_systolic_array;

localparam SYSTOL_ACTIVATION_COUNT = 16;
localparam SYSTOL_WEIGHT_COUNT = 16;

logic systol_arr_clk;
logic systol_arr_rst;
logic systol_arr_weight_update;
data_type systol_arr_activation [0:SYSTOL_ACTIVATION_COUNT - 1];
data_type systol_arr_weight [0:SYSTOL_WEIGHT_COUNT - 1];
data_type systol_arr_result [0:SYSTOL_WEIGHT_COUNT - 1];

systolic_array
#(  .ACTIVATION_COUNT(SYSTOL_ACTIVATION_COUNT)
    , .WEIGHT_COUNT(SYSTOL_WEIGHT_COUNT))
systol_arr(
        .clk_i(systol_arr_clk)
        , .rst_i(systol_arr_rst)
        , .weight_update_i(systol_arr_weight_update)
        , .activation_i(systol_arr_activation)
        , .weight_i(systol_arr_weight)
        , .result_o(systol_arr_result)
    );

//reset generation
initial begin
    systol_arr_clk = 0;
    systol_arr_rst = 1;

    #(`SYSTEM_CLK_HALF_PERIOD * 10);
    systol_arr_rst = 0;
end

always #(`SYSTEM_CLK_HALF_PERIOD) systol_arr_clk = ~systol_arr_clk;

integer weight_column_num;
integer proc_ctr;

//multiplication test for matrices with sizes equal to a systolic array
data_type weight_matrix_1 [0:SYSTOL_WEIGHT_COUNT - 1][0:SYSTOL_ACTIVATION_COUNT - 1];
data_type activation_matrix_1 [0:SYSTOL_ACTIVATION_COUNT - 1][0:SYSTOL_WEIGHT_COUNT - 1];

data_type result_matrix_1 [0:SYSTOL_WEIGHT_COUNT-1][0:SYSTOL_WEIGHT_COUNT-1];

task matrix_mul_test_1();
    begin
        weight_column_num = 0;
        proc_ctr = 0;

        for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++) begin
            for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++) begin
                result_matrix_1[i][j] = 0;
            end
        end
        
        @(posedge systol_arr_clk);
        #1;
        
        for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
            for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
                for(integer k=0; k<SYSTOL_ACTIVATION_COUNT;k++)	begin
                    result_matrix_1[i][j] = result_matrix_1[i][j] + weight_matrix_1[i][k]*activation_matrix_1[k][j];
                end
            end
        end
        
        while (weight_column_num < SYSTOL_ACTIVATION_COUNT) begin
            @(posedge systol_arr_clk);
            #1;
            
            systol_arr_weight_update = 1;
            for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
                systol_arr_weight[i] = weight_matrix_1[i][SYSTOL_ACTIVATION_COUNT-weight_column_num-1];
            end
            
            weight_column_num = weight_column_num + 1;
        end
        
        while (proc_ctr <= (SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT)) begin
            @(posedge systol_arr_clk);
            #1;

            systol_arr_weight_update = 0;

            //activation sending
            for(integer i=0; i<SYSTOL_ACTIVATION_COUNT;i++) begin
                systol_arr_activation[i] = 0;
            end
            
            for(integer i=0; i<proc_ctr+1;i++) begin
                if(proc_ctr-i < SYSTOL_ACTIVATION_COUNT) begin
                    systol_arr_activation[i] = activation_matrix_1[i][proc_ctr-i];
                end
            end
            
            //results check
            if((proc_ctr > SYSTOL_ACTIVATION_COUNT)) begin
                for(integer z = 0; z < (proc_ctr - SYSTOL_ACTIVATION_COUNT); z++) begin
                    if((z < SYSTOL_WEIGHT_COUNT) && ((proc_ctr - SYSTOL_ACTIVATION_COUNT - 1 - z) < SYSTOL_WEIGHT_COUNT)) begin
                        if(systol_arr_result[z] == result_matrix_1[z][proc_ctr - SYSTOL_ACTIVATION_COUNT - 1 - z]) begin
                            $display("TRUE  | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", z, proc_ctr-SYSTOL_ACTIVATION_COUNT-1-z, systol_arr_result[z], z, proc_ctr-SYSTOL_ACTIVATION_COUNT-1-z, result_matrix_1[z][proc_ctr-SYSTOL_ACTIVATION_COUNT-1-z]);
                        end
                        else begin
                            $display("FALSE | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", z, proc_ctr-SYSTOL_ACTIVATION_COUNT-1-z, systol_arr_result[z], z, proc_ctr-SYSTOL_ACTIVATION_COUNT-1-z, result_matrix_1[z][proc_ctr-SYSTOL_ACTIVATION_COUNT-1-z]);
                        end
                    end
                end
            end
            
            proc_ctr = proc_ctr + 1;
        end
    end
endtask


//multiplication test for matrices with sizes bigger than systolic array size
localparam WEIGHT_MATRIX_SIZE_X = 16;
localparam WEIGHT_MATRIX_SIZE_Y = 16;

localparam ACTIVATION_MATRIX_SIZE_X = 16;
localparam ACTIVATION_MATRIX_SIZE_Y = WEIGHT_MATRIX_SIZE_X;

data_type weight_matrix_2 [0:WEIGHT_MATRIX_SIZE_Y - 1][0:WEIGHT_MATRIX_SIZE_X - 1];
data_type activation_matrix_2 [0:ACTIVATION_MATRIX_SIZE_Y - 1][0:ACTIVATION_MATRIX_SIZE_X - 1];

data_type result_matrix_2 [0:WEIGHT_MATRIX_SIZE_Y-1][0:ACTIVATION_MATRIX_SIZE_X-1];

task matrix_mul_test_2();
    begin
        weight_column_num = 0;
        proc_ctr = 0;

    end
endtask



initial begin

    systol_arr_weight_update = 0;
    for(integer i=0; i<SYSTOL_ACTIVATION_COUNT;i++)	begin
        systol_arr_activation[i] = 0;
    end
    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        systol_arr_weight[i] = 0;
    end
    
    @(negedge systol_arr_rst);
    
    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        for(integer j=0; j<SYSTOL_ACTIVATION_COUNT;j++)	begin
            weight_matrix_1[i][j] = $random % 32'h2000;
            activation_matrix_1[j][i] = $random % 32'h2000;
        end
    end
    
    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        for(integer j=0; j<SYSTOL_ACTIVATION_COUNT;j++)	begin
            $display("weight[%0d][%0d] = %0d", i, j, weight_matrix_1[i][j]);
        end
    end
    
    for(integer i=0; i<SYSTOL_ACTIVATION_COUNT;i++)	begin
        for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
            $display("activation[%0d][%0d] = %0d", i, j, activation_matrix_1[i][j]);
        end
    end
    
    matrix_mul_test_1();
    
    $finish;
    
end

endmodule
