// Threads Register File

`timescale 1ns / 1ps

module Threads_Register_File(
    input logic clk, 
    input logic reset,
    input logic reg_write_en,  // will come from controller
    input logic [3:0] reg_write_addr, // will come from instruction
    input logic [DATA_WIDTH-1:0] reg_write_data [7:0], // will come from LSU
    input logic [3:0] reg_read_addr, // will come from instruction
    input logic [1:0] warp_num, // will come from scheduler
    
    input logic [1:0] blockIdx, // from outside of compute unit
    input logic [7:0] blockDim, // 1D, number of threads in a block, comes from outside of compute unit

    output logic [DATA_WIDTH-1:0] reg_read_data [7:0],
    output logic [DATA_WIDTH-1:0] threadIdx [7:0]  // goes to AGU
    ); 

    parameter DATA_WIDTH = 16;
    parameter NUM_THREADS = 32; // 4 warps, 8 threads in each warp, replace with blockDim

    logic [DATA_WIDTH-1:0] reg_file [NUM_THREADS-1:0][15:0]; // 16 registers per thread

    // last three registers of each thread will be read only and contain their threadIdx, blockIdx, and blockDim (inspiration from tiny gpu)

    integer i, j;
    initial begin
        for(i = 0; i < NUM_THREADS; i = i+1) begin
            reg_file[i][13] = i; // threadIdx
            reg_file[i][14] = blockIdx;
            reg_file[i][15] = blockDim;
        end
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            for(i = 0; i < NUM_THREADS; i = i+1)
                for(j = 0; j < 16; j = j+1)
                    reg_file[i][j] <= 16'd0;
        end
        else if(reg_write_en && (reg_write_addr < 13)) begin
            for(i = 0; i < 8; i = i+1)
                reg_file[(warp_num*8) + i][reg_write_addr] <= reg_write_data[i];
        end
    end


    always_comb begin
        for(i = 0; i < 8; i = i+1) begin
            reg_threads[i] = reg_file[(warp_num*8) + i][reg_read_addr];
            threadIdx[i] = reg_file[(warp_num*8) + i][13];
        end
    end

endmodule