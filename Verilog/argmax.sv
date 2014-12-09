// Apoorva Sharma and ben chasnov. 12/2014
// argmax computes the maximum and the index of the maximum element in a 
// RAM with 2^ADDR_WIDTH entries of width DATA_WIDTH. It assumes the RAM
// reads on the posedge of clk. 
module argmax #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 8) ( 
		input logic clk, // system clock
		
		input logic rst,
		output logic inStandby,   // held high while no more writes are needed
		
		output logic[ADDR_WIDTH-1:0] dataAddr, // address to RAM
		input  logic signed [DATA_WIDTH-1:0]  data, // data from RAM
		output logic signed [DATA_WIDTH-1:0] max, // max value in RAM
		output logic[ADDR_WIDTH-1:0] maxIndex // address of max value in RAM
);
	
// INTENRAL LOGIC
// ram indices
logic [ADDR_WIDTH-1:0] lastAddr;

// state info
typedef enum logic[1:0] {
	START,
	COMPUTE,
	STANDBY
	} state_t;

state_t state = START;
state_t next_state;

// STATE LOGIC
always_ff @(posedge clk) begin
	if (rst)
		state <= START;
	else
		state <= next_state;
end

// state transitions
always_comb begin
	case (state)
		START:
			next_state = COMPUTE;
		COMPUTE:
			// end checking at n = 205
			next_state = (dataAddr == {{(ADDR_WIDTH-8){1'b0}}, 8'd168}) ? STANDBY : COMPUTE; // used to be {ADDR_WIDTH{1'b1}}
		STANDBY:
			next_state = STANDBY;
	endcase
end

// COMPUTING LOGIC
always_ff @(posedge clk) begin
	if (state == COMPUTE) begin
		if (data > max) begin
			max <= data;
			maxIndex <= lastAddr;
		end
		dataAddr <= dataAddr + 1; // increment address
		lastAddr <= dataAddr;
	end
	if (state == START) begin
		dataAddr <= {{(ADDR_WIDTH-8){1'b0}}, 8'd88};// start checking at n = 88
		max <= {1'b1, {(DATA_WIDTH-1){1'b0}}};
		maxIndex <= 0;
	end
end

assign inStandby = (state==STANDBY);

endmodule		
