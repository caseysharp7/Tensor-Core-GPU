// Instruction Decoder

`timescale 1ns / 1ps

module Instruction_Decoder#(parameter INST_WIDTH = 16)(
    input [INST_WIDTH-1:0] instruction, // from instruction_fetch
    input [INST_WIDTH-1:0] global_instruction, // from instruction fetch 
    output [3:0] opcode, // to instruction buffer {
    output [3:0] target_reg,
    output [3:0] address_reg,
    output [3:0] imm_short,
    output [1:0] array_id, // }
    output [3:0] global_opcode, // to control
    output [3:0] global_reg,
    output [7:0] imm_long // 
    );

    assign opcode = instruction [15 -: 4];

    assign target_reg = instruction[11 -: 4];
    assign address_reg = instruction[7 -: 4];

    assign imm_short = instruction[3:0]; // also used for warp mask

    assign array_id = instruction [3:2];

    assign global_opcode = global_instruction[15 -: 4];
    assign global_reg = global_instruction[11 -: 4];
    assign imm_long = global_instruction[7:0];

endmodule