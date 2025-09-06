// Warp State

`timescale 1ns / 1ps

module Warp_State(
// input will come from outside of the compute unit
    input clk, reset,
    output [4:0] pc
    );

    reg [4:0] pc_temp;

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            pc_temp <= 5'b00000;
        end
        else
            pc_temp <= pc;

    end

    assign pc = pc_temp + 2;

endmodule
