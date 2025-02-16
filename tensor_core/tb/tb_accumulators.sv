`timescale 1ps / 1ps

`ifndef VIVADO_PRJ_USE
`include "types.vh"
`endif
import types::*;

`define SYSTEM_CLK_HALF_PERIOD 5000

module tb_accumulators;

localparam ACCUM_SIZE = 16;

logic accum_clk;
logic accum_rst;

data_type accum_in_data [0:ACCUM_SIZE-1];
logic [2:ACCUM_SIZE-1] accum_adder_chain_set;
logic [1:ACCUM_SIZE-1] accum_out_data_mux;
data_type accum_out_data [0:ACCUM_SIZE-1];

data_type data [0:ACCUM_SIZE-1];

accumulators #(
    .IN_SIZE(ACCUM_SIZE))
accum (
    .clk_i(accum_clk)
    , .rst_i(accum_rst)
   
    , .data_i(accum_in_data)
    
    , .adder_chain_set_i(accum_adder_chain_set)
    , .out_data_mux_i(accum_out_data_mux)
    
    , .data_o(accum_out_data)
);

//reset generation
initial begin
    accum_clk = 0;
    accum_rst = 1;

    #(`SYSTEM_CLK_HALF_PERIOD * 10);
    accum_rst = 0;
end

always #(`SYSTEM_CLK_HALF_PERIOD) accum_clk = ~accum_clk;

