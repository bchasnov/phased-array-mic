module ad7829_proj(input  logic [7:0] data,
                   input  logic EOC,
						 output logic RD, CS, CONVST,
						 output logic [2:0] ADC_addr);
	logic [9:0] RAM_address;
	logic [7:0] q;
	logic inclock, outclock, wren;
	
	control control(RAM_address, inclock, outclock);
	ram ram(RAM_address, data, inclock, outclock, wren, q);
	ad7829 ad7829(data, EOC, RD, CS, CONVST, ADC_addr);
	
endmodule
						 
					
module ad7829(input  logic [7:0] data,
              input  logic EOC,
				  output logic RD, CS, CONVST,
				  output logic [2:0] addr);
// To read the ADC, follow this sequence
// 1) set addr (0-7) of desired channel to read
// 2) set CONVST to low for 50ns     --__--
// 3) wait for falling edge of EOC   ---___
// 4) set CS to low
// 5) set the next address
// 6) set RD low (clocks in the next address)
// 7) read in parallel data
// 8) wait 30ns before starting.


endmodule
	
	
module control(input logic [9:0] RAM_address, 
               input logic inclock, 
					input logic outclock);

endmodule
					