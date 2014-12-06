module adc_test_nooverlap (
	input logic clk,    // Clock from FPGA
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	output logic[7:0] leds,
	input logic start
	);
	
logic[7:0] ch0, ch1, ch2, ch3, q;
logic[8:0] w_addr = 9'b0;
logic wren;
assign leds[7:2] = ch0[7:2];

adc8x512 sampler(
	.clk(clk),
	.chnl(chnl), // Channel selector to ADC
	.n_convst(n_convst), // (ON low) Start conversion on ADC
	.n_eoc(n_eoc), // (ON low) Input signal indicating EOC from ADC
	.n_cs(n_cs), // (ON low) chip select to ADC
	.n_rd(n_rd), // (ON low) initiate a read on ADC
	.adc_in(adc_in), // data bits from the ADC
	
	.start(start),
	.doneWriting(leds[0]),    // held high while no more writes are needed
	.w_addr(w_addr), // write address
	.wren(wren), // write enabled
	.ch0(ch0), 
	.ch1(ch1), 
	.ch2(ch2), 
	.ch3(ch3) // 
);


ram8x512 ramch0(
	.address(w_addr),
	.clock(clk),
	.data(ch0),
	.wren(wren),
	.q(q) 
);

ram8x512 ramch1(
	.address(w_addr),
	.clock(clk),
	.data(ch1),
	.wren(wren),
	.q() 
);


endmodule
