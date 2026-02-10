// Threads Register File

`timescale 1ns / 1ps

// This needs to be changed. When a store comes in immediately take the register data and put in in the LSU
// so that data is already in flight 
// The reg read addr will come from the instruction buffer so it can process pushes/pulls and loads/stores

module Threads_Register_File#(parameter DATA_WIDTH = 16,
                              parameter NUM_THREADS = 32)(
    input logic clk, 
    input logic reset,
    input logic reg_write_en,  // will come from controller
    input logic [3:0] reg_write_addr, // will come from LSU
    input logic [DATA_WIDTH-1:0] reg_write_data [7:0], // will come from LSU
    input logic [3:0] instr_reg_read_addr, // will come from scheduler (instruction buffer)
    input logic [3:0] push_reg_read_addr, // from FIFO Register Buffer
    input logic [1:0] instr_warp_num_read, // will come from scheduler (warp selector)
    input logic [1:0] push_warp_num_read, // come from scheduler (warp selector)
    input logic [1:0] warp_num_write, // from LSU
    
    input logic [1:0] blockIdx, // from outside of compute unit
    input logic [7:0] blockDim, // 1D, number of threads in a block, comes from outside of compute unit

    output logic [DATA_WIDTH-1:0] reg_read_data_instr [7:0], 
    output logic [DATA_WIDTH-1:0] threadIdx [7:0],  // goes to AGU
    output logic [DATA_WIDTH-1:0] reg_read_data_push [7:0] // to push unit
    ); 

    // 4 warps, 8 threads in each warp, replace with blockDim

    logic [DATA_WIDTH-1:0] reg_file [NUM_THREADS-1:0][15:0]; // 16 registers per thread

    // last three registers of each thread will be read only and contain their threadIdx, blockIdx, and blockDim

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
                reg_file[(warp_num_write*8) + i][reg_write_addr] <= reg_write_data[i];
        end
    end


    always_comb begin
        for(i = 0; i < 8; i = i+1) begin
            reg_read_data_instr[i] = reg_file[(instr_warp_num_read*8) + i][instr_reg_read_addr];
            threadIdx[i] = reg_file[(instr_warp_num_read*8) + i][13];
            reg_read_data_push[i] = reg_file[(push_warp_num_read*8) + 1][push_reg_read_addr];
        end
    end

endmodule