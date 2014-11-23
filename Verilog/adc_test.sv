module adc_test (input logic clk,    // Clock from FPGA
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	output logic[7:0] leds,
	output logic newSample);
	
logic[7:0] ch0, ch1, ch2, ch3;

adc_sampler sampler(clk, chnl, n_convst, n_eoc, n_cs, n_rd, adc_in, ch0, ch1, ch2, ch3, newSample);

assign leds = ch0;

endmodule
