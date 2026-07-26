// Load Store Unit Revised

`timescale 1ns / 1ps

// LSU will sit between computations and register file, and the L1 cache/shared memory to ease memory transfers
// Simple hazard detection can be set up earlier in the pipeline to see if a pull from the systolic array and a load to the register file will take place in the same clock cycle, and can buffer one of the results if that's the case
// Can probably just do standard stall on all warps non participating in the pull ^ + LSU stall


module LSU#(parameter DATA_WIDTH = 16, ADDR_WIDTH = , SHARED_MEM_ADDR_WIDTH = , NUM_THREADS = 8, MAX_NUM_WARPS = 4, MAX_NUM_REGS = 16, NUM_BLOCKS = , IDX_SIZE = $clog2(NUM_BLOCKS))(
    input clk, reset,

    input instr_valid, // from warp scheduler to confirm a memory instruction was activated in this clock cycle

    // from register file + warp scheduler to memory:
    input logic [DATA_WIDTH-1:0] reg_data_in [NUM_THREADS-1:0],
    input logic [NUM_THREADS-1:0] reg_active_threads_in, // from warp scheduler 
    input logic [$clog2(MAX_NUM_WARPS)-1:0] reg_warp_num_in, // from warp scheduler
    input logic [$clog2(MAX_NUM_REGS)-1:0] reg_reg_num_in, // from warp scheduler by way of instruction
    input logic [1:0] reg_instr_type_in, // from warp scheduler by way of instruction

    // from cache/global mem to reg file:
    input logic cache_ready, // signal from cache to indicate when ready to RECEIVE data
    input logic cache_data_ready, // signal from cache to indicate when ready to SEND data
    input logic [DATA_WIDTH-1:0] cache_data_in [NUM_THREADS-1:0],
    input logic [NUM_THREADS-1:0] cache_active_threads_in, 
    input logic [$clog2(MAX_NUM_WARPS)-1:0] cache_warp_num_in,  
    input logic [$clog2(MAX_NUM_REGS)-1:0] cache_reg_num_in, 
    // input logic [1:0] cache_instr_type_in, dont't need? because if going back to reg file then must be a load

    // from shared mem to reg file:
    input logic shared_mem_ready, // signal from shared memory to indicate when ready to RECEIVE data
    input logic shared_mem_data_ready, // signal from shared memory to indicate when ready to SEND data
    input logic [DATA_WIDTH-1:0] shared_mem_data_in [NUM_THREADS-1:0], // from shared memory, goes to threads reg file
    input logic [NUM_THREADS-1:0] shared_mem_active_threads_in, 
    input logic [$clog2(MAX_NUM_WARPS)-1:0] shared_mem_warp_num_in,  
    input logic [$clog2(MAX_NUM_REGS)-1:0] shared_mem_reg_num_in, 
    // input logic [1:0] shared_mem_instr_type_in, dont't need? because if going back to reg file then must be a load


    input logic line_clear_en, // from cache
    input logic [IDX_SIZE-1:0] line_clear, // from cache when a cache line is unlocked
    input logic line_lock_en, // from cache
    input logic [IDX_SIZE-1:0] line_lock, // from cache when a cache line is locked

    input logic [DATA_WIDTH-1:0] reg_cache_base_addr_reg, // from global reg file (reg to cache)
    input logic [DATA_WIDTH-1:0] reg_cache_stride_reg, // from global reg file
    input logic [DATA_WIDTH-1:0] reg_shared_mem_base_addr_reg, // from glob reg file (reg to shared mem)
    input logic [DATA_WIDTH-1:0] reg_shared_mem_stride_reg,




    // to register file from memory
    output logic [DATA_WIDTH-1:0] mem_data_out [NUM_THREADS-1:0], // shared memory/cache data out to threads register file
    output logic [NUM_THREADS-1:0] mem_active_threads_out, //  to reg file
    output logic [$clog2(MAX_NUM_WARPS)-1:0] mem_warp_num_out, // 
    output logic [$clog2(MAX_NUM_REGS)-1:0] mem_reg_num_out, // 
    // output logic [1:0] mem_instr_type_in, don't need?


    // to cache/global mem from register file/warp scheduler
    output logic [DATA_WIDTH-1:0] reg_cache_data_out [NUM_THREADS-1:0], // to cache
    output logic [ADDR_WIDTH-1:0] cache_addr_out [NUM_THREADS-1:0], // produced internally in the AGU
    output logic [NUM_THREADS-1:0] reg_cache_active_threads_out,  // to cache from warp_scheduler
    output logic [$clog2(MAX_NUM_WARPS)-1:0] reg_cache_warp_num_out,  // to cache from warp_scheduler
    output logic [$clog2(MAX_NUM_REGS)-1:0] reg_cache_reg_num_out,  // to cache from warp_scheduler
    output logic reg_cache_instr_type_out, // to cache from warp_scheduler


    // to shared mem from register file/warp scheduler
    output logic [DATA_WIDTH-1:0] reg_shared_mem_data_out [NUM_THREADS-1:0], // to shared memory
    output logic [SHARED_MEM_ADDR_WIDTH-1:0] shared_mem_addr_out [NUM_THREADS-1:0], // produced internally in the shared_mem_AGU
    output logic [NUM_THREADS-1:0] reg_shared_mem_active_threads_out,  // to shared mem from warp_scheduler
    output logic [$clog2(MAX_NUM_WARPS)-1:0] reg_shared_mem_warp_num_out,  // to shared mem from warp_scheduler
    output logic [$clog2(MAX_NUM_REGS)-1:0] reg_shared_mem_reg_num_out,  // to shared mem from warp_scheduler
    output logic reg_shared_mem_instr_type_out // to shared mem from warp_scheduler

    );

    parameter CACHE_LOAD = 2'b00;
    parameter CACHE_STORE = 2'b01;

    parameter SHARED_MEM_LOAD = 2'b10;
    parameter SHARED_MEM_STORE = 2'b11;

    logic [DATA_WIDTH-1:0] hardwired_threadIdx [NUM_THREADS-1:0];
    logic [ADDR_WIDTH-1:0] addr_out [NUM_THREADS-1:0];

    genvar i;
    generate
        for(i = 0; i < NUM_THREADS; i = i+1) begin
            assign hardwired_threadIdx[i] = (reg_warp_num_in * NUM_THREADS) + i; // hardwired threadIdx for each thread in the warp, used for AGU calculations
        end
    endgenerate

    AGU agu ( 
        .threadIdx(hardwired_threadIdx),
        .base_addr_reg(reg_cache_base_addr_reg),
        .stride_reg(reg_cache_stride_reg),
        .addr(cache_addr_in)
    );
    // Cache should handle non contiguous memory accesses fine

    SM_AGU sm_agu (
        .threadIdx(hardwired_threadIdx),
        .base_addr_reg(reg_shared_mem_base_addr_reg),
        .stride_reg(reg_shared_mem_stride_reg),
        .shared_mem_addr(shared_mem_addr_in)
    );

    logic [NUM_BLOCKS-1:0] locked_lines_mask; // array containing if a cache line is locked (1) or not (0)

    logic mem_decision_bit; // 0 for cache, 1 for shared memory, it decides whether the LSU takes data from cache or shared memory in a given cycle to write back to the register file for load instructions
     // instructions for either shared memory or cache load will be distinct, ie. lds for shared mem and ldg for cache/global
     // if push active, then decision bit will always for 1 for shared memory
    logic collision_bit;
    assign collision_bit = (cache_data_ready && shared_mem_data_ready); 

    always_ff @(posedge clk) begin
        if(reset) begin
            mem_decision_bit <= 0;
            locked_lines_mask <= '0;
        end
        else begin 
            if (collision_bit) begin
                mem_decision_bit <= ~mem_decision_bit; // flip the bit each time there's a collision to alternate between cache and shared memory for load instructions
            end

            if(line_lock_en) begin
                locked_lines_mask[line_lock] <= 1'b1;
            end
            else if(line_clear_en) begin
                locked_lines_mask[line_clear] <= 1'b0;
            end
        end
    end


    logic [IDX_SIZE-1:0] instr_target_lines [NUM_THREADS-1:0];
    logic [NUM_THREADS-1:0] lsq_ready_threads_in;
    always_comb begin
        for(int i = 0; i < NUM_THREADS; i = i+1) begin
            instr_target_lines[i] <= cache_addr_in[i][ADDR_WIDTH-TAG_WIDTH-1 -: IDX_SIZE];
        end

        for(int i = 0; i < NUM_THREADS; i = i+1) begin
            lsq_ready_threads_in[i] = !locked_lines_mask[instr_target_lines[i]];
        end
    end


    logic lsq_empty, lsq_full;
    logic reg_shared_mem_buffer_empty, reg_shared_mem_buffer_full;
    logic cache_buffer_empty, cache_buffer_full;
    logic shared_mem_buffer_empty, shared_mem_buffer_full;

    logic lsq_write_en, lsq_read_en;
    logic reg_shared_mem_buffer_write_en, reg_shared_mem_buffer_read_en;
    logic cache_buffer_write_en, cache_buffer_read_en;
    logic shared_mem_buffer_write_en, shared_mem_buffer_read_en;

    logic cache_consumed;
    logic shared_consumed;



    logic [ADDR_WIDTH-1:0] cache_addr_in [NUM_THREADS-1:0]; // produced by AGU

    logic [DATA_WIDTH-1:0] reg_cache_data_out_buffer [NUM_THREADS-1:0];
    logic [ADDR_WIDTH-1:0] reg_cache_addr_out_buffer [NUM_THREADS-1:0];
    logic [$clog2(MAX_NUM_REGS)-1:0] reg_cache_reg_num_out_buffer;
    logic [$clog2(MAX_NUM_WARPS)-1:0] reg_cache_warp_num_out_buffer;
    logic [NUM_THREADS-1:0] reg_cache_active_threads_out_buffer;
    logic reg_cache_instr_type_out_buffer;
    logic lsq_instr_ready;

    LSQ lsq(
        .clk(clk), .reset(reset),
        .write_en(lsq_write_en), .read_en(lsq_read_en),
        // all of these will be decided by a multiplexor depending on if new instruction coming in and if old instruction was rejected from cache b/c line was locked
        .ready_threads_in(lsq_ready_threads_in),
        .data_in(reg_data_in),
        .address_in(cache_addr_in),
        .reg_num_in(reg_reg_num_in),
        .warp_num_in(reg_warp_num_in),
        .active_threads_in(reg_active_threads_in),
        .instr_type_in(reg_instr_type_in[0]),

        .line_clear_en(line_clear_en),
        .line_clear(line_clear),
        .line_lock_en(line_lock_en),
        .line_lock(line_lock),


        .data_out(reg_cache_data_out_buffer),
        .address_out(reg_cache_addr_out_buffer),
        .reg_num_out(reg_cache_reg_num_out_buffer),
        .warp_num_out(reg_cache_warp_num_out_buffer),
        .active_threads_out(reg_cache_active_threads_out_buffer),
        .instr_type_out(reg_cache_instr_type_out_buffer),
        
        .ready(lsq_instr_ready),
        .empty(lsq_empty), .full(lsq_full)
    ); // to cache from reg file


    logic [SHARED_MEM_ADDR_WIDTH-1:0] shared_mem_addr_in [NUM_THREADS-1:0]; // produced by shared mem AGU

    logic [DATA_WIDTH-1:0] reg_shared_mem_data_out_buffer [NUM_THREADS-1:0];
    logic [ADDR_WIDTH-1:0] reg_shared_mem_addr_out_buffer [NUM_THREADS-1:0];
    logic [$clog2(MAX_NUM_REGS)-1:0] reg_shared_mem_reg_num_out_buffer;
    logic [$clog2(MAX_NUM_WARPS)-1:0] reg_shared_mem_warp_num_out_buffer;
    logic [NUM_THREADS-1:0] reg_shared_mem_active_threads_out_buffer;
    logic reg_shared_mem_instr_type_out_buffer;

    FIFO_Buffer reg_data_shared_mem_buffer(
        .clk(clk), .reset(reset),
        .write_en(reg_shared_mem_buffer_write_en), .read_en(reg_shared_mem_buffer_read_en),
        .data_in(reg_data_in),
        .address_in(shared_mem_addr_in),
        .reg_num_in(reg_reg_num_in),
        .warp_num_in(reg_warp_num_in),
        .active_threads_in(reg_active_threads_in),
        .instr_type_in(reg_instr_type_in[0]), // (only one bit, so whichever of the 2 bits dictates whether it's a load or a store)

        .data_out(reg_shared_mem_data_out_buffer),
        .address_out(reg_shared_mem_addr_out_buffer),
        .reg_num_out(reg_shared_mem_reg_num_out_buffer),
        .warp_num_out(reg_shared_mem_warp_num_out_buffer),
        .active_threads_out(reg_shared_mem_active_threads_out_buffer),
        .instr_type_out(reg_shared_mem_instr_type_out_buffer),
        .empty(reg_shared_mem_buffer_empty), .full(reg_shared_mem_buffer_full)
    ); // to shared mem from reg file

    logic [DATA_WIDTH-1:0] cache_data_out_buffer [NUM_THREADS-1:0];
    logic [$clog2(MAX_NUM_REGS)-1:0] cache_reg_num_out_buffer;
    logic [$clog2(MAX_NUM_WARPS)-1:0] cache_warp_num_out_buffer;
    logic [NUM_THREADS-1:0] cache_active_threads_out_buffer;

    FIFO_Buffer cache_data_buffer(
        .clk(clk), .reset(reset),
        .write_en(cache_buffer_write_en), .read_en(cache_buffer_read_en),
        .data_in(cache_data_in),
        // .address_in(),
        .reg_num_in(cache_reg_num_in),
        .warp_num_in(cache_warp_num_in),
        .active_threads_in(cache_active_threads_in),
        // .instr_type_in(),

        .data_out(cache_data_out_buffer),
        // .address_out(), don't need bc data just going back to reg file, so only need reg num, warp num, and active threads for where to put data
        .reg_num_out(cache_reg_num_out_buffer),
        .warp_num_out(cache_warp_num_out_buffer),
        .active_threads_out(cache_active_threads_out_buffer),
        // .instr_type_out(),
        .empty(cache_buffer_empty), .full(cache_buffer_full)
    ); // from cache to reg file

    logic [DATA_WIDTH-1:0] shared_mem_data_out_buffer [NUM_THREADS-1:0];
    logic [$clog2(MAX_NUM_REGS)-1:0] shared_mem_reg_num_out_buffer;
    logic [$clog2(MAX_NUM_WARPS)-1:0] shared_mem_warp_num_out_buffer;
    logic [NUM_THREADS-1:0] shared_mem_active_threads_out_buffer;

    FIFO_Buffer shared_mem_data_buffer(
        .clk(clk), .reset(reset),
        .write_en(shared_mem_buffer_write_en), .read_en(shared_mem_buffer_read_en),
        .data_in(shared_mem_data_in),
        // .address_in(),
        .reg_num_in(shared_mem_reg_num_in),
        .warp_num_in(shared_mem_warp_num_in),
        .active_threads_in(shared_mem_active_threads_in),
        // .instr_type_in(),

        .data_out(shared_mem_data_out_buffer),
        // .address_out(),
        .reg_num_out(shared_mem_reg_num_out_buffer),
        .warp_num_out(shared_mem_warp_num_out_buffer),
        .active_threads_out(shared_mem_active_threads_out_buffer),
        // .instr_type_out(),
        .empty(shared_mem_buffer_empty), .full(shared_mem_buffer_full)
    ); // from shared memory to reg file


    always_comb begin
        // flattened and corrected logic: 

        lsq_write_en = 1'b0;
        lsq_read_en = 1'b0;
        reg_shared_mem_buffer_write_en = 1'b0;
        reg_shared_mem_buffer_read_en = 1'b0;

        cache_buffer_write_en = 1'b0;
        cache_buffer_read_en = 1'b0;
        shared_mem_buffer_write_en = 1'b0;
        shared_mem_buffer_read_en = 1'b0;
        
        reg_cache_data_out = '0;
        cache_addr_out = '0;
        reg_cache_active_threads_out = '0;
        reg_cache_warp_num_out = '0;
        reg_cache_reg_num_out = '0;
        reg_cache_instr_type_out = '0;


        reg_shared_mem_data_out = '0;
        shared_mem_addr_out = '0;
        reg_shared_mem_active_threads_out = '0;
        reg_shared_mem_warp_num_out = '0;
        reg_shared_mem_reg_num_out = '0;
        reg_shared_mem_instr_type_out = '0;


        mem_data_out = '0;
        mem_active_threads_out = '0;
        mem_warp_num_out = '0;
        mem_reg_num_out = '0;

        
        cache_consumed = 1'b0;
        shared_consumed = 1'b0;

        // for store, need to send just data and address
        // for load, need to send address + metadata so can match to correct thread when data comes back

        // reg checking (for store, reg file data -> LSU -> memory)
        // will need to expand buffer atleast for going to cache because needs address, etc.
        // Also need to add stall logic if there are more stores while the buffers are full
        // Priority 1: If buffer has data, memory output MUST be the buffer data.


        if(lsq_instr_ready) begin // if any instructions are ready in the lsq
            reg_cache_data_out = reg_cache_data_out_buffer;
            cache_addr_out = reg_cache_addr_out_buffer;
            reg_cache_active_threads_out = reg_cache_active_threads_out_buffer;
            reg_cache_warp_num_out = reg_cache_warp_num_out_buffer;
            reg_cache_reg_num_out = reg_cache_reg_num_out_buffer;
            reg_cache_instr_type_out = reg_cache_instr_type_out_buffer;

            lsq_read_en = cache_ready;
            if(reg_instr_type_in[1] == 1'b0) begin // cache/global mem instruction
                lsq_write_en = 1;
            end
        end
        // We can decide to change this later, idk if it's actually more efficient to only drive the needed wires, or if should just drive all of them
        else if(cache_ready && (&lsq_ready_threads_in)) begin // only send instruction if cache is ready and all needed cache lines are unlocked
            if(reg_instr_type_in == CACHE_LOAD) begin
                cache_addr_out = cache_addr_in; // address produced by AGU
                reg_cache_active_threads_out = reg_active_threads_in;
                reg_cache_warp_num_out = reg_warp_num_in;
                reg_cache_reg_num_out = reg_reg_num_in;
                reg_cache_instr_type_out = reg_instr_type_in[0];

                lsq_write_en = 0;
            end
            else if(reg_instr_type_in == CACHE_STORE) begin
                reg_cache_data_out = reg_data_in;
                cache_addr_out = cache_addr_in; // address produced by AGU

                lsq_write_en = 0;
            end
        end
        else if(reg_instr_type_in[1] == 1'b0) begin // cache/global mem instruction
            lsq_write_en = 1;
        end
        
        


        // shared mem
        if (!reg_shared_mem_buffer_empty) begin // if not empty
            reg_shared_mem_data_out = reg_shared_mem_data_out_buffer;
            shared_mem_addr_out = reg_shared_mem_addr_out_buffer;
            reg_shared_mem_active_threads_out = reg_shared_mem_active_threads_out_buffer;
            reg_shared_mem_warp_num_out = reg_shared_mem_warp_num_out_buffer;
            reg_shared_mem_reg_num_out = reg_shared_mem_reg_num_out_buffer;
            reg_shared_mem_instr_type_out = reg_shared_mem_instr_type_out_buffer;

            reg_shared_mem_buffer_read_en = shared_mem_ready;
            if (reg_instr_type_in[1] == 1'b1) begin // shared mem instruction
                reg_shared_mem_buffer_write_en = 1;
            end
        end 
        if(shared_mem_ready) begin
            if(reg_instr_type_in == SHARED_MEM_LOAD) begin
                shared_mem_addr_out = shared_mem_addr_in; // address produced by shared mem AGU
                reg_shared_mem_active_threads_out = reg_active_threads_in;
                reg_cache_warp_num_out = reg_warp_num_in;
                reg_cache_reg_num_out = reg_reg_num_in;
                reg_shared_mem_instr_type_out = reg_instr_type_in[0];

                shared_mem_buffer_write_en = 0;
            end
            else if(reg_instr_type_in == SHARED_MEM_STORE) begin
                reg_shared_mem_data_out = reg_data_in;
                shared_mem_addr_out = shared_mem_addr_in; // produced my shared mem AGU

                shared_mem_buffer_write_en = 0;
            end
        end
        else if(reg_instr_type_in[1] == 1'b1) begin // shared mem instruction
            shared_mem_buffer_write_en = 1'b1;
        end




        // cache + shared memory checking (for load, shared memory/cache -> LSU -> reg file)
        case ({!cache_buffer_empty, !shared_mem_buffer_empty})
            2'b00: begin // both buffers empty
                if (cache_data_ready && shared_mem_data_ready) begin
                    if (!mem_decision_bit) begin
                        mem_data_out = cache_data_in;
                        
                        mem_active_threads_out = cache_active_threads_in;
                        mem_warp_num_out = cache_warp_num_in;
                        mem_reg_num_out = cache_reg_num_in;

                        cache_consumed = 1;
                    end else begin
                        mem_data_out = shared_mem_data_in;

                        mem_active_threads_out = shared_mem_active_threads_in;
                        mem_warp_num_out = shared_mem_warp_num_in;
                        mem_reg_num_out = shared_mem_reg_num_in;

                        shared_consumed = 1;
                    end
                end else if (cache_data_ready) begin
                    mem_data_out = cache_data_in;
                    mem_active_threads_out = cache_active_threads_in;
                    mem_warp_num_out = cache_warp_num_in;
                    mem_reg_num_out = cache_reg_num_in;

                    cache_consumed = 1;
                end else if (shared_mem_data_ready) begin
                    mem_data_out = shared_mem_data_in;
                    mem_active_threads_out = shared_mem_active_threads_in;
                    mem_warp_num_out = shared_mem_warp_num_in;
                    mem_reg_num_out = shared_mem_reg_num_in;

                    shared_consumed = 1;
                end
            end
            2'b10: begin // Cache buffer has data
                mem_data_out = cache_data_out_buffer;
                mem_active_threads_out = cache_active_threads_out_buffer;
                mem_warp_num_out = cache_warp_num_out_buffer;
                mem_reg_num_out = cache_reg_num_out_buffer;

                cache_consumed = 1;
                cache_buffer_read_en = 1;
            end

            2'b01: begin // Shared mem buffer has data
                mem_data_out = shared_mem_data_out_buffer;
                mem_active_threads_out = shared_mem_active_threads_out_buffer;
                mem_warp_num_out = shared_mem_warp_num_out_buffer;
                mem_reg_num_out = shared_mem_reg_num_out_buffer;

                shared_consumed = 1;
                shared_mem_buffer_read_en = 1;
            end

            2'b11: begin // Boths buffers have data, Use decision bit to choose one buffer
                if (!mem_decision_bit) begin
                    mem_data_out = cache_data_out_buffer;
                    mem_active_threads_out = cache_active_threads_out_buffer;
                    mem_warp_num_out = cache_warp_num_out_buffer;
                    mem_reg_num_out = cache_reg_num_out_buffer;

                    cache_consumed = 1;
                    cache_buffer_read_en = 1;
                end else begin
                    mem_data_out = shared_mem_data_out_buffer;
                    mem_active_threads_out = shared_mem_active_threads_out_buffer;
                    mem_warp_num_out = shared_mem_warp_num_out_buffer;
                    mem_reg_num_out = shared_mem_reg_num_out_buffer;

                    shared_consumed = 1;
                    shared_mem_buffer_read_en = 1;
                end
            end

            default: begin end
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
