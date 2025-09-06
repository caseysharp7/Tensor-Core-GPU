// Instruction Memory

`timescale 1ns / 1ps

module Instruction_Mem(
    input [4:0] read_addr,
    output [INST_WIDTH-1:0] instruction
    );
    
    parameter INST_WIDTH = 16;

    reg [INST_WIDTH-1:0] rom [15:0];  
    
    initial  
    begin


    end

    assign instruction = rom[read_addr[4:1]];
endmodule