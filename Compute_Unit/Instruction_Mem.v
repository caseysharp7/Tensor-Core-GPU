// Instruction Memory

`timescale 1ns / 1ps

module Instruction_Mem(
    input [PC_WIDTH-1:0] read_addr,
    output [INST_WIDTH-1:0] instruction
    );
    
    parameter PC_WIDTH = 8;
    parameter INST_WIDTH = 16;

    reg [INST_WIDTH-1:0] rom [127:0];  
    
    initial  
    begin


    end

    assign instruction = rom[read_addr[7:1]]; 
endmodule

// ISA: 
// LD:    (opcode)  (destination register)  (address register)  (immediate (warp_mask))
//        (0001)    (rrrr)                  (rrrr)              (iiii)

// ST:    (opcode)  (source register)       (address register)  (immediate)
//        (0010)    (rrrr)                  (rrrr)              (iiii)

// LDG (load global reg) (will be just loaded with immediate)
// LDG:   (opcode)  (destination register)  (immediate)
//        (1000)    (rrrr)                  (iiiiiiii)












// PUSH:  (opcode)  (source register)       (PE register (which PE a given thread should push to))  (systolic array ID)  (reserved)
//        (0100)    (rrrr)                  (rrr)                                                  (ii)                  (xxx)

// PULL:  (opcode)  (destination register)  (PE register)                                           (systolic array ID)  (reserved)
//        (0101)    (rrrr)                  (rrrr)                                                  (ii)                 (xx)
