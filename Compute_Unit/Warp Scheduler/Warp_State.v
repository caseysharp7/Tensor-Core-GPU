// Warp State

`timescale 1ns / 1ps

module Warp_State#(parameter PC_WIDTH = 8)(
    input clk, reset,
    input future_ready, // from Warp_Readiness_Check
    input pc_update_en, // from scheduler, set if a warp is chosen
    output [PC_WIDTH-1:0] pc,
    output ready_out
    );

    reg [PC_WIDTH-1:0] pc_temp;
    reg ready;

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            pc_temp <= 8'd0;
            ready <= 1'b0;
        end
        else
            pc_temp <= pc;
            ready <= future_ready;
    end

    assign pc = pc_update_en ? pc_temp+2 : pc;
    assign ready_out = ready;

endmodule