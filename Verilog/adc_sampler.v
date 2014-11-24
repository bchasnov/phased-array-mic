module adc_sampler (
	input logic clk,    // Clock from FPGA
	output logic[2:0] chnl, // Channel selector to ADC
	output logic n_convst, // (ON low) Start conversion on ADC
	input logic n_eoc, // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	input logic[7:0] adc_in, // data bits from the ADC
	output logic[7:0] ch0, // channel zero data
	output logic[7:0] ch1, // channel one data
	output logic[7:0] ch2, // channel two data
	output logic[7:0] ch3, // channel three data
	output logic newSample // clock running at overall sampling rate
	);

// INTERNAL LOGIC
logic stateClk; // rate of running the state machine
logic sampleClk; // sampling clock
reg [1:0] curr_channel = 2'b0; // current channel we're sampling

typedef enum logic[3:0] {
	START_CONV,
	WAIT_FOR_EOC, 
	CHIP_SELECT, // load in next address
	READ_DATA,
	WAIT_TO_RESET,
	DECIDE_TO_RESET,
	STANDBY
	} state_t;

state_t state;


// --------
// CLOCK SET UP
// --------

// Slow down system clock to obtain sampling clock
logic[9:0] clockDiv = 0;
always_ff @(posedge clk) begin
	clockDiv <= clockDiv + 10'b1;
end

assign stateClk = clockDiv[0]; // fastest clock, for switching states

logic oldSampleClk = 1'b0;
always_ff @(posedge stateClk)
	oldSampleClk <= clockDiv[9];

assign sampleClk = clockDiv[9]; // clock for indicating new samples are ready


// --------
// STATE MACHINE MECHANICS
// --------

// state register
always_ff @(posedge stateClk) begin
	case (state)
		START_CONV: 
			state <= WAIT_FOR_EOC;

		WAIT_FOR_EOC:
			if (~n_eoc)
				state <= CHIP_SELECT;
			else
				state <= WAIT_FOR_EOC;

		CHIP_SELECT: 
			state <= READ_DATA;

		READ_DATA:
			state <= WAIT_TO_RESET;

		WAIT_TO_RESET: 
			state <= DECIDE_TO_RESET;
		
		DECIDE_TO_RESET:
			if (chnl == 2'b0) begin // if we've sampled the four channels:
				newSample <= 1'b1;
				state <= STANDBY;
			end
			else
				state <= START_CONV;
		STANDBY: begin
			newSample <= 1'b0;
			if (sampleClk & ~oldSampleClk)
				state <= START_CONV;
		end	
		default: begin
			newSample <= 1'b0;
			state <= STANDBY; // shouldn't happen
		end
	endcase
end


// --------
// ADC CONTROLS
// --------

always_comb begin
	case (state)
		START_CONV: 
			{n_convst, n_cs, n_rd} = 3'b011;
		
		WAIT_FOR_EOC: 
			{n_convst, n_cs, n_rd} = 3'b111;

		CHIP_SELECT: 
			{n_convst, n_cs, n_rd} = 3'b101;

		READ_DATA:
			{n_convst, n_cs, n_rd} = 3'b100;

		WAIT_TO_RESET: 
			{n_convst, n_cs, n_rd} = 3'b111;
			
		DECIDE_TO_RESET:
			{n_convst, n_cs, n_rd} = 3'b111;
		
		STANDBY:
			{n_convst, n_cs, n_rd} = 3'b111;

		default: // shouldn't happen
			{n_convst, n_cs, n_rd} = 3'b111;
	endcase
end


// --------
// CHANNEL SWITCHING
// --------

always_ff @(negedge n_cs)
	// load the next address at the chip_select stage
	curr_channel <= curr_channel + 2'b1;

assign chnl = {1'b0, curr_channel}; // only using 4 out of 8 channels


// --------
// READING DATA
// --------

// read data slightly after telling ADC to provide data
always_ff @(negedge stateClk)
	if (state == READ_DATA)
		case (curr_channel)
			2'd0: ch3 <= adc_in;
			2'd1: ch0 <= adc_in;
			2'd2: ch1 <= adc_in;
			2'd3: ch2 <= adc_in;
			default: ch0 <= adc_in;
		endcase


endmodule
