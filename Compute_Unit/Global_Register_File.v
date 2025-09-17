// Global Register File

`timescale 1ns / 1ps

module Global_Register_File(
    input clk, reset,
    input glob_reg_write_en,  // will come from controller
    input [3:0] glob_reg_write_addr, // will come from instruction

    input [DATA_WIDTH-1:0] glob_reg_write_data, // from where?
    
    input [3:0] glob_reg_read_addr, // will come from instruction

    output [DATA_WIDTH-1:0] glob_reg_read_data
    );

    parameter DATA_WIDTH = 16;

    reg [DATA_WIDTH-1:0] reg_file [15:0]; // 16 helper registers

    integer i;
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            for(i = 0; i < 16; i = i+1)
                reg_file[i] <= 16'd0;
        end
        else if(glob_reg_write_en) begin
            reg_file[glob_reg_write_addr] <= glob_reg_write_data;
        end
    end

    assign glob_reg_read_data = reg_file[glob_reg_read_addr];

endmodule