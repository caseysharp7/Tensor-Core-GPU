// Threads Register File

`timescale 1ns / 1ps

module Threads_Register_File(
    input logic clk, 
    input logic reset,
    input logic reg_write_en,  // will come from controller
    input logic [3:0] reg_write_addr, // will come from instruction
    input logic [DATA_WIDTH-1:0] write_data [8], // will come from data memory by way of LSU
    input logic [3:0] reg_read_addr, // will come from instruction
    input logic [1:0] warp_num, // will come from scheduler
    output logic [DATA_WIDTH-1:0] reg_threads [8],
    output logic [DATA_WIDTH-1:0] threadIdx [8]  // goes to AGU
    ); 

    parameter DATA_WIDTH = 16;
    parameter NUM_THREADS = 32; // 4 warps, 8 threads in each warp

    logic [DATA_WIDTH-1:0] reg_file [NUM_THREADS-1:0][15:0]; // 16 registers per thread

    // last three values of each thread will be read only and contain their threadIdx, blockIdx, and blockDim (inspiration from tiny gpu)

    // TO DO: need to assign threadIdx blockIdx to each thread and make sure they are ROM

    integer i, j;
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            for(i = 0; i < NUM_THREADS; i = i+1)
                for(j = 0; j < 16; j = j+1)
                    reg_file[i][j] <= 16'd0;
        end
        else if(reg_write_en) begin
            for(i = 0; i < 8; i = i+1)
                reg_file[(warp_num*8) + i][reg_read_addr] <= write_data[i];
        end
    end

    always_comb begin
        for(i = 0; i < 8; i = i+1)
            reg_threads[i] = reg_file[(warp_num*8) + i][reg_read_addr];
    end

endmodule