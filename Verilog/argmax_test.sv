module argmax_test(input logic clk,
			  input logic start,
			  output logic[7:0] maxIndex);

logic[8:0] addr, maxaddr;
logic[7:0] qa, qb;
logic[7:0] max;
logic done;

ram2port ram (
	.address_a(addr),
	.address_b(9'b0),
	.clock(clk),
	.data_a(8'b0),
	.data_b(8'b0),
	.wren_a(1'b0),
	.wren_b(1'b0),
	.q_a(qa),
	.q_b(qb));

argmax #(8,9) argmax_inst(
	.clk(clk), 
	.start(start),
	.dataAddr(addr),
	.data(qa),
	.max(max),
	.maxIndex(maxaddr),
	.valid(done)
	);

assign maxIndex = maxaddr[7:0];	

endmodule
