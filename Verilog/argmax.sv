// Apoorva Sharma and ben chasnov. 12/2014
// argmax computes the maximum and the index of the maximum element in a 
// RAM with 2^ADDR_WIDTH entries of width DATA_WIDTH. It assumes the RAM
// reads on the posedge of clk. 
module argmax #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 12) ( 
					input logic clk, // system clock
					input logic start, // pulse high to start computation
					output logic[ADDR_WIDTH-1:0] dataAddr, // address to RAM
					input logic[DATA_WIDTH-1:0] data, // data from RAM
					output logic[DATA_WIDTH-1:0] max, // max value in RAM
					output logic[ADDR_WIDTH-1:0] maxIndex, // address of max value in RAM
					output logic valid // high when max and maxIndex are valid
					);
	
// INTENRAL LOGIC
// ram indices
logic [ADDR_WIDTH-1:0] i = 0;
assign dataAddr = i;
/*
// running maximi and argmaximi
logic [DATA_WIDTH-1:0] max1,max2,max3,max4, max12, max34;
logic [ADDR_WIDTH-1:0] argmax1,argmax2,argmax3,argmax4, argmax12, argmax34;
*/

// state info
typedef enum logic[1:0] {
	WAIT_TO_START,
	COMPUTE,
	DONE
	} state_t;

state_t state = WAIT_TO_START;
state_t next_state;

// STATE LOGIC
always_ff @(negedge clk) begin
	state <= next_state;
end

// state transitions
always_comb begin
	case (state)
		WAIT_TO_START:
			next_state = (start) ? COMPUTE : WAIT_TO_START;
		COMPUTE:
			next_state = (i == 0) ? DONE : COMPUTE;
		DONE:
			next_state = WAIT_TO_START;
	endcase
end

// COMPUTING LOGIC
always_ff @(posedge clk) begin
	if (state == COMPUTE) begin
		valid <= 1'b0;
		if (data > max) begin
			max <= data;
			maxIndex <= i;
		end
		i <= i + 1;
	end
	if (state == DONE) begin
		valid <= 1'b1;
	end
end

endmodule		
