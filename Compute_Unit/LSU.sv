// Load Store Unit

`timescale 1ns / 1ps

module LSU (
    input logic clk,
    input logic reset, 

    input logic [DATA_WIDTH-1:0] threadIdx [7:0], // come from threads reg file
    input logic [1:0] warp_num, // come from scheduler
    input logic [DATA_WIDTH-1:0] base_addr_reg, // come from global reg file
    input logic [3:0] base_addr_imm, // from instruction

    input logic [DATA_WIDTH-1:0] reg_read_data [7:0], // will come from threads reg file
    input logic [DATA_WIDTH-1:0] mem_read_data [7:0], // from data memory 

    output logic [DATA_WIDTH-1:0] reg_write_data [7:0], // to threads reg file (from data memory most likely)
    output logic [DATA_WIDTH-1:0] mem_write_data [7:0], // to data memory (from threads reg file most likely)
    
    output logic [ADDR_WIDTH-1:0] addr [7:0] // to data memory
    );

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 8;
    
    // need to implement logic to check if all the proper addresses were read when loading the data to the threads reg file from data memory

    AGU agu( // acceptable for loads and stores currently as we'll load from and store to contiguous memory
        .reset(reset),
        .threadIdx(threadIdx),
        .warp_num(warp_num),
        .base_addr_reg(base_addr_reg),
        .base_addr_imm(base_addr_imm),
        .addr(addr)
    )


endmodule