// simple DM cache
// multi word cache line
// 2KB

module Cache#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16, BLOCK_SIZE = 8, NUM_BLOCKS = 128, IDX_SIZE = $clog2(NUM_BLOCKS))(
    input logic clk, reset,
    input logic read_mem_ready, write_mem_ready, // from main memory
    input logic store, // from instruction, tells if store or load
    input logic [ADDR_WIDTH-1:0] address [BLOCK_SIZE-1:0], // we need the address of each thread in the warp
    input logic [DATA_WIDTH-1:0] reg_data_in [BLOCK_SIZE-1:0], // data from the threadsregister file
    input logic [DATA_WIDTH-1:0] mem_data_in [BLOCK_SIZE-1:0], // data from main memory
    input logic [BLOCK_SIZE-1:0] active_threads, // we only worry about the threads that are active
    input logic cache_req, // from instruction, tells if this is a memory instruction or not

    output logic [DATA_WIDTH-1:0] data_out [BLOCK_SIZE-1:0],
    output logic mem_read_req,
    output logic mem_write_req,
    output logic ready,
    output logic [BLOCK_SIZE-1:0] mem_read_threads_en, mem_write_threads_en
    );

    logic seq_active, seq_over;
    logic sram_read_en;
    logic write_en;
    logic [BLOCK_SIZE-1:0] valid, hit, dirty;
    logic [BLOCK_SIZE-1:0] threads_en;
    logic [IDX_SIZE-1:0] idx [BLOCK_SIZE-1:0],
    
    Cache_Control ctrl(
        .clk(clk), .reset(reset),
        .valid(valid), .hit(hit), .dirty(dirty),
        .seq_over(seq_over),
        .read_mem_ready(read_mem_ready), .write_mem_ready(write_mem_ready),
        .store(store),
        .cache_req(cache_req),

        .ready(ready),
        .write_en(write_en),
        .sram_read_en(sram_read_en), // unimplemented
        .seq_active(seq_active),
        .mem_read_req(mem_read_req),
        .mem_write_req(mem_write_req),
        .mem_read_threads_en(mem_read_threads_en),
        .mem_write_threads_en(mem_write_threads_en)
    );

    Cache_Arbiter arbiter(
        .clk(clk), .reset(reset),
        .seq_active(seq_active),
        .active_threads(active_threads),
        .idx(idx),

        .threads_en(threads_en),
        .seq_over(seq_over)
    );

    // set up a multiplexor to decide what data gets input to the cache data array
    Cache_Data data(
        .clk(clk),
        .address(address),
        .data_in(data_in),
        .sram_read_en(sram_read_en),
        .threads_en(threads_en),
        .write_en(write_en),

        .data_out(data_out),
        .idx_out(idx),
        .valid(valid), .hit(hit), .dirty(dirty)
    );

endmodule