// PE Register Inputs
// to store the inputs from the previous clk cycle in case of pause

`timescale 1ns / 1ps

module PE_Reg_In#(parameter REG_WIDTH = 16)(
    input clk, reset, pause,
    input [REG_WIDTH-1:0] d,
    output reg [REG_WIDTH-1:0] q
);

    always @(posedge clk or posedge reset) begin
        if(reset)
            q <= 0;
        else if(!pause)
            q <= d;
    end

endmodule