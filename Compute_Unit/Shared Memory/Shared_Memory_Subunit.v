// Shared Memory subunit

`timescale 1ns / 1ps

module Shared_Memory_Subunit#(parameter BLOCK_SIZE = 256, ADDRESS_WIDTH = 8, DATA_WIDTH = 16)(
    input clk,
    input write_en,
    input bank_en,
    input [ADDRESS_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] write_data,
    
    output reg [DATA_WIDTH-1:0] read_data 
    );

    reg [DATA_WIDTH-1:0] shared_mem [BLOCK_SIZE-1:0];

    always @(posedge clk) begin
        if(write_en && bank_en) begin
            shared_mem[addr] <= write_data;
        end
        if(bank_en) begin
            read_data <= shared_mem[addr];
        end
    end
endmodule