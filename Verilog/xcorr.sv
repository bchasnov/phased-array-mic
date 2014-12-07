module xcorr #(parameter ADDR_WIDTH = 9, DATA_WIDTH = 8, OUT_ADDR_WIDTH = 8) (
	input logic clk, // system clk
	input logic rst, // (re)start the xconv process

	// read access to signal a and b
	output logic [ADDR_WIDTH-1:0] a_addr, b_addr,
	input logic [DATA_WIDTH-1:0] a_data, b_data,
	
	// write access to output signal
	output logic [OUT_ADDR_WIDTH-1:0] s_addr,
	output logic [2*DATA_WIDTH+OUT_ADDR_WIDTH-1:0] s_data,
	output logic s_wren,
	
	output logic inStandby
	);

// internal indices
logic unsigned [OUT_ADDR_WIDTH-1:0] n; // offset, goes from 0 to 255 by default
logic unsigned [OUT_ADDR_WIDTH-1:0] i; // position in multiplication

// register to hold the current product
logic signed [2*DATA_WIDTH-1:0] product;

// register to hold the running sum
logic signed [2*DATA_WIDTH+OUT_ADDR_WIDTH-1:0] result;


// state info
typedef enum logic[1:0] {
	START,
	INCREMENT_N,
	INCREMENT_I,
	STANDBY
	} state_t;

state_t state = START;
state_t next_state;

// STATE LOGIC
always_ff @(posedge clk) begin
	if (rst) // sync reset
		state <= START;
	else
		state <= next_state;
end

// state transitions
always_comb begin
	case (state)
		START:
			next_state = INCREMENT_N;
		INCREMENT_N: 
			next_state = (n == {OUT_ADDR_WIDTH{1'b1}}) ? STANDBY : INCREMENT_I;
		INCREMENT_I:
			next_state = (i == {OUT_ADDR_WIDTH{1'b1}}) ? INCREMENT_N : INCREMENT_I;
		STANDBY:
			next_state = STANDBY;
	endcase
end

assign a_addr = n+i;
assign b_addr = ({1'b1,{OUT_ADDR_WIDTH{1'b0}}} - n) + i;

mult8x8 mymult(a_data, b_data, product);

// COMPUTING LOGIC
always_ff @(posedge clk) begin
	if (state == START) begin
		n <= 0; // reset both loop counters
		i <= 0;
	end
	if (state == INCREMENT_N) begin
		result <= 0; // reset result
		i <= 0; // reset inner loop counter
		n <= n + 1; // increment n
	end
	if (state == INCREMENT_I) begin
		result <= result + product; 
		i <= i + 1; // increment i
	end
end


// write the top bits of result to output, only during the compute stage
assign s_addr = n; // we always compute the nth term in the output signal
assign s_data = result;
assign s_wren = (state == INCREMENT_I);
assign inStandby = (state == STANDBY);
	
endmodule
