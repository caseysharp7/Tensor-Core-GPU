// Data Memory

`timescale 1ns / 1ps

module Data_Memory (
    input logic clk,
    input logic reset,
    input logic [ADDR_WIDTH-1:0] mem_addr [7:0], // from LSU
    input logic [DATA_WIDTH-1:0] mem_write_data [7:0], // from LSU

    input logic mem_write_en, // from controller
    input logic mem_read_en, // from controller
    
    output logic [DATA_WIDTH-1:0] mem_read_data [7:0] // to LSU
    );
 
    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 8;

    logic [DATA_WIDTH-1:0] ram [255:0]; 
    
    integer i;
    initial 
    begin  
       for(i = 0; i < 256; i = i+1)  
           ram[i] <= 32'd0;  
    end  
        
    always_ff @(posedge clk) begin  
        if (mem_write_en)  
            for(i = 0; i < 8; i = i+1)
                ram[mem_addr + i] <= mem_write_data[i];
    end  
    

    always_comb begin
        if(mem_read_en)
            for(i = 0; i < 8; i = i+1)
                mem_read_data[i] = ram[mem_addr + i];
    end

endmodule