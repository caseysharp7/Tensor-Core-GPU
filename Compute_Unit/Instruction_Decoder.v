// Instruction Decoder

`timescale 1ns / 1ps

module Instruction_Decoder(
    input [INST_WIDTH-1:0] instruction, // from instruction_fetch
    output [3:0] opcode,
    output [3:0] target_reg,
    output [3:0] address_reg,
    output [3:0] imm_short,
    output [7:0] imm_long,
    output [1:0] array_id
    );

    INST_WIDTH = 16;

    assign opcode = instruction [15 -: 4];

    assign target_reg = instruction[11 -: 4];
    assign address_reg = instruction[7 -: 4];

    assign imm_short = instruction[3:0]; // also used for warp mask

    assign array_id = instruction [3:2];

endmodule