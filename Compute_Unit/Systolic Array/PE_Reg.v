// PE Register

`timescale 1ns / 1ps

module PE_Reg#(parameter REG_WIDTH = 16)(
    input clk, reset,
    input [REG_WIDTH-1:0] d,
    output reg [REG_WIDTH-1:0] q
    );

    always @(posedge clk or posedge reset) begin
        if(reset)
            q <= 0;
        else 
            q <= d;
    end

endmodule