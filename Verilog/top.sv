module top (
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
assign leds[7:4] = ch0[7:4];

logic goodToGo0, goodToGo1;
logic goodToGo;
logic doneWriting;
logic doneReading;

assign leds[0] = goodToGo;

assign goodToGo = goodToGo0 & goodToGo1;
		

adc8x512 sampler(
	.clk(clk),
	.chnl(chnl), // Channel selector to ADC
	.n_convst(n_convst), // (ON low) Start conversion on ADC
	.n_eoc(n_eoc), // (ON low) Input signal indicating EOC from ADC
	.n_cs(n_cs), // (ON low) chip select to ADC
	.n_rd(n_rd), // (ON low) initiate a read on ADC
	.adc_in(adc_in), // data bits from the ADC
	
	.start(goodToGo | start),
	.doneWriting(doneWriting),    // held high while no more writes are needed
	.w_addr(w_addr), // write address
	.wren(wren), // write enabled
	.ch0(ch0), 
	.ch1(ch1), 
	.ch2(ch2), 
	.ch3(ch3) // 
);

// logic for xcorr
logic[8:0] a_addr, b_addr;
logic[7:0] s_addr;	
logic[7:0] a_data, b_data, s_data;
logic s_wren;

xcorr #(9, 8, 8) xcorr_inst (
	.clk(clk),
	.start(goodToGo), 
	.a_addr(a_addr), 
	.b_addr(b_addr),
	.a_data(a_data), 
	.b_data(b_data),
	.s_addr(s_addr),
	.s_data(s_data),
	.s_wren(s_wren),
	.valid(doneReading)
	);

//assign b_addr = a_addr;
//assign b_data = a_data;
	
pingpong8x512 pingpong0(
	.clk(clk),
	.r_addr(a_addr), // read address
	.r_q(a_data), // read data
	.readDone(doneReading), // held high while no more reads are needed
	.w_addr(w_addr), // write address
	.w_data(ch0), // write data
	.wren(wren), // write enabled
   .writeDone(doneWriting),// held high while no more writes are needed
	.goodToGo(goodToGo0) // high when reader and writer are good to go
);

pingpong8x512 pingpong1(
	.clk(clk),
	.r_addr(b_addr), // read address
	.r_q(b_data), // read data
	.readDone(doneReading), // held high while no more reads are needed
	.w_addr(w_addr), // write address
	.w_data(ch1), // write data
	.wren(wren), // write enabled
   .writeDone(doneWriting),// held high while no more writes are needed
	.goodToGo(goodToGo1) // high when reader and writer are good to go
);

assign leds[1] = ^ch2 & ^ch3; // to prevent quartus from being too smart

assign leds[2] = doneWriting;
assign leds[3] = doneReading; 

ram8x512 buffer_b(
	.address(s_addr),
	.clock(clk),
	.data(s_data),
	.wren(s_wren),
	.q() 
);

endmodule































/*

module top(
	input logic clk, // system clock
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	input logic sck, sdi, output logic sdo, // spi slave connection
	output logic[7:0] leds // led output for debugging
	);

// logic from sampler:
logic[7:0] mic0,mic1,mic2,mic3;
logic sampleReady;
	
adc_sampler sampler(
	.clk(clk), 
	.chnl(chnl), 
	.n_convst(n_convst),	
	.n_eoc(n_eoc), 
	.n_cs(n_cs), 
	.n_rd(n_rd), 
	.adc_in(adc_in), 
	.ch0(mic0), 
	.ch1(mic1), 
	.ch2(mic2), 
	.ch3(mic3), 
	.newSample(sampleReady)
	);

// logic for xcorr
logic xcorrStart;
logic[8:0] a_addr, b_addr;
logic[7:0] s_addr;	
logic[7:0] a_data, b_data, s_data;
logic xcorrFinished;

xcorr #(9, 8, 8) xcorr_inst (
	.clk(clk),
	.start(xcorrStart), 
	.a_addr(a_addr), 
	.b_addr(b_addr),
	.a_data(a_data), 
	.b_data(b_data),
	.s_addr(s_addr),
	.s_data(s_data),
	.s_wren(s_wren),
	.valid(xcorrFinished)
	);


// logic for argmax_inst
logic argmaxStart;
logic [8:0] xcorr_addr, max_addr;
logic [16:0] xcorr_data, max;
logic argmaxFinished;
	
argmax #(8,9) argmax_inst (
	.clk(clk), 
	.start(argmaxStart),
	.dataAddr(addr),
	.data(qa),
	.max(max),
	.maxIndex(maxaddr),
	.valid(argmaxFinished)
	);

	
endmodule */
