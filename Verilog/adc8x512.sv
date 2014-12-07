module adc8x512(
	input logic clk,
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	
	input  logic start,
	output logic doneWriting,    // held high while no more writes are needed
	output logic [8:0] w_addr, // write address
	output logic wren, // write enabled
	output logic [7:0] ch0, ch1, ch2, ch3 // 
);

logic newSample; // clock running at overall sampling rate

adc_sampler sampler(
	.clk(clk), 
	.chnl(chnl), 
	.n_convst(n_convst),	
	.n_eoc(n_eoc), 
	.n_cs(n_cs), 
	.n_rd(n_rd), 
	.adc_in(adc_in), 
	.ch0(ch0), 
	.ch1(ch1), 
	.ch2(ch2), 
	.ch3(ch3), 
	.newSample(newSample)
);

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
			next_state = (w_addr == {9{1'b1}}) ? DONE : COMPUTE;
		DONE:
			next_state = (start) ? DONE : WAIT_TO_START;
	endcase
end

/*
always_ff @(posedge clk) begin
	case (state)
		WAIT_TO_START:
			doneWriting <= 1'b0;
		COMPUTE:
			doneWriting <= 1'b0;
		DONE:
			doneWriting <= 1'b1;
	endcase
end
*/

// COMPUTING LOGIC
always_ff @(posedge newSample) begin
	if (state == COMPUTE)
		w_addr <= w_addr + 1; // increment address
	if (state == DONE)
		w_addr <= 0;
end

assign wren = (state == COMPUTE);
assign doneWriting = (state == DONE);

endmodule
