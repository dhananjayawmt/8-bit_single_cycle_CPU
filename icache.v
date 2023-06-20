/*
Module  : Instrction Cache 
Author  : Manahana H.K, Dhananjaya W.M.T.
Date    : 07/02/2022
*/

module icache (
                clock,
		        reset,
                busywait,
                readinst,
                address,
                mem_busywait,
                mem_read,
                mem_readdata,
                mem_address
                );

    input clock, reset;
    input mem_busywait;
    input [9:0] address;
    input [127:0] mem_readdata;
    
    output reg busywait;
    output reg mem_read;
    output reg [31:0] readinst;
    output reg [5:0] mem_address;

    integer i;


    reg [131:0] cache [7:0];

    reg [2:0] tag, index;
    reg [1:0] offset;

    wire [2:0] out;
    
    reg valid;
    reg hit;

    reg [31:0] word [3:0];

    /*
    Combinational part for indexing, tag comparison for hit deciding, etc.
    */

    // extract words from exitting block and decode address into tag index and offset
    always @(*)
    begin

        busywait = 1'b1;
        #1
        tag     = address[9:7];
        index   = address[6:4];
        offset  = address[3:2];

        valid   = cache[index][131];

        word[0]   = cache[index][31:0];
        word[1]   = cache[index][63:32];
        word[2]   = cache[index][95:64];
        word[3]   = cache[index][127:96];

        if (tag == cache[index][130:128] && valid)
        begin
            hit = 1'b1;
        end
        else
        begin
            hit = 1'b0;
        end

    end

    // Send data into cpu according to contol signal and hit status
    always @(*)
    begin        
        if (hit)
        begin
            case(offset)
                2'b00:
                begin
                    readinst = word[0];
                end
                2'b01:
                begin
                    readinst = word[1];
                end
                2'b10:
                begin
                    readinst = word[2];
                end
                2'b11:
                begin
                    readinst = word[3];
                end
            endcase
            busywait    = 1'b0;
            hit         = 1'b0;
        end
    end

    // write readdata to cache which is from memory
    always @(posedge clock)
    begin
        if (state == CACHE_WRITE)
        begin
        #1
            cache[index][131]    = 1'b1;
            cache[index][130:128] = tag;
            cache[index][127:0]  = mem_readdata;

            next_state = IDLE;
        end
        
    end
    

    /* Cache Controller FSM Start */

    parameter   IDLE        = 3'b000,
                MEM_READ    = 3'b001,
                CACHE_WRITE = 3'b010;

    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if (!hit)
                    next_state = MEM_READ;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_WRITE;
                else    
                    next_state = MEM_READ;
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_address = 6'dx;
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_address = {tag, index};
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

    // initial
    // begin
    //     $dumpfile("cpu_dump.vcd");
    //     for(i=0;i<128;i++)
    //         $dumpvars(1,INST_CACHE_ARRAY[i]);
    //     for(i=0;i<8;i++)
    //     begin
    //         $dumpvars(1,INST_TAG_ARRAY[i]);
    //         $dumpvars(1,INST_VALID_BIT_ARRAY[i]);
    //     end
    // end


endmodule
