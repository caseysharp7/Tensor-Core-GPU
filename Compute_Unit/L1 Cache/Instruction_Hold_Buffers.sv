// Cache Busy Warps Registers
// If a warp has a memory access that misses, it will then send a request to main
// memory. In order for this to not stall the cache for the duration of the main
// memory access, we will hold important information about the request in Registers
// here, which will then allow the cache to resolve the warp memory access once
// the memory is ready

`timescale 1ns / 1ps

module Instruction_Hold_Buffers#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16, BLOCK_SIZE = 8, NUM_THREADS = 8, DEPTH = 16)(
    input logic clk, reset,
    input logic ihb_update_en, // enable signal to update the busy warp registers
    input logic [ADDR_WIDTH-1:0] address_in [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] data_in [NUM_THREADS-1:0],
    input logic [NUM_THREADS-1:0] active_threads_in,
    input logic [1:0] warp_num_in,
    input logic [3:0] reg_num_in,
    input logic instr_type_in, // load or store, 0 for load, 1 for store
    input logic [7:0] ihb_init_mask,

    input logic refill_accepted,
    input logic [ADDR_WIDTH-1:0] compare_addr,

    output logic ihb_instr_ready,
    output logic full,

    output logic [ADDR_WIDTH-1:0] address_out [NUM_THREADS-1:0],
    output logic [DATA_WIDTH-1:0] data_out [NUM_THREADS-1:0],
    output logic [NUM_THREADS-1:0] active_threads_out,
    output logic [1:0] warp_num_out,
    output logic [3:0] reg_num_out,
    output logic instr_type_out
    );
    // need to add buffer full logic

    logic [IDX_SIZE-1:0] compare_cache_line; // the cache line that is returning from memory, equivalent to the index

    assign compare_cache_line = compare_addr[ADDR_WIDTH-TAG_WIDTH-1 -: IDX_SIZE];

    logic [IDX_SIZE-1:0] idx_in [NUM_THREADS-1:0];
    always_comb begin
        for(int i = 0; i < NUM_THREADS; i = i+1) begin
            idx_in[i] = address_in[ADDR_WIDTH-TAG_WIDTH-1 -: IDX_SIZE]
        end
    end

    typedef struct{
        logic valid;
        logic [ADDR_WIDTH-1:0] address [NUM_THREADS-1:0];
        logic [IDX_SIZE-1:0] idx [NUM_THREADS-1:0];
        logic [DATA_WIDTH-1:0] data [NUM_THREADS-1:0];
        logic [NUM_THREADS-1:0] active_threads;
        logic [1:0] warp_num;
        logic [3:0] reg_num;
        logic instr_type;

        logic [NUM_THREADS:0] ihb_mask;
    } instruction_hold_buffer_t;

    cache_busy_warp_t instruction_buffer [DEPTH-1:0];
    logic [DEPTH-1:0] busy_buffers;
    logic [$clog2(DEPTH)-1:0] first_available;
    logic [$clog2(DEPTH)-1:0] complete_buffer;

    assign full = &(busy_buffers);

    always_comb begin
        for(int i = 0; i < DEPTH; i = i+1) begin
            if(!busy_buffers[i]) begin
                first_available = i;
                break;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < DEPTH; i++) begin
                instruction_buffer[i].valid <= 0;
                for (int j = 0; j < NUM_THREADS; j++) begin
                    instruction_buffer[i].address[j] <= 0;
                    instruction_buffer[i].idx[j] <= 0;
                    instruction_buffer[i].data[j] <= 0;
                end
                instructions_buffer[i].active_threads <= 0;
                instruction_buffer[i].warp_num <= 0;
                instruction_buffer[i].reg_num <= 0;
                instruction_buffer[i].instr_type <= 0;
                instruction_buffer[i].ihb_mask <= 0;
                busy_buffers[i] <= 0;
            end
        end
        else if(ihb_update_en) begin
            instruction_buffer[first_available].valid <= 1;
            for (int j = 0; j < NUM_THREADS; j++) begin
                instruction_buffer[first_available].address[j] <= address_in[j];
                instruction_buffer[first_available].idx[j] <= idx_in[j];
                instruction_buffer[first_available].data[j] <= data_in[j];
            end
            instruction_buffer[first_available].active_threads <= active_threads_in;
            instruction_buffer[first_available].warp_num <= warp_num_in;
            instruction_buffer[first_available].reg_num <= reg_num_in;
            instruction_buffer[first_available].instr_type <= instr_type_in;
            instruction_buffer[first_available].ihb_mask <= ihb_init_mask;

            busy_buffers[first_available] = 1'b1;
        end
        
        if(refill_accepted) begin 
            for(int i = 0; i < DEPTH; i = i+1) begin 
                for(int j = 0; j < NUM_THREADS; j = j+1) begin
                    if((instruction_buffer[i].idx[j] == compare_cache_line) && busy_buffers[i]) begin
                        instruction_buffer[i].ihb_mask[j] = 1'b1;
                    end
                end
            end
        end
    end

    always_comb begin
        for(int i = 0; i < DEPTH; i = i+1) begin
            if(instruction_buffer[i].ihb_mask == 8'b1111_1111) begin
                ihb_instr_ready = 1;
                complete_buffer = i;
                break;
            end
        end

        if(ihb_instr_accepted) begin
            instruction_buffer[complete_buffer].ihb_mask = 8'd0;
            busy_buffers[complete_buffer] = 1'b0;
        end


        for (int i = 0; i < NUM_THREADS; i++) begin
            address_out[i] = instruction_buffer[complete_buffer].address[i];
            data_out[i] = instruction_buffer[complete_buffer].data[i];
        end
        active_threads_out = instruction_buffer[complete_buffer].active_threads;
        warp_num_out = instruction_buffer[complete_buffer].warp_num;
        reg_num_out = instruction_buffer[complete_buffer].reg_num;
        instr_type_out = instruction_buffer[complete_buffer].instr_type;

    end

endmodule