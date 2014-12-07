module top (
	input logic clk,    // Clock from FPGA
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	output logic[7:0] leds,
	output logic everyoneInStandby,
	output logic xcorrInStandby, samplerInStandby, argmaxInStandby,
	output logic pingpongState0, pingpongState1,
	input logic rst
	);
	
logic[7:0] ch0, ch1, ch2, ch3, q;
logic[8:0] w_addr = 9'b0;
logic wren;

assign everyoneInStandby = xcorrInStandby & samplerInStandby & argmaxInStandby;
		

adc8x512 sampler(
	.clk(clk),
	.chnl(chnl), // Channel selector to ADC
	.n_convst(n_convst), // (ON low) Start conversion on ADC
	.n_eoc(n_eoc), // (ON low) Input signal indicating EOC from ADC
	.n_cs(n_cs), // (ON low) chip select to ADC
	.n_rd(n_rd), // (ON low) initiate a read on ADC
	.adc_in(adc_in), // data bits from the ADC
	
	.rst(everyoneInStandby | rst),
	.inStandby(samplerInStandby), 
	.w_addr(w_addr), // write address
	.wren(wren), // write enabled
	.ch0(ch0), 
	.ch1(ch1), 
	.ch2(ch2), 
	.ch3(ch3) 
);

// logic for xcorr
logic[8:0] a_addr, b_addr;
logic[7:0] s_addr;	
logic[7:0] a_data, b_data;
logic[23:0] s_data;
logic s_wren;


xcorr #(9, 8, 8) xcorr_inst (
	.clk(clk),
	.rst(everyoneInStandby | rst), 
		
	.a_data(a_data), 
	.a_addr(a_addr), 
	
	.b_addr(b_addr),
	.b_data(b_data),
	
	.s_addr(s_addr),
	.s_data(s_data),
	.s_wren(s_wren),
	
	.inStandby(xcorrInStandby)
	);

logic argmaxStart;
logic [7:0] argmax_addr, max_addr_result;
logic [31:0] argmax_data, max_data_result;
logic argmaxFinished;

argmax #(32,8) argmax_inst (	
	.clk(clk), 
	.rst(everyoneInStandby | rst),
	
	.dataAddr(argmax_addr),
	.data(argmax_data),
	.max(max_data_result),
	.maxIndex(max_addr_result),
	
	.inStandby(argmaxInStandby)
);

pingpong8x512 pingpong0(
	.clk(clk),
	.r_addr(a_addr), // read address
	.r_q(a_data), // read data

	.w_addr(w_addr), // write address
	.w_data(ch0), // write data
	.wren(wren), // write enabled
	.myState(pingpongState0),
	.timeToSwitch(everyoneInStandby) // high when reader and writer are good to go
);

pingpong8x512 pingpong1(
	.clk(clk),
	.r_addr(b_addr), // read address
	.r_q(b_data), // read data

	.w_addr(w_addr), // write address
	.w_data(ch1), // write data
	.wren(wren), // write enabled
	.myState(pingpongState1),
	.timeToSwitch(everyoneInStandby) // high when reader and writer are good to go
);

pingpong32x256 pingpong_x0(
	.clk(clk),
	.r_addr(argmax_addr), // read address
	.r_q(argmax_data), // read data

	.w_addr(s_addr), // write address
	.w_data({{8{s_data[23]}}, s_data}), // write data
	.wren(s_wren), // write enabled
	
	.timeToSwitch(everyoneInStandby) // high when reader and writer are good to go
);

logic [7:0] argmaxram_addr;

ram8x512 argmaxram0_addr(
	.address(argmaxram_addr),
	.clock(everyoneInStandby),
	.data(max_addr_result),
	.wren(1'b1),
	.q() 
);

ram32x256 argmaxram0_data(
	.address(argmaxram_addr),
	.clock(everyoneInStandby),
	.data(max_data_result),
	.wren(1'b1),
	.q() 
);


always_ff @(posedge everyoneInStandby)
	argmaxram_addr <= argmaxram_addr + 1;

// assign LEDS
assign leds[0] = everyoneInStandby;

assign leds[1] = ^ch2 & ^ch3; // to prevent quartus from being too smart

assign leds[4:2] = max_addr_result[2:0];

assign leds[7:5] = ch0[7:5];



endmodule
