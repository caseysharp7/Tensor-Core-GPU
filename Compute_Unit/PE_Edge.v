// Processing Element Edge

`timescale 1ns / 1ps

module PE_Edge#(parameter DATA_WIDTH = 16)(
    input clk, reset, pause,
    input [DATA_WIDTH-1:0] left_in,
    input [DATA_WIDTH-1:0] top_in,
    input valid_bit,

    output [DATA_WIDTH-1:0] right_out,
    output [DATA_WIDTH-1:0] bottom_out,
    output [DATA_WIDTH-1:0] result
    );

    wire [DATA_WIDTH-1:0] in, out, right, bottom;
    reg [DATA_WIDTH-1:0] prod;

    always@(*) begin
        if(valid_bit)
            prod = left_in*top_in;
        else
            prod = 16'd0;
    end

    assign out = in + prod;

    PE_Reg#(.REG_WIDTH(DATA_WIDTH)) register(
        .clk(clk), .reset(reset), .d(out), .q(in)
    );

    PE_Reg_In#(.REG_WIDTH(DATA_WIDTH)) register_in_left(
        .clk(clk), .reset(reset), .pause(pause),
        .d(left_in), .q(right)
    );
    PE_Reg_In#(.REG_WIDTH(DATA_WIDTH)) register_in_top(
        .clk(clk), .reset(reset), .pause(pause),
        .d(top_in), .q(bottom)
    );

    assign right_out = right;
    assign bottom_out = bottom;
    assign result = out;

endmodule