`ifndef VIVADO_PRJ_USE
`include "types.vh"
`endif

import types::*;

module activation
    #(parameter IN_SIZE = 16)
    (
        input clk_i
        , input rst_i
       
        , input data_type data_i [0:IN_SIZE-1]        
        , output data_type data_o [0:IN_SIZE-1] 
    );
    
    typedef logic signed [`DATA_TYPE_SIZE-1:0] data_type;
    
    always@(posedge clk_i) begin
        if(rst_i) begin
            for(integer i=0; i<IN_SIZE; i++) begin
                data_o[i] <= 0;
            end
        end
        else begin
            for (integer j=0; j<IN_SIZE; j++) begin
                //ReLU                
                data_o[j] <= (data_i[j]<0) ? 0 : data_i[j];
            end
        end
    end
    
endmodule
