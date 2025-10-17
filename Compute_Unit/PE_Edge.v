// Processing Element Edge

`timescale 1ns / 1ps

module PE_Edge#(parameter DATA_WIDTH = 16)(
    input clk, reset,
    input [DATA_WIDTH-1:0] left_in,
    input [DATA_WIDTH-1:0] top_in,
    input left_valid,
    input top_valid,

    output [DATA_WIDTH-1:0] right_out,
    output [DATA_WIDTH-1:0] bottom_out,
    output [DATA_WIDTH-1:0] result
    );

    wire [DATA_WIDTH-1:0] in, out, prod;

    assign prod = left_in*top_in;

    always@(*) begin
        if(left_valid && top_valid)
    end


endmodule