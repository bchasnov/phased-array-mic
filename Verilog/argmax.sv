

module argmax #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 12) ( 
					input logic clk, // system clock
					input logic start, // pulse high to start computation
					output logic[ADDR_WIDTH-1:0] dataAddr, // address to RAM
					input logic[DATA_WIDTH-1:0] data, // data from RAM
					output logic[DATA_WIDTH-1:0] max, // max value in RAM
					output logic[ADDR_WIDTH-1:0] maxIndex, // address of max value in RAM
					output logic done
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
always_ff @(posedge clk) begin
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
		done <= 1'b0;
		i <= i + 1;
		if (data > max) begin
			max <= data;
			maxIndex <= i;
		end
	end
	if (state == DONE) begin
		done <= 1'b1;
	end
end

// AGGREGATING RESULTS
//argmax4 #(DATA_WIDTH,ADDR_WIDTH) aggregator(max1,max2,max3,max4, argmax1,argmax2,argmax3,argmax4, max,argmax);

endmodule		
	
module argmax4  #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 12) (
	input logic[DATA_WIDTH-1:0] m1,m2,m3,m4,
	input logic[ADDR_WIDTH-1:0] a1,a2,a3,a4,
	output logic[DATA_WIDTH-1:0] max,
	output logic[ADDR_WIDTH-1:0] argmax);
	
logic[DATA_WIDTH-1:0] max12,max34;
logic[ADDR_WIDTH-1:0] argmax12, argmax34;
	
always_comb begin
	if (m1 > m2) begin
		max12 = m1;
		argmax12 = a1;
	end else begin
		max12 = m2;
		max12 = a2;
	end
	
	if (m3 > m4) begin
		max34 = m3;
		argmax34 = a3;
	end else begin
		max34 = m4;
		argmax34 = a4;
	end
	
	if (max12 > max34) begin
		max = max12;
		argmax = argmax12;
	end else begin
		max = max34;
		argmax = argmax34;
	end
end 

endmodule
