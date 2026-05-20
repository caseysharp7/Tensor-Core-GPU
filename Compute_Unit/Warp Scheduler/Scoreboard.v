// Scoreboard

module Scoreboard#(parameter DATA_WIDTH = 16,
                   parameter NUM_THREADS = 32)(
    input clk, reset,
    input [1:0] warp_num_busy, // from scheduler for new entry (set bits to 1 to indicate that thread is now busy)
    input [1:0] warp_num_clear, // from LSU for completed instruction (set bits back to 0 to indicate thread is not busy)
    input [3:0] threads_mask_busy, // from scheduler
    input [3:0] threads_mask_clear, // from LSU
    input busy_en, // from controller, only marked busy if the instruction is LD or ST (dram operation)
    input done_bit, // from 

    output [NUM_THREADS-1:0] busy_threads // to scheduler
    );
    // can just load and unload sequentially as memory instructions won't go out of order

    // busy threads:
    // an on bit indicates the thread is busy
    reg [NUM_THREADS-1:0] threads_file;
    wire [7:0] threads_busy;
    wire [7:0] threads_clear;

    wire [31:0] full_busy_mask;
    wire [31:0] full_clear_mask;

    Threads_Mask_Decoder tmd_busy(
        .threads_mask(threads_mask_busy),
        .active_threads(threads_busy)
    );

    Threads_Mask_Decoder tmd_clear(
        .threads_mask(threads_mask_clear),
        .active_threads(threads_clear)
    );

    assign full_busy_mask  = busy_en  ? ({24'd0, threads_busy}  << (warp_num_busy * 8))  : 32'd0;
    assign full_clear_mask = done_bit ? ({24'd0, threads_clear} << (warp_num_clear * 8)) : 32'd0;
    
    always @(posedge clk) begin
        if(reset) begin
            threads_file <= 32'd0;
        end
        else begin
            // Apply clears first, then sets. 
            // If both happen on the exact same thread in the same cycle, 'busy' wins.
            threads_file <= (threads_file & ~full_clear_mask) | full_busy_mask;
        end
    end


    assign busy_threads = threads_file;

endmodule