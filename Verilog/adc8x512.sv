module adc8x512(
	input logic clk,
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	
	input  logic rst, // (re)start the sampling
	output logic inStandby,   // held high while no more writes are needed
	
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
			next_state = (w_addr == {9{1'b1}}) ? STANDBY : COMPUTE;
		STANDBY:
			next_state = STANDBY;
	endcase
end

// COMPUTING LOGIC
always_ff @(negedge clk) begin
	if (state == START)
		w_addr <= 0;
	// newSample lasts only for 1 clock cycle, we sample on the negedge of that cycle
	if ((state == COMPUTE) && newSample) 
		w_addr <= w_addr + 1; // increment address
end

assign wren = (state == COMPUTE);
assign inStandby = (state == STANDBY);

endmodule
