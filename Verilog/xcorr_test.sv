module xconv_test(input logic clk,start, output logic[7:0] leds);
	logic[8:0] a_addr, b_addr;
	logic[7:0] a_data, b_data, s_data;
	logic[7:0] s_addr;
	logic s_wren, done;
	
	ram_1khz ram_a (
		.address(a_addr),
		.clock(clk),
		.data(8'b0),
		.wren(1'b0),
		.q(a_data)
	);
	
	ram_5khz ram_b (
		.address(b_addr),
		.clock(clk),
		.data(8'b0),
		.wren(1'b0),
		.q(b_data)
	);
	
	ram8x256 ram_s (
		.address(s_addr),
		.clock(clk),
		.data(s_data),
		.wren(s_wren),
	);

	
	xcorr #(9, 8, 8) (
		.clk(clk),
		.start(start), 
		.a_addr(a_addr), 
		.b_addr(b_addr),
		.a_data(a_data), 
		.b_data(b_data),
		.s_addr(s_addr),
		.s_data(s_data),
		.s_wren(s_wren),
		.valid(done)
		);
	
	assign leds = s_data;

endmodule
