// Global Instructions Memory

`timescale 1ns / 1ps

module Global_Instruction_Mem(
    input [PC_WIDTH-1:0] read_addr, // from scheduler (global_pc)
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