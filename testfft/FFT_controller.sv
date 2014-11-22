
// module FFT_controller(
module testfft(
	input                         clk,
	input                         rst,             // reset on falling edge
	input                         start,           // start loading 
	output       [8:0]  inputSampleAddr,  // 0-511
	input signed [7:0]  inputSampleData,  // 0-255
	output                        done	
	
	
	
	
	
	
);
	
// parameter ADDR_BITS = 9; // 0-511
// parameter DATA_BITS = 8; // 0-255

logic [7:0] sink_real;
logic [3:0] fft_state;

// inputs to the FFT module
logic sink_sop; // indicates the start of the incoming FFT Frame
logic sink_eop; // indicates the end of the incoming FFT Frame
logic sink_valid; // asserted when data on the data bus is valid
logic sink_error; // 00: no error

// Outputs from the FFT module
logic sink_ready; // asserted by the FFT engine when it can accept data
logic source_sop;
logic source_eop;
logic source_real;
logic source_imag;


assign sink_imag = 8'b0;   // no input imaginary
assign sink_error = 2'b00; // idkwhatimdoing


// fft conversion states
typedef enum logic[3:0] {
	IN_STBY, // standby
	IN_SOP,  // start of packet
	IN_MID,  // in the middle of packet
	IN_EOP   // end of packet
} in_state_t;

typedef enum logic[3:0] {
	OUT_STBY, // standby
	OUT_SOP,  // start of packet
	OUT_MID,  // in the middle of packet
	OUT_EOP   // end of packet
} out_state_t;

always @ (posedge start)
begin
	// do something?
end 

// FFT state machine
// Transfers the input data to the FFT machine
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
			IN_STBY:
				/// what do i do here?
			
			IN_SOP:
			begin
				// TODO: should probably wait for sink_ready to be asserted...
				
				// asset start of packet to the fft module
				sink_sop <= 1'b1;
				// asseted when data on data bus is valid.
				sink_valid <= 1'b1;
				// load the first data point
				sink_real <= inputSampleData;
				// load the next address
				inputSampleAddr <= 9'b1;
				fft_state <= S_MID;
			end
			
			IN_MID:
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
			
			IN_EOP:
			begin
				sink_eop <= 1'b1;
				sink_real <= inputSampleData;
				fft_state <= S_STBY;
			end
		endcase
	end
end

// output stuff
always @ (posedge clk)
begin
	case ()
	if(source_ready)

end

ram512x8 myfftram(
	.address(),
	.clock(clk),
	.data(),
	.wren(),
	.q()
);

fft myfft(
	.clk(clk),
	.reset_n(rst),
	.inverse(1'b0), // 0: FFT, 1: IFFT
	.sink_valid(sink_valid),
	.sink_sop(sink_sop),
	.sink_eop(sink_eop),
	.sink_real(sink_real),
	.sink_imag(sink_imag),
	.sink_error(sink_error),
	.source_ready(),
	
	.sink_ready(sink_ready),
	.source_error(),
	.source_sop(source_sop),
	.source_eop(source_eop),
	.source_valid(),
	.source_exp(),
	.source_real(),
	.source_imag()
);


endmodule 