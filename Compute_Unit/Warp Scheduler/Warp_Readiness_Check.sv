// Warp Readiness Checker
// Take in values for next instruction for each warp (from instruction buffer) and compare with the 
// available threads (from scoreboard) for each respective warp to mark each warp as ready or not (warp_state)

// if any threads needed for the next instruction are already busy, then the warp is no ready and set
// to 0

`timescale 1ns / 1ps

module Warp_Readiness_Check#(parameter NUM_THREADS = 32) (
    input logic [NUM_THREADS-1:0] busy_threads, // from scoreboard
    input logic [3:0] threads_masks [3:0], // from instruction buffer

    output logic [3:0] ready_warps // to scheduler and distributed to warp_states
    );

    logic [7:0] warps [3:0];

    genvar i;
    for(i = 0; i < 4; i++) begin
        assign warps[i] = busy_threads[(8*(i+1)) - 1 -: 8];
    end

    logic [7:0] masks [3:0];
    generate
        for(i = 0; i < 4; i = i+1) begin : loop1
            Threads_Mask_Decoder tmd_inst(
                .threads_mask(threads_masks[i]),
                .active_threads(masks[i])
            );
        end
    endgenerate

    integer j;
    always_comb begin
        for(j = 0; j < 4; j = j+1) begin
            ready_warps[j] = ~(|(warps[j] & masks[j]));
        end
    end


endmodule
