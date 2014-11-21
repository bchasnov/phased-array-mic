module FFT_controller(
	input                         clk,
	input                         rst,             // reset on falling edge
	input                         start,           // start loading 
	output       [8:0]  inputSampleAddr,  // 0-511
	input signed [7:0]  inputSampleData,  // 0-255
	output                        done,	
);
	
// parameter ADDR_BITS = 9; // 0-511
// parameter DATA_BITS = 8; // 0-255

reg [7:0] sink_real;
reg [3:0] fft_state;

reg sink_eop;
reg sink_sop;

assign sink_imag = 8'b0;   // no input imaginary
assign sink_error = 2'b00; // no input imaginary


// fft conversion states
typedef enum logic[3:0] {
	S_STBY, // standby
	S_SOP,  // start of packet
	S_MID,  // in the middle of packet
	S_EOP   // end of packet
};


always @ (posedge start)
begin
	// do something?
end 



// FFT state machine.
always @ (posedge clk)
begin
	if(~rst) // reset at low.
	begin
		sink_sop <= 1'b0;
		sink_eop <= 1'b0;
		sink_real <= 8'b0;
		inputSampleAddr <= 9'b0;
		fft_state <= S_SOP; // start of package
	end
	else
	begin
		case(fft_state)
			S_STBY:
			
			
			
			S_SOP:
			begin
				// asset start of packet to the fft module
				sink_sop <= 1'b1;
				// load the first data point
				sink_real <= inputSampleData;
				// load the next address
				inputSampleAddr <= 9'b1;
				fft_state <= S_MID;
			end
			
			S_MID:
			begin
				// not sop or eop.
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
				
				sink_real <= inputSampleData;
				
				inputSampleAddr <= inputSampleAddr + 1;
				
				// if there's one left...
				if(inputSampleAddr == 9'b1_1111_1110)
					fft_state <= S_EOP;
				else
					fft_state <= S_MID;
			end
			
			S_EOP:
			begin
				sink_eop <= 1'b1;
				sink_real <= inputSampleData;
				fft_state <= S_STBY;
			end
		endcase
	end
end



fft myfft(
	.clk(clk),
	.reset_n(rst),
	.inverse(1'b0), // 0: FFT, 1: IFFT
	.sink_valid(),
	.sink_sop(sink_sop),
	.sink_eop(sink_eop),
	.sink_real(sink_real),
	.sink_imag(sink_imag),
	.sink_error(),
	.source_ready(),
	.sink_ready(),
	.source_error(),
	.source_sop(),
	.source_eop(),
	.source_valid(),
	.source_exp(),
	.source_real(),
	.source_imag()
);


endmodule 