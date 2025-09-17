// Instruction Decoder

`timescale 1ns / 1ps

module Instruction_Decoder(
    input [INST_WIDTH-1:0] instruction // from instruction_fetch
    );

    INST_WIDTH = 16;