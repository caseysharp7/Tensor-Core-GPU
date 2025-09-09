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

// ISA: 
// LD:    (opcode)  (destination register)  (address register)  (immediate)
//        (0001)    (rrrr)                  (rrrr)              (iiii)

// ST:    (opcode)  (source register)       (address register)  (immediate)
//        (0010)    (rrrr)                  (rrrr)              (iiii)

// PUSH:  (opcode)  (source register)       (PE register (which PE a given thread should push to))  (systolic array ID)  (reserved)
//        (0100)    (rrrr)                  (rrrr)                                                  (ii)                 (xx)

// PULL:  (opcode)  (destination register)  (PE register)                                           (systolic array ID)  (reserved)
//        (0101)    (rrrr)                  (rrrr)                                                  (ii)                 (ii)