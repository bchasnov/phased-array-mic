module xcorr #(parameter ADDR_WIDTH = 9, DATA_WIDTH = 8, OUT_ADDR_WIDTH = 8) (
	input logic clk, // system clk
	input logic start, // start the xconv process
	// read access to signal a and b
	output logic [ADDR_WIDTH-1:0] a_addr, b_addr,
	input logic [DATA_WIDTH-1:0] a_data, b_data,
	
	// write access to output signal
	output logic [OUT_ADDR_WIDTH-1:0] s_addr,
	output logic [DATA_WIDTH-1:0] s_data,
	output logic s_wren,
	
	output logic valid
	);

// internal indices
logic unsigned [OUT_ADDR_WIDTH-1:0] n; // offset, goes from 0 to 255 by default
logic unsigned [OUT_ADDR_WIDTH-1:0] i; // position in multiplication

// register to hold the current product
logic unsigned [2*DATA_WIDTH-1:0] product;

// register to hold the running sum
logic unsigned [2*DATA_WIDTH+OUT_ADDR_WIDTH-1:0] result;


// state info
typedef enum logic[1:0] {
	WAIT_TO_START,
	INCREMENT_N,
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
		INCREMENT_N: 
			next_state = (n == {OUT_ADDR_WIDTH{1'b1}}) ? DONE : COMPUTE;
		COMPUTE:
			next_state = (i == {OUT_ADDR_WIDTH{1'b1}}) ? INCREMENT_N : COMPUTE;
		DONE:
			next_state = (start) ? DONE : WAIT_TO_START;
	endcase
end

assign a_addr = n+i;
assign b_addr = ({1'b1,{OUT_ADDR_WIDTH{1'b0}}} - n) + i;

mult8x8 mymult(a_data, b_data, product);


assign s_addr = n; // we always compute the nth term in the output signal

// COMPUTING LOGIC
always_ff @(negedge clk) begin
	if (state == INCREMENT_N) begin
		//valid <= 1'b0;
		result <= 0; // reset result
		n <= n + 1;
		i <= 0;
	end
	if (state == COMPUTE) begin
		result <= result + product; 
		i <= i + 1;
	end
	if (state == DONE) begin
		//valid <= 1'b1;
		n <= 0;
	end
end


// write the top bits of result to output, only during the compute stage
assign s_data = result[2*DATA_WIDTH+OUT_ADDR_WIDTH-3:DATA_WIDTH+OUT_ADDR_WIDTH-2];
assign s_wren = (state == COMPUTE);
assign valid = (state == DONE);
	
endmodule
