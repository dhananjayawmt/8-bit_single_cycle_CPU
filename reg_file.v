`timescale 1ns/100ps

module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);

	// Begin port declaration
	// Inputs	
	input [7:0] IN;
	input [2:0] INADDRESS, OUT1ADDRESS, OUT2ADDRESS;
	input WRITE, CLK, RESET; // Wires

	// Outputs
	output reg [7:0] OUT1, OUT2;
	// End port declaration

	// Declare 8x8 register as vectior
	reg [7:0] registers [0:7];
	
	integer i;

	// Execute the following block when rising edge of CLK
	always@(posedge CLK)
	begin
		// Reset the register if the RESET signal is high
		if ( RESET == 1 )
		begin

			// Write 0 for all registers with 1 time unit delay
			#1 for ( i = 0; i < 8; i = i + 1)
			begin
				registers[i] = 8'b0;
			end
		end
		
		// If the WRITE signal is high and RESET signal is low, write the given input data(IN) into related register(the register given by INADDRESS)
		else if ( WRITE == 1)
		begin
			// Write the register with 1 time unit delay
			#1 registers[INADDRESS] = IN;
		end
	end

	// If any of varible is changed assign relavant values from the registers to the OUT1 and OUT2
	always@(*)
	begin
		#2
		OUT1 = registers[OUT1ADDRESS];
		OUT2 = registers[OUT2ADDRESS];
	end

	initial
	begin
		$dumpfile("cpu_wavedata.vcd");
		for(i = 0; i < 8; i = i + 1)
		begin
			$dumpvars(1,registers[i]);
		end
	end

	initial
	begin
		#5
		$display("\n\t\t\t==================================================================");
		$display("\t\t\t Change of Register Content Starting from Time #5");
		$display("\t\t\t==================================================================\n");
		$display("\t\ttime\tregs0\tregs1\tregs2\tregs3\tregs4\tregs5\tregs6\tregs7");
		$display("\t\t-------------------------------------------------------------------------------------");
		$monitor($time, "\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", registers[0], registers[1], registers[2], registers[3], registers[4], registers[5], registers[6], registers[7]);
	end


endmodule
