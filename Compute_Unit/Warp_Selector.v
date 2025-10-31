// Warp Selector
// Selects the next warp to 

// Need to decide if we declare masks as lsb first or msb first

`timescale 1ns / 1ps

module Warp_Selector(
    input clk, reset,
    input [3:0] ready_warps, // from warp states
    input push_en, // from control
    input matmul_done, // from push or pull unit when push completes

    output [1:0] push_warp,
    output [1:0] instr_warp,
    output pause // pause for systolic array if needed warp is not ready
    );

    reg [1:0] systolic_warp; // used for when push is active to track which warp should be selected
    reg [1:0] instr_warp_ptr; // which 
    reg push_active;
    wire [3:0] warp_mask;

    assign warp_mask = ready_warps;

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            push_active = 1'b0;
            systolic_warp = 2'b0;
        end
        else if(push_en) begin
            push_active = 1'b1;
            systolic_warp = 2'd0;
        end
        else if(matmul_done) begin
            push_active = 1'b0;
        end
        else begin
            systolic_warp = systolic_warp + 1;
        end
    end

    function [1:0] select_ready_warp(
        input [3:0] warp_mask,
        input [1:0] warp_ptr
    );
    integer i;
    begin

    end
    endfunction

    always@(*) begin
        if(push_active) begin
            if(!warp_mask[systolic_warp]) begin
                push_warp = 2'd0;
                pause = 1'b1;
            end
            else begin
                push_warp = systolic_warp;
                pause = 1'b0;
                warp_mask[systolic_warp] = 1'b0;
            end

        end
    end





endmodule