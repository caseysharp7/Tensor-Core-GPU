// Processing Element Center

`timescale 1ns / 1ps

module PE_Center#(parameter DATA_WIDTH = 16)(
    input clk, reset, pause,
    input [DATA_WIDTH-1:0] left_in, top_in,
    output [DATA_WIDTH-1:0] right_out, bottom_out,
    output [DATA_WIDTH-1:0] result
    );

    wire [DATA_WIDTH-1:0] in, out, prod;
    reg [DATA_WIDTH-1:0] right, bottom;

    always @(*) begin
        if(!pause)
            prod = left_in*top_in;
        else
            prod = 16'd0;
    end

    assign out = in + prod;

    PE_Reg register#(REG_WIDTH = DATA_WIDTH)(
        .clk(clk), .reset(reset), .d(out), .q(in)
    );

    PE_Reg_In register_in_left#(REG_WIDTH = DATA_WIDTH)(
        .clk(clk), .reset(reset), .pause(pause),
        .d(left_in), .q(right)
    );
    PE_Reg_In register_in_top#(REG_WIDTH = DATA_WIDTH)(
        .clk(clk), .reset(reset), .pause(pause),
        .d(top_in), .q(bottom)
    );

    assign right_out = right;
    assign bottom_out = bottom;
    assign result = out;

endmodule