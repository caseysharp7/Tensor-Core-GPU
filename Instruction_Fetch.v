// Instruction Fetch

`timescale 1ns / 1ps

module Instruction_Fetch(
    
    output [INST_WIDTH-1:0] instruction
    );

    parameter INST_WIDTH = 16;

    Instruction_Mem inst_mem(
        .read_addr
        .data(instruction)
    )


endmodule