// Instruction Fetch

`timescale 1ns / 1ps

module Instruction_Fetch(
    input [PC_WIDTH-1:0] pc, // from warp scheduler
    output [INST_WIDTH-1:0] instruction // to instr decoder
    );

    parameter INST_WIDTH = 16;
    parameter PC_WIDTH = 8;

    Instruction_Mem inst_mem(
        .read_addr(pc)
        .data(instruction)
    );

endmodule