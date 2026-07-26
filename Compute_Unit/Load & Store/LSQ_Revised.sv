// Load Store Queue Revised
// The LSQ exists to hold load or store instructions that cannot proceed because the cache line they need is locked
// write_en from cache after an instruction is rejected
// Need to decide on priority of instructions in the LSQ, if multiple instructions are waiting for the same cache line, should they be issued in order or can they be coalesced and issued together?
// Also, priority between new instructions and instructions in LSQ
// Don't want to be continually checking the LSQ for instructions to issue, maybe only check when we get a signal from the cache that a cache line is unlocked and ready?
// LSQ will have a simple bit mask to indicate if an instruction can now be issued depending on the freeness of the cache lines
// bit mask can be cleared when we get a signal from the cache that a cache line is now free

// Still so, what if an instruction in the LSQ is ready and a new instruction is being sent in a given cycle?
// i think the move is to integrate the lsq into the lsu, replacing the fifo buffer for the cache with the lsq


`timescale 1ns / 1ps

module LSQ#(parameter NUM_ENTRIES = 8, DATA_WIDTH = 16, ADDR_WIDTH = , NUM_THREADS = 8, IDX_SIZE = , TAG_WIDTH = )(
    input logic clk, reset,

    input logic write_en, // from cache when an instruction gets rejected because its cache line is locked
    input logic read_en, // from LSU if cache is ready to move forward with an instruction

    // input logic [IDX_SIZE-1:0] target_line_in, can just produce internally from address
    input logic [NUM_THREADS-1:0] ready_threads_in, // from cache to tell which are already ready/don't access locked line, if coming from new instruction just default to all ready 
    input logic [ADDR_WIDTH-1:0] address_in [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] data_in [NUM_THREADS-1:0],
    input logic [NUM_THREADS-1:0] active_threads_in,
    input logic [1:0] warp_num_in,
    input logic [3:0] reg_num_in,
    input logic instr_type_in,

    input logic line_clear_en, // from cache when a line is cleared
    input logic [IDX_SIZE-1:0] line_clear, // clears a cache line after a lock is freed
    input logic line_lock_en, // from cache when a line is locked
    input logic [IDX_SIZE-1:0] line_lock, // from cache, which new line was locked


    output logic [ADDR_WIDTH-1:0] address_out [NUM_THREADS-1:0],
    output logic [DATA_WIDTH-1:0] data_out [NUM_THREADS-1:0],
    output logic [NUM_THREADS-1:0] active_threads_out,
    output logic [1:0] warp_num_out,
    output logic [3:0] reg_num_out,
    output logic instr_type_out,
    output logic ready, // if any lsq instructions are ready
    output logic empty, full
    );

    logic [$clog2(NUM_ENTRIES)-1:0] next_ready_instr;
    logic [$clog2(NUM_ENTRIES)-1:0] next_buffer_slot;

    logic read_ready;
    logic [NUM_ENTRIES-1:0] ready_mask; // which instructions are ready  (where/when to set it )
    logic [NUM_ENTRIES-1:0] ready_mask_clear; // combinational clearing temp to set ready_mask bits within the same clock cycle that cache lines are unlocked (or at the next edge whatever)
    logic [NUM_ENTRIES-1:0] available_mask; // which buffers are available

    logic [NUM_ENTRIES-1:0] priority_write_ptr;
    logic [NUM_ENTRIES-1:0] priority_read_ptr;
    logic [$clog2(NUM_ENTRIES)-1:0] priority_array [NUM_ENTRIES-1:0];

    typedef struct {
        logic [IDX_SIZE-1:0] target_line [NUM_THREADS-1:0]; // need to adjust for there being 8 target lines
        logic [NUM_THREADS-1:0] ready_threads;
        logic [ADDR_WIDTH-1:0] address [NUM_THREADS-1:0];
        logic [DATA_WIDTH-1:0] data [NUM_THREADS-1:0];
        logic [NUM_THREADS-1:0] active_threads;
        logic [1:0] warp_num;
        logic [3:0] reg_num;
        logic instr_type;
    } lsq_str;

    lsq_str lsq_struct [NUM_ENTRIES-1:0];

    always_comb begin
        next_ready_instr = '0;
        read_ready = '0;
        next_buffer_slot = '0;
        ready_mask_clear = '1;
        ready = '0;

        for(int i = 0; i < NUM_ENTRIES; i = i+1) begin
            if(ready_mask[priority_array[i]]) begin
                next_ready_instr = i[$clog2(NUM_ENTRIES)-1:0];
                read_ready = 1'b1;
                break;
            end

            if(available_mask[i]) begin
                next_buffer_slot = i[$clog2(NUM_ENTRIES)-1:0];
                break;
            end
        end


        for(int i = 0; i < NUM_ENTRIES; i = i+1) begin
            for(int j = 0; j < NUM_THREADS; j = j+1) begin
                if(!(lsq_struct[i].ready_threads[j] || (lsq_struct[i].target_line[j] == line_clear)) || lsq_struct[i].target_line[j] == line_lock) begin
                    ready_mask_clear[i] = 1'b0;
                end
            end
        end

        ready = |(ready_mask); // checks if any instructions are ready in the lsq;
    end

    always_ff@(posedge clk) begin
        if(reset) begin
            ready_mask <= '0;
            available_mask <= '1;

            priority_read_ptr <= 1'b0;
            priority_write_ptr <= 1'b0;
        end
        else begin 
            if(write_en) begin
                lsq_struct[next_buffer_slot].ready_threads <= ready_threads_in;
                for(int i = 0; i < NUM_ENTRIES; i = i+1) begin
                    lsq_struct[next_buffer_slot].target_line[i] <= address_in[i][ADDR_WIDTH-TAG_WIDTH-1 -: IDX_SIZE];
                    lsq_struct[next_buffer_slot].address[i] <= address_in[i];
                    lsq_struct[next_buffer_slot].data[i] <= data_in[i];
                end
                lsq_struct[next_buffer_slot].active_threads <= active_threads_in;
                lsq_struct[next_buffer_slot].warp_num <= warp_num_in;
                lsq_struct[next_buffer_slot].reg_num <= reg_num_in;
                lsq_struct[next_buffer_slot].instr_type <= instr_type_in;

                available_mask[next_buffer_slot] <= 1'b0;

                priority_array[priority_write_ptr] <= next_buffer_slot;
                priority_write_ptr <= priority_write_ptr + 1;
            end

            if(read_en && read_ready) begin
                available_mask[next_ready_instr] <= 1'b1;
                ready_mask[next_ready_instr] <= 1'b0;

                priority_read_ptr <= priority_read_ptr + 1;
            end

            if(line_clear_en) begin
                for(int i = 0; i < NUM_ENTRIES; i = i+1) begin
                    for(int j = 0; j < NUM_THREADS; j = j+1) begin
                        if(lsq_struct[i].target_line[j] == line_clear) begin
                            lsq_struct[i].ready_threads[j] <= 1'b1;
                        end
                        ready_mask <= ready_mask & ready_mask_clear;
                    end
                end
            end

            // this is needed because what if in the previous if block, we set a few instructions to now 
            // being ready and so one of them is chosen and then it locks the cache line again, how else would
            // we know here that the line got locked again
            if(line_lock_en) begin
                for(int i = 0; i < NUM_ENTRIES; i = i+1) begin
                    for(int j = 0; j < NUM_THREADS; j = j+1) begin
                        if(lsq_struct[i].target_line[j] == line_lock) begin
                            lsq_struct[i].ready_threads[j] <= 1'b0;
                        end
                        ready_mask <= ready_mask & ready_mask_clear;
                    end
                end
            end
        end
    end

    // for priority and masking, have additional variable that keeps priority
    // like say, if the fill order is 1,2,3,4,5 then priority is 1,2,3,4,5
    // then 2 gets output, we then have 1,3,4,5. Then 2 gets filled again,
    // new priority becomes 1,3,4,5,2

    always_comb begin
        for(int i = 0; i < NUM_ENTRIES; i = i+1) begin
            address_out[i] = lsq_struct[next_ready_instr].address[i];
            data_out[i] = lsq_struct[next_ready_instr].data[i];
        end
        active_threads_out = lsq_struct[next_ready_instr].active_threads;
        warp_num_out = lsq_struct[next_ready_instr].warp_num;
        reg_num_out = lsq_struct[next_ready_instr].reg_num;
        instr_type_out = lsq_struct[next_ready_instr].instr_type;
    end

    assign full = priority_write_ptr == (priority_read_ptr - 1);
    assign empty = priority_write_ptr == priority_read_ptr;


endmodule

