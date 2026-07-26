// simple DM cache
// multi word cache line
// 2KB

`timescale 1ns / 1ps

module Cache#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16, BLOCK_SIZE = 8, NUM_BLOCKS = 128, IDX_SIZE = $clog2(NUM_BLOCKS))(
    input logic clk, reset,

    // LSU interface
    input logic cache_req, // from control, tells if this is a memory instruction or not

    input logic reg_instr_type_in, // from instruction, tells if store or load, 0 for load, 1 for store
    input logic [1:0] reg_warp_num_in,
    input logic [3:0] reg_reg_num_in,
    input logic [ADDR_WIDTH-1:0] reg_addr_in [BLOCK_SIZE-1:0], // we need the address of each thread in the warp
    input logic [DATA_WIDTH-1:0] reg_data_in [BLOCK_SIZE-1:0], // data from the threadsregister file
    input logic [BLOCK_SIZE-1:0] reg_active_threads_in, // we only worry about the threads that are active
    
    output logic ready,
    output logic [DATA_WIDTH-1:0] load_data_out [BLOCK_SIZE-1:0], // to threads reg file
    output logic cache_req_accepted,
    output logic cache_req_rejected,

    // memory interface
    input logic read_mem_valid, // memory ready to accept read request
    input logic write_mem_valid, // memory ready to accept write data

    input logic mem_read_ready, // we have the data from memory ready, we already read it and its in a buffer
    input logic [DATA_WIDTH-1:0] mem_data_in [BLOCK_SIZE-1:0], // data from main memory
    input logic [ADDR_WIDTH-1:0] mem_addr_in, // address from main memory 

    output logic mem_read_req,
    output logic mem_write_req,
    output logic [ADDR_WIDTH-1:0] mem_addr_out,
    output logic [DATA_WIDTH-1:0] mem_data_out [BLOCK_SIZE-1:0], // to main memory
    );

    // NEED before testing cache funcionality:
    // buffer for data coming back from memory
    // LSQ to hold instructions that are waiting for a cache line to be unlocked

    // Should also check with LSU to make sure the timing of ready/accept/reject signals make sense and are present

    // cache control outputs
    logic refill_accepted;
    logic cache_req_latch;
    // ready, cache_req_accepted, cache_req_rejected
    logic ihb_instr_accepted;
    logic ihb_update_en;
    logic write_en;
    logic wb_seq_active;
    logic alloc_seq_active;
    logic seq_active;
    logic wb_init_mask_valid;
    logic alloc_init_mask_valid;
    // mem_read_req, mem_write_req
    logic refill_active;

    // cache data outputs
    logic [DATA_WIDTH-1:0] cache_data [BLOCK_SIZE-1:0];
    logic [IDX_SIZE-1:0] idx [BLOCK_SIZE-1:0];
    logic [BLOCK_SIZE-1:0] hit, dirty;
    logic locked;
    logic [NUM_THREADS-1:0] wb_init_mask, alloc_init_mask, ihb_init_mask;

    // cache arbiter outputs
    logic [NUM_THREADS-1:0] threads_en;
    logic [$clog2(NUM_BLOCKS)-1:0] cache_line;
    logic seq_over;

    // ihb outputs
    logic ihb_instr_ready;
    logic ihb_full;
    logic [ADDR_WIDTH-1:0] ihb_addr_in [NUM_THREADS-1:0];
    logic [DATA_WIDTH-1:0] ihb_data_in [NUM_THREADS-1:0];
    logic [NUM_THREADS-1:0] ihb_active_threads_in;
    logic [1:0] ihb_warp_num_in;
    logic [3:0] ihb_reg_num_in;
    logic ihb_instr_type_in;

    
    always_comb begin
        if(cache_req_latch) begin
            data_mux_in = reg_data_in;
            addr_mux_in = reg_addr_in;
            active_threads_mux_in = reg_active_threads_in;
            warp_num_mux_in = reg_warp_num_in;
            reg_num_mux_in = reg_reg_num_in;
            instr_type_mux_in = reg_instr_type_in;

        end 
        else if(ihb_instr_accepted) begin
            data_mux_in = ihb_data_in; // ihb INTO the cache, OUT of the ihb
            addr_mux_in = ihb_addr_in; 
            active_threads_mux_in = ihb_active_threads_in;
            warp_num_mux_in = ihb_warp_num_in;
            reg_num_mux_in = ihb_reg_num_in;
            instr_type_mux_in = ihb_instr_type_in;

        end
        else if(refill_accepted || refill_active) begin // maybe don't need this because don't need the data immediately for a refill because no hit logic
            data_mux_in = mem_data_in;
            addr_mux_in = mem_addr_in;
        end
        else begin // go to registers for stored data
            data_mux_in = data_int;
            addr_mux_in = addr_int;
            active_threads_mux_in = active_threads_int;
            warp_num_mux_in = warp_num_int;
            reg_num_mux_in = reg_num_int;
            instr_type_mux_in = instr_type_int;

        end
    end

    always_ff @(posedge clk) begin 
        if(cache_req_latch) begin
            // need to buffer all data/metadata that could be needed for the ihb buffers

            data_int = reg_data_in;
            addr_int = reg_addr_in;
            active_threads_int = reg_active_threads_in;
            warp_num_int = reg_warp_num_in;
            reg_num_int = reg_reg_num_in;
            instr_type_int = reg_instr_type_in;

        end

        else if(refill_accepted) begin
            data_int = mem_data_in;
            addr_int = mem_addr_in;
        end

        else if(ihb_instr_accepted) begin
            data_int = ihb_data_in; // ihb INTO the cache, OUT of the ihb
            addr_int = ihb_addr_in; 
            active_threads_int = ihb_active_threads_in;
            warp_num_int = ihb_warp_num_in;
            reg_num_int = ihb_reg_num_in;
            instr_type_int = ihb_instr_type_in;

        end
    end


    Cache_Control ctrl(
        .clk(clk), .reset(reset),
        .refill_accepted(refill_accepted),
        .cache_req_latch(cache_req_latch),

        .instr_type(instr_type_mux_in),
        .cache_req(cache_req),
        .active_threads(active_threads_mux_in),
        .ready(ready),
        .cache_req_accepted(cache_req_accepted),
        .cache_req_rejected(cache_req_rejected),

        .ihb_instr_ready(ihb_instr_ready),
        .ihb_full(ihb_full),
        .ihb_instr_accepted(ihb_instr_accepted),
        .ihb_update_en(ihb_update_en),

        .locked(locked),
        .hit(hit), .dirty(dirty),
        .write_en(write_en),

        .wb_seq_active(wb_seq_active),
        .alloc_seq_active(alloc_seq_active),

        .seq_over(seq_over),
        .seq_active(seq_active),
        .wb_init_mask_valid(wb_init_mask_valid),
        .alloc_init_mask_valid(alloc_init_mask_valid),

        .mem_read_ready(mem_read_ready),
        .mem_read_req(mem_read_req), .mem_write_req(mem_write_req),
        .refill_active(refill_active);
    );


    // set up a multiplexor to decide what data gets input to the cache data array
    Cache_Data data(
        .clk(clk),
        .reset(reset),
        .addr_in(addr_mux_in),
        .data_in(data_mux_in),
        .threads_en(threads_en),
        .active_threads(active_threads_mux_in),
        .write_en(write_en),
        .refill_active(refill_active),
        .wb_seq_active(wb_seq_active),
        .cache_line(cache_line),
        .alloc_seq_active(alloc_seq_active),

        .data_out(cache_data),
        .idx_out(idx),
        .hit(hit), .dirty(dirty),
        .locked(locked),
        .wb_init_mask(wb_init_mask), .alloc_init_mask(alloc_init_mask), ihb_init_mask(ihb_init_mask)
    );

    Cache_Arbiter arbiter(
        .clk(clk), .reset(reset),
        .seq_active(seq_active),
        .active_threads(active_threads_mux_in),
        .idx(idx),
        .wb_seq_active(wb_seq_active),
        .wb_init_mask_valid(wb_init_mask_valid),
        .wb_init_mask(wb_init_mask),
        .alloc_seq_active(alloc_seq_active),
        .alloc_init_mask_valid(alloc_init_mask_valid),
        .alloc_init_mask(alloc_init_mask),
        .write_mem_valid(write_mem_valid), .read_mem_valid(read_mem_valid),

        .threads_en(threads_en),
        .cache_line(cache_line),
        .seq_over(seq_over)
    );

    Instruction_Hold_Buffers ihb(
        .clk(clk), .reset(reset),
        .ihb_update_en(ihb_update_en),
        .address_in(addr_mux_in),
        .data_in(data_mux_in),
        .active_threads_in(active_threads_mux_in),
        .warp_num_in(warp_num_mux_in),
        .reg_num_in(reg_num_mux_in),
        .instr_type_in(instr_type_mux_in),
        .ihb_init_mask(ihb_init_mask),
        .refill_accepted(refill_accepted),
        .compare_addr(mem_addr_in),

        .ihb_instr_ready(ihb_instr_ready),
        .full(ihb_full),
        .address_out(ihb_addr_in),
        .data_out(ihb_data_in),
        .active_threads_out(ihb_active_threads_in),
        .warp_num_out(ihb_warp_num_in),
        .reg_num_out(ihb_reg_num_in),
        .instr_type_out(ihb_instr_type_in)
    );



endmodule