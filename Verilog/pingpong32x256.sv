module pingpong32x256 (
	input logic clk,
	
	input logic [7:0] r_addr, // read address
	output logic [31:0] r_q, // read data
	
	input logic [7:0] w_addr, // write address
	input logic [31:0] w_data, // write data
	input logic wren, // write enabled
	
	input logic timeToSwitch // controller sends when buffers need to switch
);

typedef enum logic {
	RA_WB,
	RB_WA
} state_t;

state_t state = RA_WB; 
state_t next_state;

always_ff @(posedge timeToSwitch) begin 
	state <= next_state;
end

always_comb
	case (state)
		RA_WB:
			next_state = RB_WA;
		RB_WA:
			next_state = RA_WB;
	endcase

logic [7:0] addr_a, addr_b;
logic [31:0] data_a, data_b;
logic [31:0] q_a, q_b;
logic wren_a, wren_b;

ram32x256 buffer_a(
	.address(addr_a),
	.clock(clk),
	.data(data_a),
	.wren(wren_a),
	.q(q_a) 
);

ram32x256 buffer_b(
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
		end
		RB_WA: begin
			addr_a = w_addr;
			data_a = w_data;
			wren_a = wren;
			
			addr_b = r_addr;
			data_b = 8'b0;
			wren_b = 1'b0;
			r_q = q_b;
		end
	endcase


endmodule
