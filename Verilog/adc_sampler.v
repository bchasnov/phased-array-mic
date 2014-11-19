module #(parameter LOGCLKDIV) adc_sampler (
	input logic clk,    // Clock from FPGA
	output logic[2:0] chnl // Channel selector to ADC
	output logic n_convst // (ON low) Start conversion on ADC
	input logic n_eoc // (ON low) Input signal indicating EOC from ADC
	output logic n_cs, // (ON low) chip select to ADC
	output logic n_rd, // (ON low) initiate a read on ADC
	output logic[7:0] ch0 // channel zero data
	output logic[7:0] ch1 // channel one data
	output logic[7:0] ch2 // channel two data
	output logic[7:0] ch3 // channel three data
	output logic newSample // clock running at overall sampling rate
	);

// INTERNAL LOGIC
logic stateClk; // rate of running the state machine
logic sampleClk; // sampling clock (running 4x speed of newSample)
logic [2:0] curr_channel = 2'b0; // current channel we're sampling

typedef enum logic[3:0] {
	START_CONV,
	WAIT_FOR_EOC, 
	CHIP_SELECT, // load in next address
	READ_DATA,
	WAIT_TO_RESET
	} state_t;

state_t state, next_state;


// --------
// CLOCK SET UP
// --------

// Slow down system clock to obtain sampling clock
logic[LOGCLKDIV+1:0] clockDiv = 0;
always_ff @(posedge clk) begin
	clockDiv <= clockDiv + 1;
end

assign stateClk = clockDiv[5]; // fastest clock, for switching states
assign sampleClk = clockDiv[LOGCLKDIV-3]; // clock for reseting the FSM
assign newSample = clockDiv[LOGCLKDIV-1]; // clock for indicating new samples are ready


// --------
// STATE MACHINE MECHANICS
// --------

// state register
always_ff @(posedge stateClk)
	state <= next_state;

// next state logic
always_comb begin
	case (state)
		START_CONV: 
			next_state = WAIT_FOR_EOC;

		WAIT_FOR_EOC:
			if (~n_eoc)
				next_state = CHIP_SELECT;
			else
				next_state = WAIT_FOR_EOC;

		CHIP_SELECT: 
			next_state = READ_DATA;

		READ_DATA:
			next_state = WAIT_TO_RESET;

		WAIT_TO_RESET: 
			if (sampleClk) 
				next_state = START_CONV;
			else
				next_state = WAIT_TO_RESET;

		default: // shouldn't happen
			next_state = WAIT_TO_RESET;
	endcase
end


// --------
// STATE DEPENDENT I/O
// --------
always_comb begin
	case (state)
		START_CONV: 

		WAIT_FOR_EOC:

		CHIP_SELECT: 

		READ_DATA:

		WAIT_TO_RESET: 
			
		default: // shouldn't happen

	endcase
end;