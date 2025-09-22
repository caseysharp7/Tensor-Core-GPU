// Load Store Unit

`timescale 1ns / 1ps

module LSU (
    input logic clk,
    input logic reset, 

    input logic [DATA_WIDTH-1:0] threadIdx [7:0], // come from threads reg file
    input logic [1:0] warp_num, // come from scheduler
    input logic [DATA_WIDTH-1:0] base_addr_reg, // come from global reg file
    input logic [3:0] base_addr_imm, // from instruction

    input logic [3:0] dest_reg_addr_in, // from instruction
    input logic instr_bit_in, // from controller
    input logic queue_write_en, // from controller

    input logic [DATA_WIDTH-1:0] reg_read_data [7:0], // will come from threads reg file
    input logic [DATA_WIDTH-1:0] mem_read_data [7:0], // from data memory 

    output logic [DATA_WIDTH-1:0] reg_write_data [7:0], // to threads reg file (from data memory most likely)
    output logic [DATA_WIDTH-1:0] mem_write_data [7:0], // to data memory (from threads reg file most likely)
    
    output logic [3:0] reg_addr_out, // to threads reg file after done bit activated, for a load (with a write we will already have data from threads reg file) 
    output logic [1:0] warp_num_out, // to scoreboard
    output logic done_bit_out, // to scoreboard

    output logic [ADDR_WIDTH-1:0] addr_out [7:0] // to data memory
    );

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 8;

    logic addr_temp;
    
    // need to implement logic to check if all the proper addresses were read when loading the data to the threads reg file from data memory (I think we can actually solve this using software instead)

    AGU agu( // acceptable for loads and stores currently as we'll load from and store to contiguous memory
        .reset(reset),
        .threadIdx(threadIdx),
        .warp_num(warp_num),
        .base_addr_reg(base_addr_reg),
        .base_addr_imm(base_addr_imm),
        .addr(addr_temp)
    );

    LSQ lsq(
        .clk(clk), .reset(reset), 
        .warp_num_in_q(warp_num),
        .dest_reg_in_q(dest_reg_addr),
        .addr_in_q(addr_temp),
        .instr_bit_in_q(instr_bit_in),
        .queue_write_en(queue_write_en),

        .warp_num_out_q(warp_num_out),
        .dest_reg_out_q(reg_addr_out),
        .addr_out_q(addr_out),
        .instr_bit_out_q(), // used internally? or to control
        .done_bit_q(done_bit_out) 
    );

endmodule