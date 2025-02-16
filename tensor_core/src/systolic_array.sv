`ifndef VIVADO_PRJ_USE
    `include "types.vh"
`endif
import types::*;

module systolic_array
	#(  parameter ACTIVATION_COUNT = 16
		, parameter WEIGHT_COUNT = 16)
	(
		input clk_i
		, input rst_i
		, input weight_update_i

		, input data_type activation_i [0:ACTIVATION_COUNT-1]
		, input data_type weight_i [0:WEIGHT_COUNT-1]

		, output data_type result_o [0:WEIGHT_COUNT-1]
	);
    
    /*
    AC = ACTIVATION_COUNT
    WC = WEIGHT_COUNT
    
    	    \/  \/  \/  \/  \/  \/
    		0	1	2	3	4	AC
	-> 	0							0	-> 	
	-> 	1							1	-> 	
	-> 	2							2	-> 	
	-> 	3							3	-> 	
	-> 	4							4	-> 	
	-> 	WC							WC	-> 	
    
    */
    
    //The systolic array states
    localparam DATA_FILL = 2'b0; // filling the systolic array with data (weights)
    localparam CALCULATION = 2'b1; // pass data through the systolic array and calculation
   
    reg state, next_state;
    
    data_type mac_res [0:WEIGHT_COUNT-1][0:ACTIVATION_COUNT-1];
    data_type weight_reg [0:WEIGHT_COUNT-1][0:ACTIVATION_COUNT-1];
    data_type activation_reg [0:WEIGHT_COUNT-1][0:ACTIVATION_COUNT-1];
    
    genvar result_iterator;
    generate
        for(result_iterator=0; result_iterator<WEIGHT_COUNT; result_iterator++) begin
            assign result_o[result_iterator] = mac_res[result_iterator][ACTIVATION_COUNT-1];
        end
    endgenerate
    
    always @ (posedge clk_i) begin
        if (rst_i) begin
            state <= CALCULATION;
        end
        else begin
            state <= next_state;
        end
    end 
    
    always_comb begin
        case (state)
            DATA_FILL: begin
                if(weight_update_i) next_state = DATA_FILL;
                else next_state = CALCULATION;
            end
            CALCULATION: begin
                if(weight_update_i) next_state = DATA_FILL;
                else next_state = CALCULATION;
            end
            default: next_state = CALCULATION;
        endcase
    end   
    
    // Calculation logic
    always@(posedge clk_i)
        if (rst_i) begin
            for(integer y=0; y<WEIGHT_COUNT; y++) begin
                for(integer x=0; x<ACTIVATION_COUNT; x++) begin
                    weight_reg[y][x] <= 0;
                    activation_reg[y][x] <= 0;
                    mac_res[y][x] <= 0;
                end
            end
        end
        else begin
            case (state)
            DATA_FILL: begin
                if(weight_update_i) begin
                    //feeding weights to an systolic array
                    for(integer y=0; y<WEIGHT_COUNT; y++) weight_reg[y][0] <= weight_i[y];
                    
                    //shifting weights into the depth of the the systolic array
                    for(integer x=1; x<ACTIVATION_COUNT; x++) begin
                        for(integer y=0; y<WEIGHT_COUNT; y++) begin
                            weight_reg[y][x] <= weight_reg[y][x-1];
                        end
                    end
                end
                else begin
                    for(integer x=0; x<ACTIVATION_COUNT; x++) activation_reg[0][x] <= activation_i[x];
                end
            end
            CALCULATION: begin
                if(weight_update_i) begin
                    for(integer y=0; y<WEIGHT_COUNT; y++) weight_reg[y][0] <= weight_i[y];
                end
                else begin
                    //pass activations through the systolic array
                    //feeding activations to an systolic array
                    for(integer x=0; x<ACTIVATION_COUNT; x++) activation_reg[0][x] <= activation_i[x];
                    
                    //shifting activations into the depth of the the systolic array
                    for(integer y=1; y<WEIGHT_COUNT; y++) begin
                        for(integer x=0; x<ACTIVATION_COUNT; x++) begin
                            activation_reg[y][x] <= activation_reg[y-1][x];
                        end
                    end
                    
                    //calculation of matrix multiplication
                    for(integer y=0; y<WEIGHT_COUNT; y++) mac_res[y][0] <= weight_reg[y][0]*activation_reg[y][0];
                    
                    for(integer x=1; x<ACTIVATION_COUNT; x++) begin
                        for(integer y=0; y<WEIGHT_COUNT; y++) begin
                            mac_res[y][x] <= (weight_reg[y][x] * activation_reg[y][x]) + mac_res[y][x-1];
                        end
                    end
                end
            end
        endcase
        end
    
endmodule
