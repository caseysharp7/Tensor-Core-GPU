// Shared Memory Arbiter

`timescale 1ns / 1ps

module Shared_Memory_Arbiter#(parameter NUM_BANKS = 8, NUM_THREADS = 8)(
    input logic clk, reset,
    input logic [NUM_THREADS-1:0] active_threads,
    input logic [2:0] thread_banks [NUM_BANKS-1:0],

    output logic [NUM_BANKS-1:0] threads_en, // per thread enable, not per bank
    output logic warp_stall
    );

    logic [NUM_BANKS-1:0] threads_mask;
    logic [NUM_BANKS-1:0] banks_busy;
    logic [NUM_BANKS-1:0] remaining_threads;


    assign remaining_threads = active_threads & ~threads_mask;

    always_comb begin
        threads_en = '0;
        banks_busy = '0;

        for(int i = 0; i < NUM_BANKS; i = i+1) begin
            if(remaining_threads[i]) begin
                if(!banks_busy[thread_banks[i]]) begin
                    threads_en[i] = 1'b1;
                    banks_busy[thread_banks[i]] = 1'b1;
                end
            end
        end

        warp_stall = (remaining_threads & ~threads_en) != 0;
    end

    always_ff@(posedge clk) begin
        if(reset || !warp_stall) begin
            threads_mask <= 8'b0;
        end
        else begin
            threads_mask <= threads_mask | threads_en;
        end
    end

endmodule