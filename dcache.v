/*
Module  : Data Cache 
Author  : Isuru Nawinne, Kisaru Liyanage
Date    : 25/05/2020

Description	:

This file presents a skeleton implementation of the cache controller using a Finite State Machine model. Note that this code is not complete.
*/

module dcache (
                clock,
		        reset,
                busywait,
                read,
                write,
                writedata,
                readdata,
                address,
                mem_busywait,
                mem_read,
                mem_write,
                mem_writedata,
                mem_readdata,
                mem_address
                );

    input read, write, clock, reset;
    input mem_busywait;
    input [7:0] writedata, address;
    input [31:0] mem_readdata;
    
    output reg busywait;
    output reg mem_read, mem_write;
    output reg [7:0] readdata;
    output reg [5:0] mem_address;
    output reg [31:0] mem_writedata;

    integer i;


    reg [36:0] cache [7:0];

    reg [2:0] tag, index;
    reg [1:0] offset;

    wire [2:0] out;
    
    reg readaccess, writeaccess, valid, dirty;
    wire hit;

    reg [7:0] word0, word1, word2, word3;

    /*
    Combinational part for indexing, tag comparison for hit deciding, etc.
    */

    // extract words from exitting block and decode address into tag index and offset
    always @(*)
    begin

        #1
        tag     = address[7:5];
        index   = address[4:2];
        offset  = address[1:0];
        valid   = cache[index][36];
        dirty   = cache[index][35];

        word0   = cache[index][7:0];
        word1   = cache[index][15:8];
        word2   = cache[index][23:16];
        word3   = cache[index][31:24];

    end

    // compare tag and valid bit
    xnor n_xnor [2:0] (out, tag, cache[index][34:32]);

    and (taghit, out[2], out[1], out[0]);

    and (hit, valid, taghit);


    // Send data into cpu according to contol signal and hit status
    always @(*)
    begin
        busywait = (read || write)? 1 : 0;
        
        if (read && hit)
        begin
            case(offset)
                2'b00:
                begin
                    readdata = word0;
                end
                2'b01:
                begin
                    readdata = word1;
                end
                2'b10:
                begin
                    readdata = word2;
                end
                2'b11:
                begin
                    readdata = word3;
                end
            endcase
            busywait    = 1'b0;
            readaccess  = 1'b0;
        end

        if (write && hit)
        begin
            busywait        = 1'b0;
	        writeaccess		= 1'b1;
        end

    end

    //write into cache
    always @(posedge clock)
    begin
	if (writeaccess)
	begin
		#1
		case(offset)
		    2'b00:
		    begin
			cache[index][7:0]   = writedata;
		    end
		    2'b01:
		    begin
			cache[index][15:8]  = writedata;
		    end
		    2'b10:
		    begin
			cache[index][23:16] = writedata;
		    end
		    2'b11:
		    begin
			cache[index][31:24] = writedata;
		    end
		endcase
        cache[index][35]    = 1'b1;
		writeaccess	        = 1'b0;
	end
    end

    // write readdata to cache which is from memory
    always @(posedge clock)
    begin
        if (state == CACHE_WRITE)
        begin
        #1
            cache[index][36]    = 1'b1;
            cache[index][35]    = 1'b0;
            cache[index][34:32] = tag;
            cache[index][31:0]  = mem_readdata;

            next_state = IDLE;
        end
        
    end
    

    /* Cache Controller FSM Start */

    parameter   IDLE        = 3'b000,
                MEM_READ    = 3'b001,
                MEM_WRITE   = 3'b010,
                CACHE_WRITE = 3'b011;

    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty && !hit)  
                    next_state = MEM_READ;
                else if ((read || write) && dirty && !hit)
                    next_state = MEM_WRITE;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_WRITE;
                else    
                    next_state = MEM_READ;

            MEM_WRITE:
                if (!mem_busywait)
                    next_state = MEM_READ;
                else
                    next_state = MEM_WRITE;
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 8'dx;
                mem_writedata = 8'dx;
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                busywait = 1;
            end

            MEM_WRITE:
            begin
                mem_read = 0;
                mem_write = 1;
                mem_address = {tag, index};
                mem_writedata = cache[index][31:0];
                busywait = 1;
            end
            
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge clock, reset)
    begin
        if(reset)
	begin
		state = IDLE;
		//hit = 1'b0;
		for (i = 0; i < 8; i=i+1)
		begin
			cache[i] = 0;
		end
	end
        else
	begin
		state = next_state;
	end
    end
    /* Cache Controller FSM End */

    initial
	begin
		$dumpfile("cpu_wavedata.vcd");
		for(i = 0; i < 8; i = i + 1)
		begin
			$dumpvars(1,cache[i]);
		end
	end

endmodule
