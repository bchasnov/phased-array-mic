module pingpong8x512 (
	input logic clk,
	input logic [8:0] r_addr, // read address
	output logic [7:0] r_q, // read data
	input logic readDone, // held high while no more reads are needed
	input logic [8:0] w_addr, // write address
	input logic [7:0] w_data, // write data
	input logic wren, // write enabled
   input logic writeDone,// held high while no more writes are needed
	output logic goodToGo // high when reader and writer are good to go
);

logic timeToSwitch;
assign timeToSwitch = readDone & writeDone;

typedef enum logic[1:0] {
	RA_WB = 2'b00,
	SWITCH1 = 2'b01, 
	RB_WA = 2'b10,
	SWITCH2 = 2'b11
	} state_t;
	
state_t state = SWITCH2; // which buffer is the read buffer
state_t next_state;
always_ff @(posedge clk) begin // maybe use clk?
	state <= next_state;
end

always_comb
	case (state)
		RA_WB:
			next_state = timeToSwitch ? SWITCH1 : RA_WB;
		SWITCH1:
			next_state = RB_WA;
		RB_WA:
			next_state = timeToSwitch ? SWITCH2 : RB_WA;
		SWITCH2:
			next_state = RA_WB;
	endcase

logic [8:0] addr_a, addr_b;
logic [7:0] data_a, data_b;
logic [7:0] q_a, q_b;
logic wren_a, wren_b;

ram8x512 buffer_a(
	.address(addr_a),
	.clock(clk),
	.data(data_a),
	.wren(wren_a),
	.q(q_a) 
);

ram8x512 buffer_b(
	.address(addr_b),
	.clock(clk),
	.data(data_b),
	.wren(wren_b),
	.q(q_b) 
);

// OUTPUT LOGIC
always_comb 
	case (state)
		RA_WB: begin
			addr_b = w_addr;
			data_b = w_data;
			wren_b = wren;
			addr_a = r_addr;
			data_a = 8'b0;
			wren_a = 1'b0;
			r_q = q_a;
			goodToGo = 1'b1;
		end
		SWITCH1: begin // same as RA_WB with goodToGo on
			addr_a = w_addr;
			data_a = w_data;
			wren_a = wren;
			addr_b = r_addr;
			data_b = 8'b0;
			wren_b = 1'b0;
			r_q = q_b;
			goodToGo = 1'b0;
		end
		RB_WA: begin
			addr_a = w_addr;
			data_a = w_data;
			wren_a = wren;
			addr_b = r_addr;
			data_b = 8'b0;
			wren_b = 1'b0;
			r_q = q_b;
			goodToGo = 1'b1;
		end
		SWITCH2: begin // same as RB_WA with goodToGo on
			addr_b = w_addr;
			data_b = w_data;
			wren_b = wren;
			addr_a = r_addr;
			data_a = 8'b0;
			wren_a = 1'b0;
			r_q = q_a;
			goodToGo = 1'b0;
		end
	endcase


endmodule
