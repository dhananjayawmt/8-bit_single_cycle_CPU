`timescale 1ns/100ps

// Include other necessary verilog files
`include "cpu_tools.v"
`include "alu.v"
`include "reg_file.v"

// Define cpu module
module cpu(
		PC,
		INSTRUCTION,
		CLK,
		RESET,
		OUT1,
		READDATA,
		dBUSYWAIT,
		iBUSYWAIT,
		MEM_READ,
		MEM_WRITE,
		ALU_OUT);

	// Declare inputs
	input [31:0] INSTRUCTION;
	input CLK, RESET, dBUSYWAIT, iBUSYWAIT;
	input [7:0] READDATA;

	// Declare output
	output [31:0] PC;
	output [7:0] OUT1, ALU_OUT;
	output MEM_READ, MEM_WRITE;

	// Declare wires for connecting instances of other modules
	wire	MUX1_CS,
		MUX2_CS,
		MUX3_CS,
		MUX4_CS,
		JMP_CS,
		BEQ_CS,
		BNE_CS,
		REG_WRITE,
		MEM_WRITE,
		BUSYWAIT,
		MEM_READ,
		CLK,
		RESET,
		ZERO;

	reg [31:0]	OFFSET;

	wire [31:0]	NXTPC,
			TARGET_ADDRESS,
			MUX3_OUT,
			NEW_PC;

	wire [2:0]	INADDRESS,
			OUT1ADDRESS,
			OUT2ADDRESS,
			ALUOP;

	wire [7:0]	OPCODE,
			IMMEDIATE,
			IN,
			OUT1,
			OUT2,
			OUT2_COMP,
			MUX1_OUT,
			MUX2_OUT,
			ALU_OUT,
			READDATA;

	/* 
	* -----------------------------------------------------------------------------------
	* 			Create instances of modules
	* -----------------------------------------------------------------------------------
	*/

	decode decode1(
			INSTRUCTION,
			OPCODE,
			INADDRESS,
			OUT1ADDRESS,
			OUT2ADDRESS,
			IMMEDIATE);

	control_unit c_unit1(
				OPCODE,
				BUSYWAIT,
				PC,
				MUX1_CS,
				MUX2_CS,
				MUX4_CS,
				JMP_CS,
				BEQ_CS,
				BNE_CS,
				ALUOP,
				REG_WRITE,
				MEM_WRITE,
				MEM_READ);

	reg_file reg_file1(
				IN,
				OUT1,
				OUT2,
				INADDRESS,
				OUT1ADDRESS,
				OUT2ADDRESS,
				REG_WRITE,
				CLK,
				RESET);

	twos_comp twos_comp1(OUT2, OUT2_COMP);

	// Select the REGOUT2 value or its 2's complement according to the select(MUX1_CS) signal
	mux8 mux8_1(OUT2, OUT2_COMP, MUX1_CS, MUX1_OUT);

	// Select the Immediate value of mux1_out according to the select(MUX2_CS) signal
	mux8 mux8_2(IMMEDIATE, MUX1_OUT, MUX2_CS, MUX2_OUT);

	// Select the NXTPC value or target jump address according to the OPCODE
	mux32 mux32_3(TARGET_ADDRESS, NXTPC, MUX3_CS, NEW_PC);

	mux8 mux8_4(READDATA, ALU_OUT, MUX4_CS, IN);

	alu alu1(OUT1, MUX2_OUT, ALU_OUT, ZERO, ALUOP);

	pc pc1(CLK, RESET, dBUSYWAIT, iBUSYWAIT, NEW_PC, PC);

	pcIncrement pcincrement1(PC, NXTPC);

	adder32 adder32_1(OFFSET, NXTPC, TARGET_ADDRESS);

	and (TEMP1, BEQ_CS, ZERO);

	and (TEMP2, BNE_CS, ~ZERO);

	or (MUX3_CS, TEMP1, TEMP2, JMP_CS);

	// Extend the sign bit and create 32 bit offset value
	always @(IMMEDIATE)
	begin
		if(IMMEDIATE[7] == 1'b0)
		begin
			OFFSET[31:8] = 24'h000000;
		end
		else if(IMMEDIATE[7] == 1'b1)
		begin
			OFFSET[31:8] = 24'hffffff;
		end
		OFFSET[7:0] = IMMEDIATE;
	end

	// Re route wires to leftshift the offset value by 2
	always @(OFFSET)
	begin
		OFFSET[31:2] = OFFSET[29:0];
		OFFSET[1:0] = 2'b00;
	end
endmodule