task accum_out_data_static_test(
    input logic [2:ACCUM_SIZE-1] adder_chain_set,
    input logic [1:ACCUM_SIZE-1] out_data_mux,
    input data_type in_data [0:ACCUM_SIZE-1]
);
begin
    data_type gold_out [0:ACCUM_SIZE-1];

    @(posedge accum_clk);
    #1;
    accum_adder_chain_set = adder_chain_set;
    accum_out_data_mux = out_data_mux;
    accum_in_data = in_data;
    
    $display("");
    $display("-------accum_out_data_static_test START--------");
    $display("========================================");
    $display("adder_chain_set = %b", adder_chain_set);
    $display("out_data_mux = %b", out_data_mux);
    $write("in_data = { ");
    for(integer i = 0; i<ACCUM_SIZE; i = i + 1) begin
        $write("%0d ", in_data[i]);
    end
    $display("}");
    $display("========================================");

    @(posedge accum_clk);
    @(posedge accum_clk);
    #1;
    
    case (out_data_mux)
        15'b000_0000_0000_0000: begin
            for(integer i = 0; i<ACCUM_SIZE; i = i + 1) begin
                gold_out[i] = in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b101_0101_0101_0101: begin
            for(integer i = 0; i < 1; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 1; i<ACCUM_SIZE; i = i + 2) begin
                gold_out[i] = in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b010_0100_1001_0010: begin
            for(integer i = 0; i < 2; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 2; i<ACCUM_SIZE; i = i + 3) begin
                gold_out[i] = in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b001_0001_0001_0001: begin
            for(integer i = 0; i < 3; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 3; i<ACCUM_SIZE; i = i + 4) begin
                gold_out[i] = in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_1000_0100_0010: begin
            for(integer i = 0; i < 4; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 4; i<ACCUM_SIZE; i = i + 5) begin
                gold_out[i] = in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0100_0001_0000: begin
            for(integer i = 0; i < 5; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 5; i<ACCUM_SIZE; i = i + 6) begin
                gold_out[i] = in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0010_0000_0100: begin
            for(integer i = 0; i < 6; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 6; i<ACCUM_SIZE; i = i + 7) begin
                gold_out[i] = in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0001_0000_0001: begin
            for(integer i = 0; i < 7; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 7; i<ACCUM_SIZE; i = i + 8) begin
                gold_out[i] = in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_1000_0000: begin
            for(integer i = 0; i < 8; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 8; i<ACCUM_SIZE; i = i + 9) begin
                gold_out[i] = in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0100_0000: begin
            for(integer i = 0; i < 9; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 9; i<ACCUM_SIZE; i = i + 10) begin
                gold_out[i] = in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0010_0000: begin
            for(integer i = 0; i < 10; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 10; i<ACCUM_SIZE; i = i + 11) begin
                gold_out[i] = in_data[i-10] + in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0001_0000: begin
            for(integer i = 0; i < 11; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 11; i<ACCUM_SIZE; i = i + 12) begin
                gold_out[i] = in_data[i-11] + in_data[i-10] + in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0000_1000: begin
            for(integer i = 0; i < 12; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 12; i<ACCUM_SIZE; i = i + 13) begin
                gold_out[i] = in_data[i-12] + 
                                in_data[i-11] + in_data[i-10] + in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0000_0100: begin
            for(integer i = 0; i < 13; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 13; i<ACCUM_SIZE; i = i + 14) begin
                gold_out[i] = in_data[i-13] + in_data[i-12] + 
                                in_data[i-11] + in_data[i-10] + in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0000_0010: begin
            for(integer i = 0; i < 14; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 14; i<ACCUM_SIZE; i = i + 15) begin
                gold_out[i] = in_data[i-14] + in_data[i-13] + in_data[i-12] + 
                                in_data[i-11] + in_data[i-10] + in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end

        15'b000_0000_0000_0001: begin
            for(integer i = 0; i < 15; i = i + 1) begin
                @(posedge accum_clk);
                #1;
            end
            for(integer i = 15; i<ACCUM_SIZE; i = i + 16) begin
                gold_out[i] = in_data[i-15] + 
                                in_data[i-14] + in_data[i-13] + in_data[i-12] + 
                                in_data[i-11] + in_data[i-10] + in_data[i-9] + 
                                in_data[i-8] + in_data[i-7] + in_data[i-6] + 
                                in_data[i-5] + in_data[i-4] + in_data[i-3] +
                                in_data[i-2] + in_data[i-1] + in_data[i];
                if(accum_out_data[i] == gold_out[i]) begin
                    $display("TRUE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                       | C_gold[%0d] = %0d", i, gold_out[i]);
                end
                else begin
                    $display("FALSE | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
                    $display("                        | C_gold[%0d] = %0d", i, gold_out[i]);
                end
            end
        end
        default: begin
            $display("INCORRECT SETTINGS");
        end
    endcase

    $display("========================================");
    $display("---------accum_out_data_static_test END--------");
    $display("");

end
endtask

//data generation
initial begin
    while (1) begin
        @(posedge accum_clk);
        #1;

        for(integer i = 0; i < ACCUM_SIZE; i++) begin
            data[i] = $urandom() % 10;
        end        
    end
end

task accum_out_data_dinamic_test(
    input logic [2:ACCUM_SIZE-1] adder_chain_set,
    input logic [1:ACCUM_SIZE-1] out_data_mux,
    input data_type in_data [0:ACCUM_SIZE-1],
    input integer cycles_num
);
begin
    data_type gold_out [0:ACCUM_SIZE-1];

    @(posedge accum_clk);
    #1;
    accum_adder_chain_set = adder_chain_set;
    accum_out_data_mux = out_data_mux;
    
    $display("");
    $display("-------accum_out_data_dinamic_test START--------");
    $display("========================================");
    $display("adder_chain_set = %b", adder_chain_set);
    $display("out_data_mux = %b", out_data_mux);
    $display("========================================");

    for(integer n=0; n<cycles_num; n++) begin
        
        accum_in_data = in_data;

        $write("in_data = { ");
        for(integer i = 0; i<ACCUM_SIZE; i = i + 1) begin
            $write("%0d ", in_data[i]);
        end
        $display("}");

        for(integer i = 0; i<ACCUM_SIZE; i = i + 1) begin
            $display(" | [%0t] Accum_out | C[%0d] = %0d", $time, i, accum_out_data[i]);
        end

        @(posedge accum_clk);
        #1;

        for(integer i = 0; i<ACCUM_SIZE; i = i + 1) begin
            in_data[i] = in_data[i] + n;
        end
    end

    $display("========================================");
    $display("---------accum_out_data_dinamic_test END--------");
    $display("");
end
endtask

initial begin : main
    $timeformat(-9, 0, "ns");

    accum_adder_chain_set = 14'b11_1111_1111_1111;
    accum_out_data_mux = 15'b111_1111_1111_1111;
    
    for(integer i=0; i<ACCUM_SIZE; i++) begin
        data[i] = 0;
    end
    
    @(negedge accum_rst);
    
    
    @(posedge accum_clk);
    // accum_out_data_static_test(14'b00_0000_0000_0000, 15'b000_0000_0000_0000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b00_0000_0000_0000, 15'b101_0101_0101_0101, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b10_0100_1001_0010, 15'b010_0100_1001_0010, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_0011_0011_0011, 15'b001_0001_0001_0001, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1001_1100_1110, 15'b000_1000_0100_0010, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1100_1111_0011, 15'b000_0100_0001_0000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1110_0111_1100, 15'b000_0010_0000_0100, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_0011_1111, 15'b000_0001_0000_0001, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1001_1111, 15'b000_0000_1000_0000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1100_1111, 15'b000_0000_0100_0000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1110_0111, 15'b000_0000_0010_0000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1111_0011, 15'b000_0000_0001_0000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1111_1001, 15'b000_0000_0000_1000, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1111_1100, 15'b000_0000_0000_0100, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1111_1110, 15'b000_0000_0000_0010, data);
    
    // @(posedge accum_clk);
    // accum_out_data_static_test(14'b11_1111_1111_1111, 15'b000_0000_0000_0001, data);

    accum_out_data_dinamic_test(14'b10_0100_1001_0010, 15'b010_0100_1001_0010, data, 10);

    @(posedge accum_clk);
    @(posedge accum_clk);
    $finish;
end

endmodule
