// Load Store Unit Revised

`timescale 1ns / 1ps

// LSU will sit between computations and register file, and the L1 cache/shared memory to ease memory transfers
// Simple hazard detection can be set up earlier in the pipeline to see if a pull from the systolic array and a load to the register file will take place in the same clock cycle, and can buffer one of the results if that's the case
// Can probably just do standard stall on all warps non participating in the pull ^ + LSU stall
module LSU#(parameter DATA_WIDTH = 16, ADDR_WIDTH = , NUM_THREADS = 8)(
    input clk, reset,
    input mem_read_req, mem_write_req,
    input [NUM_THREADS-1:0] mem_read_threads_en, mem_write_threads_en,
    input cache_ready, shared_mem_ready, // signals from cache and shared memory to indicate when ready

    input logic [1:0] reg_warp_num, cache_warp_num,
    input logic [1:0] instr_type, // load, load from memory, load from shared memory

    // input logic [ADDR_WIDTH-1:0] addr [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] reg_data_in [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] cache_data_in [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] shared_mem_data_in [NUM_THREADS-1:0], // from shared memory, goes to threads reg file


    output logic [DATA_WIDTH-1:0] reg_cache_data_out [NUM_THREADS-1:0] // to cache
    output logic [DATA_WIDTH-1:0] reg_shared_mem_data_out [NUM_THREADS-1:0] // to shared memory
    output logic [DATA_WIDTH-1:0] mem_data_out [NUM_THREADS-1:0] // shared memory/cache data out to threads register file
    );

    logic reg_cache_buffer_empty, reg_cache_buffer_full;
    logic reg_shared_mem_buffer_empty, reg_shared_mem_buffer_full;
    logic cache_buffer_empty, cache_buffer_full;
    logic shared_mem_buffer_empty, shared_mem_buffer_full;

    logic [DATA_WIDTH-1:0] reg_cache_data_out_buffer [NUM_THREADS-1:0];
    logic [DATA_WIDTH-1:0] reg_shared_mem_data_out_buffer [NUM_THREADS-1:0];
    logic [DATA_WIDTH-1:0] cache_data_out [NUM_THREADS-1:0];
    logic [DATA_WIDTH-1:0] shared_mem_data_out [NUM_THREADS-1:0];

    logic [DATA_WIDTH-1:0] reg_data_in_buffer [NUM_THREADS-1:0];

    logic mem_decision_bit; // 0 for cache, 1 for shared memory, it decides whether the LSU takes data from cache or shared memory to write back to the register file for load instructions, flip each time

    AGU agu ( // acceptable for loads and stores currently as we'll load from and store to contiguous memory
        .reset(reset),
        .threadIdx(threadIdx),
        .warp_num(warp_num),
        .base_addr_reg(base_addr_reg),
        .base_addr_imm(base_addr_imm),
        .addr(addr_temp)
    ); // Maybe can modify this using the global register file to allow non contiguous memory accesses using different offsets held in the global register file
    // Cache should handle non contiguous memory accesses fine

    FIFO_Buffer reg_data_cache_buffer(
        .clk(clk), .reset(reset),
        .write_en(), .read_en(),
        .data_in(reg_data_in_buffer),
        .data_out(reg_cache_data_out_buffer),
        .empty(reg_cache_buffer_empty), .full(reg_cache_buffer_full)
    ); // to cache from reg file

    FIFO_Buffer reg_data_shared_mem_buffer(
        .clk(clk), .reset(reset),
        .write_en(), .read_en(),
        .data_in(reg_data_in_buffer),
        .data_out(reg_shared_mem_data_out_buffer),
        .empty(reg_shared_mem_buffer_empty), .full(reg_shared_mem_buffer_full)
    ); // to shared mem from reg file

    FIFO_Buffer cache_data_buffer(
        .clk(clk), .reset(reset),
        .write_en(), .read_en(),
        .data_in(cache_data_in),
        .data_out(cache_data_out)
        .empty(cache_buffer_empty), .full(cache_buffer_full)
    ); // from cache to reg file

    FIFO_Buffer shared_mem_data_buffer(
        .clk(clk), .reset(reset),
        .write_en(), .read_en(),
        .data_in(shared_mem_data_in),
        .data_out(shared_mem_data_out),
        .empty(shared_mem_buffer_empty), .full(shared_mem_buffer_full)
    ); // from shared memory to reg file

    // NEED: Multiplexor logic to decide bewteen shared memory and cache data for mem_data_out

    always_ff@(posedge clk) begin
        if(reset) begin
            
        end
        else begin
            mem_decision_bit <= ~mem_decision_bit; // flip the bit each time to alternate between cache and shared memory for load instructions
        end
    end

    always_comb begin
        reg_cache_buffer_write_en = 0;
        reg_cache_buffer_read_en = 0;
        reg_shared_mem_buffer_write_en = 0;
        reg_shared_mem_buffer_read_en = 0;

        cache_buffer_write_en = 0;
        cache_buffer_read_en = 0;
        shared_mem_buffer_write_en = 0;
        shared_mem_buffer_read_en = 0;


        // default behavior of each buffer:
        if(cache_ready && !reg_cache_buffer_empty) begin
            reg_cache_data_out = reg_cache_data_out_buffer;
            reg_cache_buffer_write_en = 0;
            reg_cache_buffer_read_en = 1;
        end
        else begin
            // do nothing
        end
        
        if(shared_mem_ready && !reg_shared_mem_buffer_empty) begin
            reg_shared_mem_data_out = reg_shared_mem_data_out_buffer;
            reg_shared_mem_buffer_write_en = 0;
            reg_shared_mem_buffer_read_en = 1;
        end
        else begin
            // do nothing
        end


        // reg checking (for store, reg file data -> LSU)
        // will need to expand buffer atleast for going to cache because needs address, etc.
        if(instr_type == CACHE_STORE) begin
            if(cache_ready) begin
                if(reg_cache_buffer_empty) begin // if there's nothing in the buffer
                    reg_cache_data_out = reg_data_in;
                    reg_cache_buffer_write_en = 0;
                    reg_cache_buffer_read_en = 0;
                end
                else begin
                    reg_cache_data_out = reg_cache_data_out_buffer;

                    // into buffer
                    reg_data_in_buffer = reg_data_in;

                    // en signals
                    reg_cache_buffer_write_en = 1;
                    reg_cache_buffer_read_en = 1;
                end
            end
            else begin
                if(reg_cache_buffer_full) begin
                    // stall processor
                end
                reg_cache_buffer_write_en = 1;
                reg_cache_buffer_read_en = 0;
            end
        end

        else if(instr_type == SHARED_MEM_STORE) begin
            if(shared_mem_ready) begin
                if(reg_shared_mem_buffer_empty) begin // if there's nothing in the buffer
                    reg_shared_mem_data_out = reg_data_in;
                    reg_shared_mem_buffer_write_en = 0;
                    reg_shared_mem_buffer_read_en = 0;
                end
                else begin
                    reg_shared_mem_data_out = reg_shared_mem_data_out_buffer;

                    // into buffer
                    reg_data_in_buffer = reg_data_in;

                    // en signals
                    reg_shared_mem_buffer_write_en = 1;
                    reg_shared_mem_buffer_read_en = 1;
                end
            end
            else begin
                if(reg_shared_mem_buffer_full) begin
                    // stall processor
                end
                reg_shared_mem_buffer_write_en = 1;
                reg_shared_mem_buffer_read_en = 0;
            end
        end
        else begin
            // do nothing
        end

        // cache + shared memory checking (for load, shared memory/cache -> LSU)
        if(cache_buffer_empty && shared_mem_buffer_empty) begin
            if(cache_data_ready && shared_mem_data_ready) begin
                if(!mem_decision_bit) begin // cache selected
                    mem_data_out = cache_data_in;
                    shared_mem_buffer_write_en = 1;
                end
                else begin
                    mem_data_out = shared_mem_data_in;
                    cache_buffer_write_en = 1;
                end
            end
            else if(cache_data_ready) begin
                mem_data_out = cache_data_in;
            end
            else if(shared_mem_data_ready) begin
                mem_data_out = shared_mem_data_in;
            end
            else begin
                // do nothing
            end
        end

        else if(!cache_buffer_empty && shared_mem_buffer_empty) begin
            mem_data_out = cache_data_out;
            cache_buffer_read_en = 1;

            if(cache_data_ready) begin
                cache_buffer_write_en = 1;
            end
            else begin
                // do nothing
            end

            if(shared_mem_data_ready) begin
                shared_mem_buffer_write_en = 1;
            end
            else begin
                // do nothing
            end
        end

        else if(cache_buffer_empty && !shared_mem_buffer_empty) begin
            mem_data_out = shared_mem_data_out;
            shared_mem_buffer_read_en = 1;

            if(shared_mem_data_ready) begin
                shared_mem_buffer_write_en = 1;
            end
            else begin
                // do nothing
            end

            if(cache_data_ready) begin
                cache_buffer_write_en = 1;
            end
            else begin
                // do nothing
            end
        end

        else begin
            // if both buffers have data, can prioritize cache over shared memory or vice versa depending on mem_decision_bit
            if(!mem_decision_bit) begin
                mem_data_out = cache_data_out;
                cache_buffer_read_en = 1;

                if(cache_data_ready) begin
                    cache_buffer_write_en = 1;
                end
                else begin
                    // do nothing
                end

                if(shared_mem_data_ready) begin
                    shared_mem_buffer_write_en = 1;
                end
                else begin
                    // do nothing
                end
            end
            else begin
                mem_data_out = shared_mem_data_out;
                shared_mem_buffer_read_en = 1;

                if(shared_mem_data_ready) begin
                    shared_mem_buffer_write_en = 1;
                end
                else begin
                    // do nothing
                end

                if(cache_data_ready) begin
                    cache_buffer_write_en = 1;
                end
                else begin
                    // do nothing
                end
            end
        end

        // flattened and corrected logic: 

        reg_cache_buffer_write_en       = 0;
        reg_cache_buffer_read_en        = 0;
        reg_shared_mem_buffer_write_en  = 0;
        reg_shared_mem_buffer_read_en   = 0;
        cache_buffer_write_en           = 0;
        cache_buffer_read_en            = 0;
        shared_mem_buffer_write_en      = 0;
        shared_mem_buffer_read_en       = 0;
        
        mem_data_out                    = 0;

        logic cache_consumed;
        logic shared_mem_consumed;
        cache_consumed = 0;
        shared_mem_consumed = 0;

        // reg checking (for store, reg file data -> LSU -> memory)
        // will need to expand buffer atleast for going to cache because needs address, etc.
        // Also need to add stall logic if there are more stores while the buffers are full
        // Priority 1: If buffer has data, memory output MUST be the buffer data.
        if (!reg_cache_buffer_empty) begin
            reg_cache_data_out = reg_cache_data_out_buffer;
            reg_cache_buffer_read_en = cache_ready; // Drain if memory allows
            // If a store is also happening, we must buffer the new data (Push-Pull)
            if (instr_type == CACHE_STORE) begin
                reg_cache_buffer_write_en = 1;
            end
        end 
        // Priority 2: Buffer is empty. Check for bypass or buffering new stores.
        else if (instr_type == CACHE_STORE) begin
            if (cache_ready) begin
                reg_cache_data_out = reg_data_in; // Direct Bypass
                reg_cache_buffer_write_en = 0;
            end else begin
                reg_cache_data_out = reg_cache_data_out_buffer; // Hold (don't care)
                reg_cache_buffer_write_en = 1; // Must buffer because memory isn't ready
            end
        end 
        // Default: Nothing to send
        else begin
            reg_cache_data_out = reg_cache_data_out_buffer;
        end

        // shared mem
        if (!reg_shared_mem_buffer_empty) begin
            reg_shared_mem_data_out = reg_shared_mem_data_out_buffer;
            reg_shared_mem_buffer_read_en = shared_mem_ready;
            if (instr_type == SHARED_MEM_STORE) begin
                reg_shared_mem_buffer_write_en = 1;
            end
        end 
        else if (instr_type == SHARED_MEM_STORE) begin
            if (shared_mem_ready) begin
                reg_shared_mem_data_out = reg_data_in;
                reg_shared_mem_buffer_write_en = 0;
            end else begin
                reg_shared_mem_data_out = reg_shared_mem_data_out_buffer;
                reg_shared_mem_buffer_write_en = 1;
            end
        end 
        else begin
            reg_shared_mem_data_out = reg_shared_mem_data_out_buffer;
        end


        // cache + shared memory checking (for load, shared memory/cache -> LSU -> reg file)
        case ({!cache_buffer_empty, !shared_mem_buffer_empty})
            2'b00: begin // both buffers empty
                if (cache_data_ready && shared_mem_data_ready) begin
                    if (!mem_decision_bit) begin
                        mem_data_out = cache_data_in;
                        cache_consumed = 1;
                    end else begin
                        mem_data_out = shared_mem_data_in;
                        shared_consumed = 1;
                    end
                end else if (cache_data_ready) begin
                    mem_data_out = cache_data_in;
                    cache_consumed = 1;
                end else if (shared_mem_data_ready) begin
                    mem_data_out = shared_mem_data_in;
                    shared_consumed = 1;
                end
            end
            2'b10: begin // Cache buffer has data
                mem_data_out = cache_data_out;
                cache_consumed = 1;
                cache_buffer_read_en = 1;
            end

            2'b01: begin // Shared mem buffer has data
                mem_data_out = shared_mem_data_out;
                shared_consumed = 1;
                shared_mem_buffer_read_en = 1;
            end

            2'b11: begin // Boths buffers have data, Use decision bit to choose one buffer
                if (!mem_decision_bit) begin
                    mem_data_out = cache_data_out;
                    cache_consumed = 1;
                    cache_buffer_read_en = 1;
                end else begin
                    mem_data_out = shared_mem_data_out;
                    shared_consumed = 1;
                    shared_mem_buffer_read_en = 1;
                end
            end
        endcase

        if (cache_data_ready) begin
            if (!cache_consumed || cache_buffer_read_en) begin
                cache_buffer_write_en = 1;
            end
        end

        if (shared_mem_data_ready) begin
            if (!shared_consumed || shared_mem_buffer_read_en) begin
                shared_mem_buffer_write_en = 1;
            end
        end

    end


endmodule