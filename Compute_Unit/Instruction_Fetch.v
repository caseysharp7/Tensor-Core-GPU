// Instruction Fetch

`timescale 1ns / 1ps

module Instruction_Fetch#(
    parameter INST_WIDTH = 16,
    parameter PC_WIDTH = 8
)(
    input [PC_WIDTH-1:0] pc, // from warp scheduler
    input [PC_WIDTH-1:0] global_pc, // from warp scheduler
    output [INST_WIDTH-1:0] instruction, // to instr decoder
    output [INST_WIDTH-1:0] global_instruction // to instr decoder
    );

    Instruction_Mem inst_mem(
        .read_addr(pc),
        .read_global_addr(global_pc),
        .instruction(instruction),
        .global_instruction(global_instruction)
    );

endmodule