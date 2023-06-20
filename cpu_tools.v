/*
* In this file contains modules for followings
* 	Control unit
* 	2x1 Mux
* 	2's Complement
* 	program counter
* 	Instruction Decode
*/

`timescale 1ns/100ps

// Defien the decode module
module decode(INSTRUCTION, OPCODE, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, IMMEDIATE);

	// Declare input
	input [31:0] INSTRUCTION;

	// Declare outputs
	output reg [2:0]	INADDRESS,
				OUT1ADDRESS,
				OUT2ADDRESS;

	output reg [7:0]	OPCODE,
				OFFSET_COUNT,
				IMMEDIATE;
	
	// If the INSTRUCTION is changed execute the following block
	always @(INSTRUCTION)
	begin
		// Get the relevant bits for OPCODE, inout Address and Immediate from 32 bit INSTRUCTION
		OPCODE		= INSTRUCTION[31:24];
		INADDRESS	= INSTRUCTION[18:16];
		OUT1ADDRESS	= INSTRUCTION[10:8];
		OUT2ADDRESS	= INSTRUCTION[2:0];

		if (OPCODE == 8'h06 || OPCODE == 8'h07 || OPCODE == 8'h11)
		begin
			IMMEDIATE = INSTRUCTION[23:16];
		end
		else
		begin
			IMMEDIATE = INSTRUCTION[7:0];
		end

		// check the opcode generate SHiFTOP according to the shift type
		if ( OPCODE == 8'h0d || OPCODE == 8'h0e || OPCODE == 8'h0f || OPCODE == 8'h10)
		begin
			// Check thr shift value and give a limit for maxmum shift amount
			if (INSTRUCTION[7:0] > 8'h0f)
			begin
				IMMEDIATE[3:0] = 4'd8;
			end
			else begin
				IMMEDIATE = INSTRUCTION;
			end

			if ( OPCODE == 8'h0d)	// for sll
			begin
				IMMEDIATE[7:6] = 2'b00;
			end
			else if ( OPCODE == 8'h0e)// for srl	
			begin
				IMMEDIATE[7:6] = 2'b01;
			end
			else if ( OPCODE == 8'h0f)// for sra
			begin
				IMMEDIATE[7:6] = 2'b10;
			end
			else if ( OPCODE == 8'h10)// for ror
			begin
				IMMEDIATE[7:6] = 2'b11;
			end
		end
	end
endmodule

/* 
* Define Control unit
* In here, generate control signals according to the OPCODE
*/
module control_unit(
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
	READ);

	// Input declaration
	input BUSYWAIT;
	input [7:0] OPCODE;
	input [31:0] PC;

	/* 
	* Output declaration as registers
	* 
	*	MUX1_CS - to select REGOUT2 or its 2's complement
	*	MUX2_CS - to select Immdiate or mux1_out
	*	JMP_CS - to select NEXT PC or Target address, when jump instruction execution
	*	BEQ_CS	- to select NEW_PC  when branch eqaul instruction
	*	BNE_CS	- to select NEW_PC  when branch not eqaul instruction 
	*/
	
	output reg 	MUX1_CS,
			MUX2_CS,
			MUX4_CS,
			JMP_CS,
			BEQ_CS,
			BNE_CS,
			REG_WRITE,
			MEM_WRITE,
			READ;

	output reg [2:0] ALUOP;

	always @(PC)
	begin
		#2
		MEM_WRITE 	= 1'b0;
		READ		= 1'b0;
	end

	always @(OPCODE, PC)
	begin
		#1 // Add 1 time unit delay to generate signals
		case(OPCODE)
			8'h00:	// Generate control signals for loadi
			begin
				MUX2_CS 	= 1'b1;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b000;
			end
			8'h01:	// Generate control signals for move
			begin
				MUX1_CS 	= 1'b1;
				MUX2_CS 	= 1'b0;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;	
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP		= 3'b000;
			end
			8'h02:	// Generate control signals for add
			begin
				MUX1_CS 	= 1'b1;
				MUX2_CS 	= 1'b0;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP		= 3'b001;
			end
			8'h03:	// Generate control signals for sub
			begin
				MUX1_CS 	= 1'b0;
				MUX2_CS 	= 1'b0;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b001;
			end
			8'h04:	// Generate control signals for and
			begin	
				MUX1_CS 	= 1'b1;
				MUX2_CS 	= 1'b0;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b010;
			end
			8'h05:	// Generate control signals for or
			begin
				MUX1_CS 	= 1'b1;
				MUX2_CS 	= 1'b0;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b011;
			end
			8'h06:	// Generate control signals for jump
			begin
				JMP_CS		= 1'b1;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b0;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
			end
			8'h07:	// Generate control signals for beq
			begin
				MUX1_CS 	= 1'b0;
				MUX2_CS 	= 1'b0;
				BEQ_CS		= 1'b1;
				JMP_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b0;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP		= 3'b001;
			end
			8'h08:	// Generate control signals for lwd
			begin
				MUX1_CS 	= 1'b1;
				MUX2_CS 	= 1'b0;
				MUX4_CS		= 1'b1;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b1;
				ALUOP		= 3'b000;
			end
			8'h09:	// Generate control signals for lwi
			begin
				MUX2_CS 	= 1'b1;
				MUX4_CS		= 1'b1;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b1;
				ALUOP		= 3'b000;
			end
			8'h0a:	// Generate control signals for swd
			begin
				MUX1_CS 	= 1'b1;
				MUX2_CS 	= 1'b0;
				BEQ_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b0;
				MEM_WRITE	= 1'b1;
				READ		= 1'b0;
				ALUOP		= 3'b000;
			end
			8'h0b:	// Generate control signals for swi
			begin
				MUX2_CS 	= 1'b1;
				BEQ_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE	= 1'b0;
				MEM_WRITE	= 1'b1;
				READ		= 1'b0;
				ALUOP		= 3'b000;
			end
			8'h0c:	// Generate control signals for mult
			begin
				ALUOP 		= 3'b100;
			end
			8'h0d:	// Generate control signals for sll
			begin
				MUX2_CS 	= 1'b1;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b101;
			end
			8'h0e:	// Generate control signals for srl
			begin
				MUX2_CS 	= 1'b1;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b101;
			end
			8'h0f:	// Generate control signals for sra
			begin
				MUX2_CS 	= 1'b1;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b101;
			end
			8'h10:	// Generate control signals for ror
			begin
				MUX2_CS 	= 1'b1;
				MUX4_CS		= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b0;
				REG_WRITE 	= 1'b1;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP 		= 3'b101;
			end
			8'h11:	// Generate control signals for bne
			begin
				MUX1_CS 	= 1'b0;
				MUX2_CS 	= 1'b0;
				JMP_CS		= 1'b0;
				BEQ_CS		= 1'b0;
				BNE_CS		= 1'b1;
				REG_WRITE	= 1'b0;
				MEM_WRITE	= 1'b0;
				READ		= 1'b0;
				ALUOP		= 3'b001;
			end
		endcase
	end

endmodule

// Define module mux for 8 bit buses
module mux8(DATA1, DATA2, SELECT, RESULT);

	// Declare inputs
	input [7:0] DATA1, DATA2;
	input SELECT;

	// Declare output
	output reg [7:0] RESULT;

	// If any of argument is changed execute the following block
	always @(*)
	begin
		// If the select is 1 output will be DATA1 else output will be DATA 2
		RESULT = SELECT ? DATA1 : DATA2;
	end
endmodule

// Define module mux for 32 bit buses
module mux32(DATA1, DATA2, SELECT, RESULT);

	// Declare inputs
	input [31:0] DATA1, DATA2;
	input SELECT;

	// Declare output
	output reg [31:0] RESULT;

	// If any of argument is changed execute the following block
	always @(*)
	begin
		// If the select is 1 output will be DATA1 else output will be DATA 2
		RESULT = SELECT ? DATA1 : DATA2;
	end
endmodule

// Define module 2's complement
module twos_comp(DATA, RESULT);

	// Declare input
	input [7:0] DATA;

	// Declare output
	output reg [7:0] RESULT;

	// If the input DATA is changed execute the following block
	always @(DATA)
	begin
		#1 RESULT = ~DATA + 1;
	end
endmodule

// Define module pc
module pc(CLK, RESET, dBUSYWAIT, iBUSYWAIT, NEW_PC, PC);

	// Declare inputs
	input [31:0] NEW_PC;
	input CLK, RESET, dBUSYWAIT, iBUSYWAIT;

	// Declare output
	output reg [31:0] PC;

	// Following block of code is executed at the positive edge of the CLK
	always @(posedge CLK)
	begin
		// If the RESET signal is high assign 0 for the pc value
		if ( RESET == 1'b1)
		begin
			PC = 32'b0;
		end

		// Else get the NXTPC value to the pc register
		else if ( !dBUSYWAIT && !iBUSYWAIT)
		begin
			#1 PC = NEW_PC;
		end
	end
endmodule


// Define pc increment module to increment pc value by 4
module pcIncrement(PC, NXTPC);

	input [31:0] PC;

	output reg [31:0] NXTPC;

	always @(PC)
	begin
		#1 NXTPC = PC + 4;
	end
endmodule


// Define adder module to add 32 bit values
module adder32(DATA1, DATA2, RESULT);

	input [31:0]	DATA1,
			DATA2;
	
	output [31:0]	RESULT;

	assign #2 RESULT = DATA1  + DATA2;

endmodule
