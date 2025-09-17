// Warp State

`timescale 1ns / 1ps

module Warp_State#(parameter PC_WIDTH = 8)(
    input clk, reset,
    output [PC_WIDTH-1:0] pc
    );

    reg [PC_WIDTH-1:0] pc_temp;

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            pc_temp <= 8'd0;
        end
        else
            pc_temp <= pc;
    end

    assign pc = pc_temp + 2;

endmodule
