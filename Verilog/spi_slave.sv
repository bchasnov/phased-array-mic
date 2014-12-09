module spi_slave(input logic sck, // from master 
	input  logic sdo, // from master
	output logic sdi, // to master
	input  logic reset,
	input  logic [63:0] d, // data to send 
	output logic [63:0] q); // data received.. not used

logic [5:0] cnt; //0 - 63
logic qdelayed;

// 6-bit counter tracks when full 8 bytes is transmitted and new d should be sent
always_ff @(negedge sck, posedge reset) 
	if (reset) cnt = 0;
	else cnt = cnt + 6'b1;

// loadable shift register
// loads d at the start, shifts sdo into bottom position on subsequent step 
always_ff @(posedge sck)
	q <= (cnt == 0) ? d : {q[62:0], sdo};

// align sdi to falling edge of sck // load d at the start
always_ff @(negedge sck)
	qdelayed = q[62];

assign sdi = (cnt == 0) ? d[63] : qdelayed;

endmodule
