//   config     |   adder_chain_set_i   |     out_data_mux_i    |   description
//--------------|-----------------------|-----------------------|-----------------------
//    0 		|	00_0000_0000_0000	|	 000_0000_0000_0000	| every output is used
//    1 		|	00_0000_0000_0000	|	 101_0101_0101_0101	| every second output is used
//    2 		|	10_0100_1001_0010	|	 010_0100_1001_0010	| every third output is used
//    3 		|	11_0011_0011_0011	|	 001_0001_0001_0001	| every fourth output is used
//    4 		|	11_1001_1100_1110	|	 000_1000_0100_0010	| every fifth output is used
//    5 		|	11_1100_1111_0011	|	 000_0100_0001_0000	| every sixth output is used
//    6 		|	11_1110_0111_1100	|	 000_0010_0000_0100	| every seventh output is used
//    7 		|	11_1111_0011_1111	|	 000_0001_0000_0001	| every eighth output is used
//    8 		|	11_1111_1001_1111	|	 000_0000_1000_0000	| every ninth output is used
//    9 		|	11_1111_1100_1111	|	 000_0000_0100_0000	| every tenth output is used
//    10 		|	11_1111_1110_0111	|	 000_0000_0010_0000	| every eleventh output is used
//    11		|	11_1111_1111_0011	|	 000_0000_0001_0000	| every twelfth output is used
//    12		|	11_1111_1111_1001	|	 000_0000_0000_1000	| every thirteenth output is used
//    13		|	11_1111_1111_1100	|	 000_0000_0000_0100	| every fourteenth output is used
//    14		|	11_1111_1111_1110	|	 000_0000_0000_0010	| every fifteenth output is used
//    15		|	11_1111_1111_1111	|	 000_0000_0000_0001	| every sixteenth output is used

`ifndef VIVADO_PRJ_USE
`include "types.vh"
`endif
import types::*;

module accumulators #(
        parameter IN_SIZE = 16
        
    )(
        input clk_i
        , input rst_i
       
        , input data_type data_i [0:IN_SIZE-1]
        
        , input [2:IN_SIZE-1] adder_chain_set_i
        , input [1:IN_SIZE-1] out_data_mux_i
        
        , output data_type data_o [0:IN_SIZE-1]
    );
       
    data_type in_data_buf [0:IN_SIZE-1][2:0];
    data_type accumulation_reg [1:IN_SIZE-1];
    data_type accumulation_reg_buf [1:IN_SIZE-1];
    
    data_type adder_op1 [1:IN_SIZE-1];
    data_type adder_op2 [1:IN_SIZE-1];
    
    always@(posedge clk_i) begin: input_buf
        if(rst_i) begin
            for (integer i=0; i<IN_SIZE; i++) begin
                in_data_buf[i][0] <= 0;
                in_data_buf[i][1] <= 0;
            end
        end
        else begin
            for (integer i=0; i<IN_SIZE; i++) begin
                in_data_buf[i][0] <= data_i[i];
                in_data_buf[i][1] <= in_data_buf[i][0];
            end
        end
    end
    
    always_comb begin: adder_chain_mux
        adder_op1[1] = in_data_buf[0][1];
        adder_op2[1] = data_i[1];
        // adder_op2[1] = in_data_buf[1];
        for (integer i=2; i<IN_SIZE; i++) begin
            adder_op1[i] = adder_chain_set_i[i] ? accumulation_reg_buf[i-1] : in_data_buf[i-1][1];
            // adder_op2[i] = in_data_buf[i];
            adder_op2[i] = data_i[i];
        end
    end
    
    always@ (posedge clk_i) begin: adders
        if (rst_i) begin
            for (integer i=1; i<IN_SIZE; i++) begin
                accumulation_reg[i] <= 0;
                accumulation_reg_buf[i] <= 0;
            end
        end 
        else begin
            for (integer i=1; i<IN_SIZE; i++) begin
                accumulation_reg[i] <= adder_op1[i] + adder_op2[i]; 
                accumulation_reg_buf[i] <= accumulation_reg[i];
            end
        end
    end 
    
    always_comb begin: out_data_mux
        if (out_data_mux_i == 0) begin
            data_o[0] = in_data_buf[0][1];
        end else begin
            data_o[0] = 32'dZ;
        end
        
        for (integer i=1; i<IN_SIZE; i++) begin
            if (out_data_mux_i == 0) begin
                data_o[i] = in_data_buf[i][1];
            end else begin
                data_o[i] = out_data_mux_i[i] ? accumulation_reg[i] : 32'dZ;
            end
        end
    end
    
endmodule
