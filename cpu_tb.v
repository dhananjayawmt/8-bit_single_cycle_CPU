// Computer Architecture (CO224) - Lab 06
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Isuru Nawinne

`timescale 1ns/100ps

`include "cpu.v"
`include "dcache.v"
`include "icache.v"
`include "data_memory.v"
`include "instruction_memory.v"

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    
    wire	dread,
                iread,
	    	dwrite,
		dbusywait,
                ibusywait,
		dmem_busywait,
                imem_busywait,
		dmem_read,
                imem_read,
		dmem_write;
    
    wire [7:0]	dwritedata,
	    	dreaddata,
		daddress;

    wire [9:0]	iaddress;

    wire [31:0] dmem_writedata,
	    	dmem_readdata,
                readinst;

    wire [5:0]	dmem_address,
                imem_address;

    wire [127:0]        imem_readdata;
    /*
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory

    reg [7:0] instr_mem [1023:0];

    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    
//     always @(PC)
//     begin
// 	     #2 INSTRUCTION = {instr_mem[PC+3], instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC]};
//     end

    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        //{instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000010_00000000_00000001_00000000;
        //{instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000010_00000000_00000010_00000000;
        //{instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00000100_00000000_00000000_00000000;
	//{instr_mem[10'd115, instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00000100_00000011_00110100_00000111;
	//{instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00000101_00000000_00000101_00000000;
	//{instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00000000_00000000_00000010_00000110;
	//{instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]} = 32'b00000111_00000000_00000111_00000000;
	//{instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]} = 32'b00000000_00000000_00000001_00000110;
	//{instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]} = 32'b00000010_00000001_11111101_00000111;
	//{instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]} = 32'b00000010-00000001_00000000_00000010;
        
        // METHOD 2: loading instr_mem content from instr_mem.mem file
        //$readmemb("programs/instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(
                PC,
                INSTRUCTION,
                CLK,
                RESET,
                dwritedata,
                dreaddata,
                dbusywait,
                ibusywait,
                dread,
                dwrite,
                daddress);

    dcache mydcache (
                        CLK,
			RESET,
                        dbusywait,
                        dread,
                        dwrite,
                        dwritedata,
                        dreaddata,
                        daddress,
                        dmem_busywait,
                        dmem_read,
                        dmem_write,
                        dmem_writedata,
                        dmem_readdata,
                        dmem_address
                        );  

    data_memory mydmemory (
                        CLK,
                        RESET,
                        dmem_read,
                        dmem_write,
                        dmem_address,
                        dmem_writedata,
                        dmem_readdata,
                        dmem_busywait
                        );


    icache myicache (
                        CLK,
			RESET,
                        ibusywait,
                        INSTRUCTION,
                        PC[9:0],
                        imem_busywait,
                        imem_read,
                        imem_readdata,
                        imem_address
                        );  

    instruction_memory myimemory (
                        CLK,
                        imem_read,
                        imem_address,
                        imem_readdata,
                        imem_busywait
                        );

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
	$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
	
	#3 RESET = 1'b1;
	#2 RESET = 1'b0;
        
        // finish simulation after some time
        #2000
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule
