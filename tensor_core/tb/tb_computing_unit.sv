`timescale 1ps / 1ps

`ifndef VIVADO_PRJ_USE
`include "src/types.vh"
`endif

`define LOG_FILE "E:/YandexDisk/Computer/University_projects/Neuroprocessor/NeuroProc_prototype/tb/log/tb_computing_unit.log"
`define WAVE_FILE "E:/YandexDisk/Computer/University_projects/Neuroprocessor/NeuroProc_prototype/tb/log/tb_computing_unit.vcd"

import types::*;

`define SYSTEM_CLK_HALF_PERIOD 5000
`define SYSTEM_CLK_FREQ_MHZ (1000000 / (2 * `SYSTEM_CLK_HALF_PERIOD))

module tb_computing_unit;

localparam SYSTOL_ACTIVATION_COUNT = 256;
localparam SYSTOL_WEIGHT_COUNT = 256;
localparam ACTIVATION_QUEUE_DEPTH = 256;
localparam WEIGHT_QUEUE_DEPTH = 256;
localparam OFFSET_QUEUE_DEPTH = 256;

logic sys_clk;
logic sys_rst;

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

//init reset generation
initial begin
    sys_clk = 0;
    sys_rst = 1;

    #(`SYSTEM_CLK_HALF_PERIOD * 10);
    sys_rst = 0;
end

always #(`SYSTEM_CLK_HALF_PERIOD) sys_clk = ~sys_clk;

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

integer assert_count;
integer error_assert_count;

integer weight_column_num; 
integer weight_row_num;
integer activation_row_num, offset_row_num;
integer col, row;

integer proc_ctr;
integer tmp_proc_count;
integer monitor_tmp_proc_count;
reg systol_arr_res_check_done, 
    accum_res_check_done,
    offset_res_check_done,
    activ_res_check_done;
integer iteration_count;

time start_time, end_time;

// Task: matrix_mul_test_1
// Description:
// 1) multiplication test for matrices with sizes equal to a systolic array
// 2) sending weights and activations to the computing unit one after the other
//    simulation of the common bus for weights and activations
data_type weight_matrix_1 [0:SYSTOL_WEIGHT_COUNT - 1]
                            [0:SYSTOL_ACTIVATION_COUNT - 1];
                            
data_type activation_matrix_1 [0:SYSTOL_ACTIVATION_COUNT - 1]
                                [0:SYSTOL_WEIGHT_COUNT - 1];

data_type offset_matrix_1 [0:SYSTOL_WEIGHT_COUNT - 1]
                                [0:SYSTOL_WEIGHT_COUNT - 1];

data_type mul_result_matrix_1 [0:SYSTOL_WEIGHT_COUNT-1][0:SYSTOL_WEIGHT_COUNT-1];
data_type offset_result_matrix_1 [0:SYSTOL_WEIGHT_COUNT-1][0:SYSTOL_WEIGHT_COUNT-1];
data_type cu_result_matrix_1 [0:SYSTOL_WEIGHT_COUNT-1][0:SYSTOL_WEIGHT_COUNT-1];

task matrix_mul_test_1();
    begin
        $display("");
        $display("--------matrix_mul_test_1 START---------");
        $display("========================================");

        `ifdef LOG_FILE
        $fdisplay(log_fd, "");
        $fdisplay(log_fd, "--------matrix_mul_test_1 START---------");
        $fdisplay(log_fd, "========================================");
        `endif
     
        
        cu_accum_adder_chain_set = 14'b00_0000_0000_0000;
        cu_accum_out_data_mux = 15'b000_0000_0000_0000;

        assert_count = 0;
        error_assert_count = 0;
        weight_column_num = 0;
        activation_row_num = 0;
        offset_row_num = 0;
        proc_ctr = 0;

        for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++) begin
            for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++) begin
                mul_result_matrix_1[i][j] = 0;
            end
        end
        
        @(posedge sys_clk);
        #1;
        
        for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin : mul_array_gold_res_calc
            for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
                for(integer k=0; k<SYSTOL_ACTIVATION_COUNT;k++)	begin
                    mul_result_matrix_1[i][j] = mul_result_matrix_1[i][j] + 
                                            weight_matrix_1[i][k] * 
                                            activation_matrix_1[k][j];
                end
            end
        end

        for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin : offset_gold_res_calc
            for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
                offset_result_matrix_1[i][j] = mul_result_matrix_1[i][j] + 
                                                offset_matrix_1[i][j];
            end
        end
        
        for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin : CU_gold_res_calc
            for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
                cu_result_matrix_1[i][j] = (offset_result_matrix_1[i][j] < 0) ? 
                                                0 : offset_result_matrix_1[i][j];
            end
        end
        
        //weight sending
        while (weight_column_num < SYSTOL_ACTIVATION_COUNT) begin : weight_sending
            @(posedge sys_clk);
            #1;

            if(cu_weight_full == 0) begin
                if(weight_column_num == 0) begin
                    cu_weight_update = 1;

                    start_time = $time;
                end
                else begin
                    cu_weight_update = 0;
                end

                cu_weight_wr_en = 1;
                for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
                    cu_weight[i] = weight_matrix_1[i][SYSTOL_ACTIVATION_COUNT - weight_column_num - 1];
                end
                weight_column_num = weight_column_num + 1;
            end
            else begin
                cu_weight_wr_en = 0;
            end
        end

        while (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT) + 10)) begin
            @(posedge sys_clk);
            #1;
            
            begin : activation_sending
            cu_weight_update = 0;
            cu_weight_wr_en = 0;

            //activation sending
            if(activation_row_num < (SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT)) begin
                if(cu_activation_full == 0) begin
                    cu_activation_wr_en = 1;
                    for(integer i = 0; i < SYSTOL_ACTIVATION_COUNT; i++) begin
                        cu_activation[i] = 0;
                    end

                    for(integer i = 0; i < activation_row_num + 1; i++) begin
                        if((activation_row_num - i) < SYSTOL_ACTIVATION_COUNT) begin
                            cu_activation[i] = activation_matrix_1[i][activation_row_num - i];
                        end
                    end

                    activation_row_num = activation_row_num + 1;
                end
                else begin
                    cu_activation_wr_en = 0;
                end
            end
            else begin
                cu_activation_wr_en = 0;
            end
            end

            //offsets sending
            //start 4 clock cycle before getting results from accum block
            if (
                (proc_ctr > (SYSTOL_ACTIVATION_COUNT + 5 - 4)) && 
                (offset_row_num < (2 * SYSTOL_WEIGHT_COUNT))
            ) begin : offsets_sending

                if(cu_offset_full == 0) begin
                    cu_offset_wr_en = 1;
                    for(integer i = 0; i < SYSTOL_WEIGHT_COUNT; i++) begin
                        cu_offset[i] = 0;
                    end

                    for(integer i = 0; i < offset_row_num + 1; i++) begin
                        if((offset_row_num - i) < SYSTOL_WEIGHT_COUNT) begin
                            cu_offset[i] = offset_matrix_1[i][offset_row_num - i];
                        end
                    end

                    offset_row_num = offset_row_num + 1;
                end
                else begin
                    cu_offset_wr_en = 0;
                end
            end
            else begin
                cu_offset_wr_en = 0;
            end

            //systol_array results check
            //4 clock cycle delay between sending data to cu and storing data in systolic array
            if ( 
                (proc_ctr > (SYSTOL_ACTIVATION_COUNT + 4)) &&
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT) + 4))
            ) begin : systol_array_results_check

                for(integer z=0; z < (proc_ctr - (SYSTOL_ACTIVATION_COUNT + 4)); z++) begin
                    col = proc_ctr - (SYSTOL_ACTIVATION_COUNT + 4) - 1 - z;
                    row = z;
                    if((row < SYSTOL_WEIGHT_COUNT) && (col < SYSTOL_WEIGHT_COUNT)) begin
                        assert_count = assert_count + 1;
                        if(cu.systol_arr_dout[row] == mul_result_matrix_1[row][col]) begin
                            $display("TRUE  | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_1[row][col]);
                                
                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_1[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_1[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_1[row][col]);
                            `endif
                        end
                    end
                end
            end

            //accum results check
            //5 clock cycle delay between sending data to cu and getting data from accumulators
            //if cu_accum_adder_chain_set == 14'b00_0000_0000_0000;
            //   cu_accum_out_data_mux == 15'b000_0000_0000_0000;
            if (
                (proc_ctr > (SYSTOL_ACTIVATION_COUNT + 5)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT) + 5))
            ) begin : accum_results_check

                for(integer z = 0; z < (proc_ctr - (SYSTOL_ACTIVATION_COUNT + 5)); z++) begin
                    col = proc_ctr - (SYSTOL_ACTIVATION_COUNT + 5) - 1 - z;
                    row = z;
                    if((row < SYSTOL_WEIGHT_COUNT) && (col < SYSTOL_WEIGHT_COUNT)) begin
                        assert_count = assert_count + 1;
                        if(cu.accum_dout[row] == mul_result_matrix_1[row][col]) begin
                            $display("TRUE  | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_1[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_1[row][col]);                            
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_1[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_1[row][col]);
                            `endif
                        end
                    end
                end             
            end

            //offset results check
            //6 clock cycle delay between sending data to cu and getting data from offsets
            if (
                (proc_ctr > (SYSTOL_ACTIVATION_COUNT + 6)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT) + 6))
            ) begin : offset_results_check

                for(integer z=0; z < (proc_ctr - (SYSTOL_ACTIVATION_COUNT + 6)); z++) begin
                    col = proc_ctr - (SYSTOL_ACTIVATION_COUNT + 6) - 1 - z;
                    row = z;
                    if((row < SYSTOL_WEIGHT_COUNT) && (col < SYSTOL_WEIGHT_COUNT)) begin
                        assert_count = assert_count + 1;
                        if(cu.offsets_dout[row] == offset_result_matrix_1[row][col]) begin
                            $display("TRUE  | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_1[row][col]);
                            
                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_1[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_1[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_1[row][col]);
                            `endif
                        end
                    end
                end             
            end

            //cu results check
            //7 clock cycle delay between sending data to cu and getting data from offsets
            if (
                (proc_ctr > (SYSTOL_ACTIVATION_COUNT + 7)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT) + 7))
            ) begin : CU_results_check

                for(integer z=0; z < (proc_ctr - (SYSTOL_ACTIVATION_COUNT + 7)); z++) begin
                    col = proc_ctr - (SYSTOL_ACTIVATION_COUNT + 7) - 1 - z;
                    row = z;
                    if((row < SYSTOL_WEIGHT_COUNT) && (col < SYSTOL_WEIGHT_COUNT)) begin
                        assert_count = assert_count + 1;
                        if(cu_result[row] == cu_result_matrix_1[row][col]) begin
                            $display("TRUE  | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_1[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_1[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_1[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_1[row][col]);
                            `endif
                        end
                    end
                end

                if(proc_ctr == ((SYSTOL_WEIGHT_COUNT + 2 * SYSTOL_ACTIVATION_COUNT) + 7)) begin
                    end_time = $time;
                end
            end
            
            proc_ctr = proc_ctr + 1;
        end

        $display("========================================");
        $display("Test result:");
        $display("Assertion count = %0d", assert_count);
        $display("Error count = %0d", error_assert_count);

        $display("========================================");
        $display("Computing unit work test:");
        $display("Matrix1[%0d][%0d] X Matrix2[%0d][%0d] + Matrix3[%0d][%0d]",
                SYSTOL_WEIGHT_COUNT, SYSTOL_ACTIVATION_COUNT,
                SYSTOL_ACTIVATION_COUNT, SYSTOL_WEIGHT_COUNT,
                SYSTOL_WEIGHT_COUNT, SYSTOL_WEIGHT_COUNT);
        $display("Freq = %0d MHz", `SYSTEM_CLK_FREQ_MHZ);
        $display("Time = %0t", (end_time - start_time));

        $display("========================================");
        $display("----------matrix_mul_test_1 END---------");
        $display("");

        `ifdef LOG_FILE
        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "Test result:");
        $fdisplay(log_fd, "Assertion count = %0d", assert_count); 
        $fdisplay(log_fd, "Error count = %0d", error_assert_count); 

        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "Computing unit work test:");
        $fdisplay(log_fd, "Matrix1[%0d][%0d] X Matrix2[%0d][%0d] + Matrix3[%0d][%0d]", 
                            SYSTOL_WEIGHT_COUNT, SYSTOL_ACTIVATION_COUNT, 
                            SYSTOL_ACTIVATION_COUNT, SYSTOL_WEIGHT_COUNT,
                            SYSTOL_WEIGHT_COUNT, SYSTOL_WEIGHT_COUNT);
        $fdisplay(log_fd, "Freq = %0d MHz", `SYSTEM_CLK_FREQ_MHZ);
        $fdisplay(log_fd, "Time = %0t", (end_time - start_time));

        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "----------matrix_mul_test_1 END---------");
        $fdisplay(log_fd, "");                            
        `endif
    end
endtask


// Task: matrix_mul_test_2
// Description:
// 1) multiplication test for matrices with sizes equal to a systolic array
// 2) sending weights and activations to the computing unit in parallel
//    simulation of the separate bus for weights and activations
localparam WEIGHT_X_SIZE_2 = SYSTOL_ACTIVATION_COUNT;
localparam WEIGHT_Y_SIZE_2 = SYSTOL_WEIGHT_COUNT;
localparam ACTIVATION_X_SIZE_2 = SYSTOL_WEIGHT_COUNT;
localparam ACTIVATION_Y_SIZE_2 = WEIGHT_X_SIZE_2;
localparam OFFSET_X_SIZE_2 = ACTIVATION_X_SIZE_2;
localparam OFFSET_Y_SIZE_2 = WEIGHT_Y_SIZE_2;

data_type weight_matrix_2 [0:WEIGHT_Y_SIZE_2 - 1]
                            [0:WEIGHT_X_SIZE_2 - 1];
                            
data_type activation_matrix_2 [0:ACTIVATION_Y_SIZE_2 - 1]
                                [0:ACTIVATION_X_SIZE_2 - 1];

data_type offset_matrix_2 [0:OFFSET_Y_SIZE_2 - 1]
                                [0:OFFSET_X_SIZE_2 - 1];

data_type mul_result_matrix_2 [0:WEIGHT_Y_SIZE_2-1][0:ACTIVATION_X_SIZE_2-1];
data_type offset_result_matrix_2 [0:WEIGHT_Y_SIZE_2-1][0:ACTIVATION_X_SIZE_2-1];
data_type cu_result_matrix_2 [0:WEIGHT_Y_SIZE_2-1][0:ACTIVATION_X_SIZE_2-1];

task matrix_mul_test_2();
    begin
        $display("");
        $display("--------matrix_mul_test_2 START---------");
        $display("========================================");

        `ifdef LOG_FILE
        $fdisplay(log_fd, "");
        $fdisplay(log_fd, "--------matrix_mul_test_2 START---------");
        $fdisplay(log_fd, "========================================");
        `endif

        cu_accum_adder_chain_set = 14'b00_0000_0000_0000;
        cu_accum_out_data_mux = 15'b000_0000_0000_0000;

        assert_count = 0;
        error_assert_count = 0;
        weight_column_num = 0;
        activation_row_num = 0;
        offset_row_num = 0;
        proc_ctr = 0;

        for(integer i=0; i<WEIGHT_Y_SIZE_2;i++) begin
            for(integer j=0; j<ACTIVATION_X_SIZE_2;j++) begin
                mul_result_matrix_2[i][j] = 0;
            end
        end
        
        @(posedge sys_clk);
        #1;
        
        for(integer i=0; i<WEIGHT_Y_SIZE_2;i++)	begin : mul_array_gold_res_calc
            for(integer j=0; j<ACTIVATION_X_SIZE_2;j++)	begin
                for(integer k=0; k<WEIGHT_X_SIZE_2;k++)	begin
                    mul_result_matrix_2[i][j] = mul_result_matrix_2[i][j] + 
                                                weight_matrix_2[i][k] * 
                                                activation_matrix_2[k][j];
                end
            end
        end

        for(integer i=0; i<OFFSET_Y_SIZE_2;i++)	begin : offset_gold_res_calc
            for(integer j=0; j<OFFSET_X_SIZE_2;j++)	begin
                offset_result_matrix_2[i][j] = mul_result_matrix_2[i][j] + 
                                                offset_matrix_2[i][j];
            end
        end
        
        for(integer i=0; i<WEIGHT_Y_SIZE_2;i++)	begin : CU_gold_res_calc
            for(integer j=0; j<ACTIVATION_X_SIZE_2;j++)	begin
                cu_result_matrix_2[i][j] = (offset_result_matrix_2[i][j] < 0) ? 
                                                0 : offset_result_matrix_2[i][j];
            end
        end
        
        while (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 10)) begin
            @(posedge sys_clk);
            #1;
            
            //weight sending
            if(weight_column_num < WEIGHT_X_SIZE_2) begin : weight_sending
                if(cu_weight_full == 0) begin
                    if(weight_column_num == 0) begin
                        cu_weight_update = 1;

                        start_time = $time;
                    end
                    else begin
                        cu_weight_update = 0;
                    end

                    cu_weight_wr_en = 1;
                    for(integer i=0; i < SYSTOL_WEIGHT_COUNT; i++) begin
                        cu_weight[i] = weight_matrix_2[i][WEIGHT_X_SIZE_2 - weight_column_num - 1];
                    end
                    weight_column_num = weight_column_num + 1;
                end
                else begin
                    cu_weight_wr_en = 0;
                end
            end
            else begin
                cu_weight_update = 0;
                cu_weight_wr_en = 0;
            end

            //activation sending
            if(activation_row_num < (2 * ACTIVATION_X_SIZE_2 + ACTIVATION_Y_SIZE_2)) begin : activation_sending
                if(cu_activation_full == 0) begin
                    cu_activation_wr_en = 1;
                    for(integer i = 0; i < SYSTOL_ACTIVATION_COUNT; i++) begin
                        cu_activation[i] = 0;
                    end
                    
                    for(integer i = 0; i < activation_row_num + 1; i++) begin
                        if((activation_row_num - i) < ACTIVATION_X_SIZE_2) begin
                            cu_activation[i] = activation_matrix_2[i][activation_row_num - i];
                        end
                    end

                    activation_row_num = activation_row_num + 1;
                end
                else begin
                    cu_activation_wr_en = 0;
                end
            end
            else begin
                cu_activation_wr_en = 0;
            end

            //offsets sending
            //start 4 clock cycle before getting results from accum block
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 6 - 4)) && 
                (offset_row_num < (OFFSET_X_SIZE_2 + OFFSET_Y_SIZE_2))
            ) begin : offsets_sending

                if(cu_offset_full == 0) begin
                    cu_offset_wr_en = 1;
                    for(integer i = 0; i < SYSTOL_WEIGHT_COUNT; i++) begin
                        cu_offset[i] = 0;
                    end

                    for(integer i = 0; i < offset_row_num + 1; i++) begin
                        if((offset_row_num - i) < SYSTOL_WEIGHT_COUNT) begin
                            cu_offset[i] = offset_matrix_2[i][offset_row_num - i];
                        end
                    end

                    offset_row_num = offset_row_num + 1;
                end
                else begin
                    cu_offset_wr_en = 0;
                end
            end
            else begin
                cu_offset_wr_en = 0;
            end

            //systol array results check
            //4 clock cycle delay between sending data to cu and storing data in systolic array
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 4)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 4))
            ) begin : systol_array_results_check

                for(integer z = 0; z < (proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 4)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 4) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_2) && (col < ACTIVATION_X_SIZE_2)) begin
                        assert_count = assert_count + 1;
                        if(cu.systol_arr_dout[row] == mul_result_matrix_2[row][col]) begin
                            $display("TRUE  | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_2[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_2[row][col]);
                            `endif
                        end
                    end
                end
            end

            //accum results check
            //6 clock cycle delay between sending data to cu and getting data from accumulators
            //if cu_accum_adder_chain_set == 14'b00_0000_0000_0000;
            //   cu_accum_out_data_mux == 15'b000_0000_0000_0000;
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 6)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 6))
            ) begin : accum_results_check

                for(integer z = 0; z < (proc_ctr - (2* SYSTOL_ACTIVATION_COUNT + 6)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 6) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_2) && (col < ACTIVATION_X_SIZE_2)) begin
                        assert_count = assert_count + 1;
                        if(cu.accum_dout[row] == mul_result_matrix_2[row][col]) begin
                            $display("TRUE  | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_2[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[row], row, col, mul_result_matrix_2[row][col]);
                            `endif
                        end
                    end
                end             
            end

            //offset results check
            //7 clock cycle delay between sending data to cu and getting data from offsets
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 7)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 7))
            ) begin : offset_results_check

                for(integer z=0; z < (proc_ctr - (2* SYSTOL_ACTIVATION_COUNT + 7)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 7) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_2) && (col < ACTIVATION_X_SIZE_2)) begin
                        assert_count = assert_count + 1;
                        if(cu.offsets_dout[row] == offset_result_matrix_2[row][col]) begin
                            $display("TRUE  | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_2[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_2[row][col]);
                            `endif
                        end
                    end
                end             
            end

            //cu results check
            //8 clock cycle delay between sending data to cu and getting data from offsets
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 8)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 8))
            ) begin : CU_results_check

                for(integer z=0; z < (proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 8)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 8) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_2) && (col < ACTIVATION_X_SIZE_2)) begin
                        assert_count = assert_count + 1;
                        if(cu_result[row] == cu_result_matrix_2[row][col]) begin
                            $display("TRUE  | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_2[row][col]);
                            
                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_2[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_2[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_2[row][col]);
                            `endif
                        end
                    end
                end  

                if(proc_ctr == ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 7)) begin
                    end_time = $time;
                end
            end

            proc_ctr = proc_ctr + 1;
        end

        $display("========================================");
        $display("Test result:");
        $display("Assertion count = %0d", assert_count); 
        $display("Error count = %0d", error_assert_count); 

        $display("========================================");
        $display("Computing unit work test:");
        $display("Matrix1[%0d][%0d] X Matrix2[%0d][%0d] + Matrix3[%0d][%0d]", 
                WEIGHT_Y_SIZE_2, WEIGHT_X_SIZE_2, 
                ACTIVATION_Y_SIZE_2, ACTIVATION_X_SIZE_2,
                OFFSET_Y_SIZE_2, OFFSET_X_SIZE_2);
        $display("Freq = %0d MHz", `SYSTEM_CLK_FREQ_MHZ);
        $display("Time = %0t", (end_time - start_time));

        $display("========================================");
        $display("----------matrix_mul_test_2 END---------");
        $display("");

        `ifdef LOG_FILE
        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "Test result:");
        $fdisplay(log_fd, "Assertion count = %0d", assert_count); 
        $fdisplay(log_fd, "Error count = %0d", error_assert_count); 

        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "Computing unit work test:");
        $fdisplay(log_fd, "Matrix1[%0d][%0d] X Matrix2[%0d][%0d] + Matrix3[%0d][%0d]", 
                            WEIGHT_Y_SIZE_2, WEIGHT_X_SIZE_2, 
                            ACTIVATION_Y_SIZE_2, ACTIVATION_X_SIZE_2,
                            OFFSET_Y_SIZE_2, OFFSET_X_SIZE_2);
        $fdisplay(log_fd, "Freq = %0d MHz", `SYSTEM_CLK_FREQ_MHZ);
        $fdisplay(log_fd, "Time = %0t", (end_time - start_time));

        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "----------matrix_mul_test_2 END---------");
        $fdisplay(log_fd, "");
        `endif
    end
endtask


// Task: matrix_mul_test_3
// Description:
// 1) multiplication test for matrices with sizes BIGGER than a systolic array
//    using the software algorithm for LINEAR arrangement of matrices in a systolic array
// 2) sending weights and activations to the computing unit in PARALLEL
//    simulation of the SEPARATE BUS for weights and activations
localparam WEIGHT_X_SIZE_3 = 576; //3x3x64x64
localparam WEIGHT_Y_SIZE_3 = 64;
localparam ACTIVATION_X_SIZE_3 = 322624;
localparam ACTIVATION_Y_SIZE_3 = WEIGHT_X_SIZE_3;
localparam OFFSET_X_SIZE_3 = ACTIVATION_X_SIZE_3;
localparam OFFSET_Y_SIZE_3 = WEIGHT_Y_SIZE_3;

data_type weight_matrix_3 [0:WEIGHT_Y_SIZE_3 - 1]
                            [0:WEIGHT_X_SIZE_3 - 1];
                            
data_type activation_matrix_3 [0:ACTIVATION_Y_SIZE_3 - 1]
                                [0:ACTIVATION_X_SIZE_3 - 1];

data_type offset_matrix_3 [0:OFFSET_Y_SIZE_3 - 1]
                                [0:OFFSET_X_SIZE_3 - 1];

data_type gold_res;
data_type mul_result_matrix_3 [0:WEIGHT_Y_SIZE_3-1][0:ACTIVATION_X_SIZE_3-1];
data_type offset_result_matrix_3 [0:WEIGHT_Y_SIZE_3-1][0:ACTIVATION_X_SIZE_3-1];
data_type cu_result_matrix_3 [0:WEIGHT_Y_SIZE_3-1][0:ACTIVATION_X_SIZE_3-1];


localparam LINES_NUM = (WEIGHT_X_SIZE_3 <= SYSTOL_ACTIVATION_COUNT) ? 1 : (
                            ((WEIGHT_X_SIZE_3 % SYSTOL_ACTIVATION_COUNT) == 0) ?
                                (WEIGHT_X_SIZE_3 / SYSTOL_ACTIVATION_COUNT) :
                                (WEIGHT_X_SIZE_3 / SYSTOL_ACTIVATION_COUNT) + 1
                        );

localparam PRE_WEIGHT_X_SIZE_3 = SYSTOL_ACTIVATION_COUNT;
localparam PRE_WEIGHT_Y_SIZE_3 = WEIGHT_Y_SIZE_3 * LINES_NUM;

data_type preproc_weight_matrix_3 [0:PRE_WEIGHT_Y_SIZE_3 - 1]
                                  [0:PRE_WEIGHT_X_SIZE_3 - 1];

localparam PRE_ACTIVATION_X_SIZE_3 = ACTIVATION_X_SIZE_3 * LINES_NUM;
localparam PRE_ACTIVATION_Y_SIZE_3 = PRE_WEIGHT_X_SIZE_3;

data_type preproc_activation_matrix_3 [0:PRE_ACTIVATION_Y_SIZE_3 - 1]
                                      [0:PRE_ACTIVATION_X_SIZE_3 - 1];

localparam ITERATION_NUM_3 = (PRE_WEIGHT_Y_SIZE_3 <= SYSTOL_WEIGHT_COUNT) ? 1 : (
                                ((PRE_WEIGHT_Y_SIZE_3 % SYSTOL_WEIGHT_COUNT) == 0) ?
                                    (PRE_WEIGHT_Y_SIZE_3 / SYSTOL_WEIGHT_COUNT) :
                                    (PRE_WEIGHT_Y_SIZE_3 / SYSTOL_WEIGHT_COUNT) + 1
                            );

task matrix_mul_test_3();
    begin

        $display("");
        $display("--------matrix_mul_test_3 START---------");
        $display("========================================");

        `ifdef LOG_FILE
        $fdisplay(log_fd, "");
        $fdisplay(log_fd, "--------matrix_mul_test_3 START---------");
        $fdisplay(log_fd, "========================================");
        `endif
        case (LINES_NUM)
            1:        begin cu_accum_adder_chain_set = 14'b00_0000_0000_0000; cu_accum_out_data_mux = 15'b000_0000_0000_0000; end
            2:        begin cu_accum_adder_chain_set = 14'b00_0000_0000_0000; cu_accum_out_data_mux = 15'b101_0101_0101_0101; end
            3:        begin cu_accum_adder_chain_set = 14'b10_0100_1001_0010; cu_accum_out_data_mux = 15'b010_0100_1001_0010; end
            4:        begin cu_accum_adder_chain_set = 14'b11_0011_0011_0011; cu_accum_out_data_mux = 15'b001_0001_0001_0001; end
            5:        begin cu_accum_adder_chain_set = 14'b11_1001_1100_1110; cu_accum_out_data_mux = 15'b000_1000_0100_0010; end
            6:        begin cu_accum_adder_chain_set = 14'b11_1100_1111_0011; cu_accum_out_data_mux = 15'b000_0100_0001_0000; end
            7:        begin cu_accum_adder_chain_set = 14'b11_1110_0111_1100; cu_accum_out_data_mux = 15'b000_0010_0000_0100; end
            8:        begin cu_accum_adder_chain_set = 14'b11_1111_0011_1111; cu_accum_out_data_mux = 15'b000_0001_0000_0001; end
            9:        begin cu_accum_adder_chain_set = 14'b11_1111_1001_1111; cu_accum_out_data_mux = 15'b000_0000_1000_0000; end
            10:       begin cu_accum_adder_chain_set = 14'b11_1111_1100_1111; cu_accum_out_data_mux = 15'b000_0000_0100_0000; end
            11:       begin cu_accum_adder_chain_set = 14'b11_1111_1110_0111; cu_accum_out_data_mux = 15'b000_0000_0010_0000; end
            12:       begin cu_accum_adder_chain_set = 14'b11_1111_1111_0011; cu_accum_out_data_mux = 15'b000_0000_0001_0000; end
            13:       begin cu_accum_adder_chain_set = 14'b11_1111_1111_1001; cu_accum_out_data_mux = 15'b000_0000_0000_1000; end
            14:       begin cu_accum_adder_chain_set = 14'b11_1111_1111_1100; cu_accum_out_data_mux = 15'b000_0000_0000_0100; end
            15:       begin cu_accum_adder_chain_set = 14'b11_1111_1111_1110; cu_accum_out_data_mux = 15'b000_0000_0000_0010; end
            16:       begin cu_accum_adder_chain_set = 14'b11_1111_1111_1111; cu_accum_out_data_mux = 15'b000_0000_0000_0001; end

            default:  begin cu_accum_adder_chain_set = 14'b00_0000_0000_0000; cu_accum_out_data_mux = 15'b000_0000_0000_0000; end
        endcase
        
        iteration_count = 0;
        assert_count = 0;
        error_assert_count = 0;

        weight_column_num = 0;
        weight_row_num = 0;

        activation_row_num = 0;
        offset_row_num = 0;
        proc_ctr = 0;
        tmp_proc_count = 0;

        monitor_tmp_proc_count = 0;
        systol_arr_res_check_done = 0;
        accum_res_check_done = 0;
        offset_res_check_done = 0;
        activ_res_check_done = 0;

        for(integer i=0; i<WEIGHT_Y_SIZE_3;i++) begin
            for(integer j=0; j<ACTIVATION_X_SIZE_3;j++) begin
                mul_result_matrix_3[i][j] = 0;
            end
        end
        
        @(posedge sys_clk);
        #1;
        
        for(integer i=0; i<WEIGHT_Y_SIZE_3;i++)	begin : mul_array_gold_res_calc
            for(integer j=0; j<ACTIVATION_X_SIZE_3;j++)	begin
                for(integer k=0; k<WEIGHT_X_SIZE_3;k++)	begin
                    mul_result_matrix_3[i][j] = mul_result_matrix_3[i][j] + 
                                                weight_matrix_3[i][k] * 
                                                activation_matrix_3[k][j];
                end
            end
        end

        for(integer i=0; i<OFFSET_Y_SIZE_3;i++)	begin : offset_gold_res_calc
            for(integer j=0; j<OFFSET_X_SIZE_3;j++)	begin
                offset_result_matrix_3[i][j] = mul_result_matrix_3[i][j] + 
                                                offset_matrix_3[i][j];
            end
        end
        
        for(integer i=0; i<WEIGHT_Y_SIZE_3;i++)	begin : CU_gold_res_calc
            for(integer j=0; j<ACTIVATION_X_SIZE_3;j++) begin
                cu_result_matrix_3[i][j] = (offset_result_matrix_3[i][j] < 0) ? 
                                                0 : offset_result_matrix_3[i][j];
            end
        end

        begin : weight_matrix_preprocessing
        for(integer i=0; i<PRE_WEIGHT_Y_SIZE_3;i++) begin
            for(integer j=0; j<PRE_WEIGHT_X_SIZE_3;j++) begin
                preproc_weight_matrix_3[i][j] = 0;
            end
        end

        for(integer i=0; i<(WEIGHT_Y_SIZE_3);i++) begin
            for(integer j=0; j<WEIGHT_X_SIZE_3;j++) begin
                preproc_weight_matrix_3[(i*LINES_NUM)+(j/SYSTOL_ACTIVATION_COUNT)]
                                        [j%SYSTOL_ACTIVATION_COUNT] = weight_matrix_3[i][j];
            end
        end
        end

        begin : activation_matrix_preprocessing
        for(integer i=0; i<PRE_ACTIVATION_Y_SIZE_3;i++) begin
            for(integer j=0; j<PRE_ACTIVATION_X_SIZE_3;j++) begin
                preproc_activation_matrix_3[i][j] = 0;
            end
        end

        for(integer j=0; j<ACTIVATION_X_SIZE_3; j++) begin
            for(integer i=0; i<ACTIVATION_Y_SIZE_3; i++) begin
                preproc_activation_matrix_3[i%SYSTOL_ACTIVATION_COUNT]
                                            [(j*LINES_NUM)+(i/SYSTOL_ACTIVATION_COUNT)] = activation_matrix_3[i][j];
            end
        end
        end

        start_time = $time;

//        while (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 10 * SYSTOL_ACTIVATION_COUNT) + 10)) begin
        while (proc_ctr <= 3 + ((PRE_WEIGHT_X_SIZE_3 + SYSTOL_ACTIVATION_COUNT +PRE_ACTIVATION_X_SIZE_3 + SYSTOL_WEIGHT_COUNT + 3 + 1 + 1 ) * ITERATION_NUM_3)) begin
            @(posedge sys_clk);
            #1;

            //calc process
            cu_weight_update = 0;
            if(proc_ctr == 0) begin : calc_process
                cu_weight_update = 1;
            
            //SYSTOL_ACTIVATION_COUNT - time for weight sending to fifo
            //(SYSTOL_ACTIVATION_COUNT + PRE_ACTIVATION_X_SIZE_3 + SYSTOL_WEIGHT_COUNT) - time for actvation sending to fifo
            end else if((proc_ctr - tmp_proc_count) ==
                            (SYSTOL_ACTIVATION_COUNT + PRE_ACTIVATION_X_SIZE_3 + SYSTOL_WEIGHT_COUNT)) begin
                cu_weight_update = 1;
            end

            if(cu_weight_update_busy == 1) begin
                tmp_proc_count = proc_ctr;
                monitor_tmp_proc_count = proc_ctr;
            end

            //weight sending
            if(cu_weight_full == 0) begin : weight_sending_to_fifo
                if(weight_row_num < PRE_WEIGHT_Y_SIZE_3) begin
                    if(weight_column_num < PRE_WEIGHT_X_SIZE_3) begin
                        cu_weight_wr_en = 1;

                        for(integer i=0; i < SYSTOL_WEIGHT_COUNT; i++) begin
                            if((weight_row_num + i) < PRE_WEIGHT_Y_SIZE_3) begin
                                cu_weight[i] = preproc_weight_matrix_3[weight_row_num + i]
                                                                    [PRE_WEIGHT_X_SIZE_3 - weight_column_num - 1]; 
                            end else begin
                                cu_weight[i] = 0;
                            end
                        end

                        weight_column_num = weight_column_num + 1;
                    end else begin
                        weight_row_num = weight_row_num + SYSTOL_WEIGHT_COUNT;
                        weight_column_num = 0;
                        cu_weight_wr_en = 0;
                    end
                end else begin
                    cu_weight_wr_en = 0;
                end
            end else begin
                cu_weight_wr_en = 0;
            end

            //activation sending
            if(iteration_count < ITERATION_NUM_3) begin
                if(activation_row_num < (SYSTOL_ACTIVATION_COUNT + PRE_ACTIVATION_X_SIZE_3 + SYSTOL_WEIGHT_COUNT)) begin : activation_sending
                    if(cu_activation_full == 0) begin
                        cu_activation_wr_en = 1;
                        for(integer i = 0; i < SYSTOL_ACTIVATION_COUNT; i++) begin
                            cu_activation[i] = 0;
                        end
                        
                        for(integer i = 0; i < activation_row_num + 1; i++) begin
                            if((activation_row_num - i) < PRE_ACTIVATION_X_SIZE_3) begin
                                cu_activation[i] = preproc_activation_matrix_3[i][activation_row_num - i];
                            end
                        end

                        activation_row_num = activation_row_num + 1;
                    end
                    else begin
                        cu_activation_wr_en = 0;
                    end
                end
                else begin
                    cu_activation_wr_en = 0;
                    activation_row_num = 0;
                    iteration_count = iteration_count + 1;
                end
            end else begin
                cu_activation_wr_en = 0;
            end

            //offsets sending
            //start 4 clock cycle before getting results from accum block 
            //TODO обновить подачу смещений
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 5 - 4)) && 
                (offset_row_num < (OFFSET_X_SIZE_3 + OFFSET_Y_SIZE_3))
            ) begin : offsets_sending

                if(cu_offset_full == 0) begin
                    cu_offset_wr_en = 1;
                    for(integer i = 0; i < SYSTOL_WEIGHT_COUNT; i++) begin
                        cu_offset[i] = 0;
                    end

                    for(integer i = 0; i < offset_row_num + 1; i++) begin
                        if((offset_row_num - i) < SYSTOL_WEIGHT_COUNT) begin
                            cu_offset[i] = offset_matrix_3[i][offset_row_num - i];
                        end
                    end

                    offset_row_num = offset_row_num + 1;
                end
                else begin
                    cu_offset_wr_en = 0;
                end
            end
            else begin
                cu_offset_wr_en = 0;
            end

            //systol array results check
            if (
                ((proc_ctr - monitor_tmp_proc_count) > (SYSTOL_ACTIVATION_COUNT + 1)) &&
                ((proc_ctr - monitor_tmp_proc_count) <= (SYSTOL_ACTIVATION_COUNT + PRE_ACTIVATION_X_SIZE_3 
                                                                                    + SYSTOL_WEIGHT_COUNT + 1))
            ) begin : systol_array_results_check

                for(integer z = 0; z < (proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 4)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 4) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_3) && (col < ACTIVATION_X_SIZE_3)) begin
                        assert_count = assert_count + 1;
                        if(cu.systol_arr_dout[row] == mul_result_matrix_3[row][col]) begin
                            $display("TRUE  | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_3[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_3[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_3[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] SystolArr_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.systol_arr_dout[row], row, col, mul_result_matrix_3[row][col]);
                            `endif
                        end
                    end
                end
            end

            //accum results check
            //2 clock cycle delay between sending data to accumulators and getting data from accumulators
            if (
                ((proc_ctr - monitor_tmp_proc_count) > (SYSTOL_ACTIVATION_COUNT + 1 + 2)) &&
                ((proc_ctr - monitor_tmp_proc_count) <= (SYSTOL_ACTIVATION_COUNT + PRE_ACTIVATION_X_SIZE_3 
                                                                                    + SYSTOL_WEIGHT_COUNT + 1 + 2))
            ) begin : accum_results_check
                for(integer z = 0; z < (proc_ctr - monitor_tmp_proc_count - (SYSTOL_ACTIVATION_COUNT + 1 + 2)); z++) begin
                    col = proc_ctr - monitor_tmp_proc_count - (SYSTOL_ACTIVATION_COUNT + 1 + 2) - 1 - z;
                    row = z;
                    if(LINES_NUM == 1) begin
                        gold_res = mul_result_matrix_3[row][col];
                    end else if((z % LINES_NUM) == (LINES_NUM - 1)) begin
                        // col = ;
                        row = z / LINES_NUM;
                        gold_res = mul_result_matrix_3[row][col];
                    end else begin
                        col = 32'bX;
                        row = 32'bX;
                        gold_res = 32'dZ;
                    end
                    if((row < WEIGHT_Y_SIZE_3) && (col < ACTIVATION_X_SIZE_3)) begin
                        assert_count = assert_count + 1;
                        if(cu.accum_dout[z] === gold_res) begin
                            $display("TRUE  | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[z], row, col, gold_res);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[z], row, col, gold_res);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[z], row, col, gold_res);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] Accum_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.accum_dout[z], row, col, gold_res);
                            `endif
                        end
                    end
                end             
            end

            //offset results check
            //6 clock cycle delay between sending data to cu and getting data from offsets
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 6)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 6))
            ) begin : offset_results_check

                for(integer z=0; z < (proc_ctr - (2* SYSTOL_ACTIVATION_COUNT + 6)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 6) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_3) && (col < ACTIVATION_X_SIZE_3)) begin
                        assert_count = assert_count + 1;
                        if(cu.offsets_dout[row] == offset_result_matrix_3[row][col]) begin
                            $display("TRUE  | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_3[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_3[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_3[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] Offsets_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu.offsets_dout[row], row, col, offset_result_matrix_3[row][col]);
                            `endif
                        end
                    end
                end             
            end

            //cu results check
            //7 clock cycle delay between sending data to cu and getting data from offsets
            if (
                (proc_ctr > (2 * SYSTOL_ACTIVATION_COUNT + 7)) && 
                (proc_ctr <= ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 7))
            ) begin : CU_results_check

                for(integer z=0; z < (proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 7)); z++) begin
                    col = proc_ctr - (2 * SYSTOL_ACTIVATION_COUNT + 7) - 1 - z;
                    row = z;
                    if((row < WEIGHT_Y_SIZE_3) && (col < ACTIVATION_X_SIZE_3)) begin
                        assert_count = assert_count + 1;
                        if(cu_result[row] == cu_result_matrix_3[row][col]) begin
                            $display("TRUE  | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_3[row][col]);
                            
                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "TRUE  | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_3[row][col]);
                            `endif
                        end
                        else begin
                            error_assert_count = error_assert_count + 1;
                            $display("FALSE | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_3[row][col]);

                            `ifdef LOG_FILE
                            $fdisplay(log_fd, "FALSE | [%0t] CU_out | C[%0d][%0d] = %0d | C_gold[%0d][%0d] = %0d ", 
                                    $time, row, col, cu_result[row], row, col, cu_result_matrix_3[row][col]);
                            `endif
                        end
                    end
                end  

//                if(proc_ctr == ((SYSTOL_WEIGHT_COUNT + 3 * SYSTOL_ACTIVATION_COUNT) + 7)) begin
                if(proc_ctr == ((PRE_WEIGHT_X_SIZE_3 + SYSTOL_ACTIVATION_COUNT +PRE_ACTIVATION_X_SIZE_3 + SYSTOL_WEIGHT_COUNT + 3 + 1 + 1 ) * ITERATION_NUM_3)) begin
                    end_time = $time;
                end
            end

            if(systol_arr_res_check_done & accum_res_check_done &
                offset_res_check_done & activ_res_check_done) begin
                monitor_tmp_proc_count = tmp_proc_count;
                
                systol_arr_res_check_done = 0;
                accum_res_check_done = 0;
                offset_res_check_done = 0;
                activ_res_check_done = 0;
            end

            proc_ctr = proc_ctr + 1;
            
        end

        $display("========================================");
        $display("Test result:");
        $display("Assertion count = %0d", assert_count); 
        $display("Error count = %0d", error_assert_count); 

        $display("========================================");
        $display("Computing unit work test:");
        $display("Matrix1[%0d][%0d] X Matrix2[%0d][%0d] + Matrix3[%0d][%0d]", 
                WEIGHT_Y_SIZE_3, WEIGHT_X_SIZE_3, 
                ACTIVATION_Y_SIZE_3, ACTIVATION_X_SIZE_3,
                OFFSET_Y_SIZE_3, OFFSET_X_SIZE_3);
        $display("Freq = %0d MHz", `SYSTEM_CLK_FREQ_MHZ);
        $display("Time = %0t", (end_time - start_time));

        $display("========================================");
        $display("----------matrix_mul_test_3 END---------");
        $display("");

        `ifdef LOG_FILE
        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "Test result:");
        $fdisplay(log_fd, "Assertion count = %0d", assert_count); 
        $fdisplay(log_fd, "Error count = %0d", error_assert_count); 

        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "Computing unit work test:");
        $fdisplay(log_fd, "Matrix1[%0d][%0d] X Matrix2[%0d][%0d] + Matrix3[%0d][%0d]", 
                            WEIGHT_Y_SIZE_3, WEIGHT_X_SIZE_3, 
                            ACTIVATION_Y_SIZE_3, ACTIVATION_X_SIZE_3,
                            OFFSET_Y_SIZE_3, OFFSET_X_SIZE_3);
        $fdisplay(log_fd, "Freq = %0d MHz", `SYSTEM_CLK_FREQ_MHZ);
        $fdisplay(log_fd, "Time = %0t", (end_time - start_time));

        $fdisplay(log_fd, "========================================");
        $fdisplay(log_fd, "----------matrix_mul_test_3 END---------");
        $fdisplay(log_fd, "");
        `endif
    end
endtask


integer log_fd;

initial begin : main
    $timeformat(-9, 0, "ns");

    `ifdef LOG_FILE
    log_fd = $fopen(`LOG_FILE);
    `endif

    cu_weight_update = 0;
    cu_activation_wr_en = 0;
    cu_weight_wr_en = 0;
    cu_offset_wr_en = 0;

    cu_accum_adder_chain_set = 14'b00_0000_0000_0000;
    cu_accum_out_data_mux = 15'b000_0000_0000_0000;
    
    for(integer i=0; i<SYSTOL_ACTIVATION_COUNT;i++)	begin
        cu_activation[i] = 0;
    end
    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        cu_weight[i] = 0;
    end
    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        cu_offset[i] = 0;
    end
    
    @(negedge sys_rst);
    
    @(negedge cu_rst_busy);
    
    begin : input_data_generation
    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin //TODO добавить в тест 1 размеры матриц как отдельный параметр
        for(integer j=0; j<SYSTOL_ACTIVATION_COUNT;j++)	begin
            weight_matrix_1[i][j] = ($random % 8192) + 1;
            activation_matrix_1[j][i] = ($random % 8192) + 1;
        end
    end

    for(integer i=0; i<WEIGHT_Y_SIZE_2;i++)	begin
        for(integer j=0; j<WEIGHT_X_SIZE_2;j++)	begin
            weight_matrix_2[i][j] = ($random % 8192) + 1;
        end
    end

    for(integer i=0; i<ACTIVATION_Y_SIZE_2;i++)	begin
        for(integer j=0; j<ACTIVATION_X_SIZE_2;j++)	begin
            activation_matrix_2[i][j] = ($random % 8192) + 1;
        end
    end

    for(integer i=0; i<WEIGHT_Y_SIZE_3;i++)	begin
        for(integer j=0; j<WEIGHT_X_SIZE_3;j++)	begin
            // weight_matrix_3[i][j] = ($random % 8192) + 1;
            weight_matrix_3[i][j] = i*WEIGHT_X_SIZE_3 + j;
        end
    end

    for(integer i=0; i<ACTIVATION_Y_SIZE_3;i++)	begin
        for(integer j=0; j<ACTIVATION_X_SIZE_3;j++)	begin
            // activation_matrix_3[i][j] = ($random % 8192) + 1;
            activation_matrix_3[i][j] = i*ACTIVATION_X_SIZE_3 + j + 1;
        end
    end

    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin //TODO добавить в тест 1 размеры матриц как отдельный параметр
        for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
            offset_matrix_1[i][j] = ($random % 8192) + 1;
        end
    end

    for(integer i=0; i<OFFSET_Y_SIZE_2;i++)	begin
        for(integer j=0; j<OFFSET_X_SIZE_2;j++)	begin
            offset_matrix_2[i][j] = ($random % 8192) + 1;
        end
    end

    for(integer i=0; i<OFFSET_Y_SIZE_3;i++)	begin
        for(integer j=0; j<OFFSET_X_SIZE_3;j++)	begin
            offset_matrix_3[i][j] = ($random % 8192) + 1;
        end
    end
    end

    begin : input_data_display

    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        for(integer j=0; j<SYSTOL_ACTIVATION_COUNT;j++)	begin
            $display("weight[%0d][%0d] = %0d", i, j, weight_matrix_1[i][j]);

            `ifdef LOG_FILE
            $fdisplay(log_fd, "weight[%0d][%0d] = %0d", i, j, weight_matrix_1[i][j]);
            `endif
        end
    end
    
    for(integer i=0; i<SYSTOL_ACTIVATION_COUNT;i++)	begin
        for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
            $display("activation[%0d][%0d] = %0d", i, j, activation_matrix_1[i][j]);

            `ifdef LOG_FILE
            $fdisplay(log_fd, "activation[%0d][%0d] = %0d", i, j, activation_matrix_1[i][j]);
            `endif
        end
    end

    for(integer i=0; i<SYSTOL_WEIGHT_COUNT;i++)	begin
        for(integer j=0; j<SYSTOL_WEIGHT_COUNT;j++)	begin
            $display("offset[%0d][%0d] = %0d", i, j, offset_matrix_1[i][j]);

            `ifdef LOG_FILE
            $fdisplay(log_fd, "offset[%0d][%0d] = %0d", i, j, offset_matrix_1[i][j]);
            `endif
        end
    end
    end

    begin : test_exec
    // matrix_mul_test_1();

//     matrix_mul_test_2();
    
    matrix_mul_test_3();

    $display("test = %0d", (1 / 2));

    end

    `ifdef LOG_FILE
    $fclose(log_fd);
    `endif

    $finish;
    
end

endmodule   
