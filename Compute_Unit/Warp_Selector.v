// Warp Selector
// Selects the next warp to 

`timescale 1ns / 1ps

module Warp_Selector(
    input clk, reset,
    input [3:0] ready_warps, // from warp states
    input push_en, // from control
    input matmul_done, // from push or pull unit when push completes

    output reg [1:0] push_warp, 
    output reg [1:0] instr_warp,
    output reg pause, // pause for systolic array if needed warp is not ready
    output all_busy // indicates if all warps are busy, need to stall the whole processor
    );

    parameter NUM_WARPS = 4;

    reg [1:0] systolic_warp_prev, systolic_warp_next; // used for when push is active to track which warp should be selected
    reg [1:0] instr_warp_ptr; // which 
    reg [1:0] next_instr_warp_ptr;
    reg push_active;
    reg [3:0] ready_warps_temp, sel_out;

    always@(*) begin
        ready_warps_temp = ready_warps;
    end

    always@(posedge clk) begin
        if(reset) begin
            push_active <= 1'b0;
            systolic_warp_next <= 2'b0;
            systolic_warp_prev <= 2'b0;
        end
        else if(push_en) begin
            push_active <= 1'b1;
            systolic_warp_prev <= 2'd0; // can change this if determine that instruction tells which warp to start with
            systolic_warp_next <= 2'd0;
            if(ready_warps[0]) begin
                systolic_warp_prev <= systolic_warp_prev + 1;
            end
        end
        else if(matmul_done) begin
            push_active <= 1'b0;
        end
        else if(ready_warps[systolic_warp_prev]) begin
            systolic_warp_next <= systolic_warp_prev;
            systolic_warp_prev <= systolic_warp_prev + 1;
        end
        
        instr_warp_ptr <= next_instr_warp_ptr;
    end
    
    assign all_busy = (ready_warps == 4'b0000) ? 1'b1 : 1'b0;

    function automatic [3:0] select_instr_warp(
        input [3:0] ready_warps_temp,
        input [1:0] warp_ptr
    );

        integer i;
        integer idx;
        reg found;
        reg [1:0] warp;
        reg [1:0] next_ptr;

        begin
            found = 0;
            warp = warp_ptr;
            next_ptr = warp_ptr;

            for (i = 0; i < 4; i = i + 1) begin
                idx = (warp_ptr + i) % 4;
                if (ready_warps_temp[idx] && !found) begin
                    warp = idx[1:0];
                    next_ptr = (idx + 1) % 4;
                    found = 1;
                end
            end

            select_instr_warp = {next_ptr, warp};
        end
    endfunction

    always@(*) begin
        if(push_active) begin
            if(!ready_warps_temp[systolic_warp_next]) begin
                push_warp = 2'd0;
                pause = 1'b1;
            end
            else begin
                push_warp = systolic_warp_next;
                pause = 1'b0;
                ready_warps_temp[systolic_warp_next] = 1'b0;
            end
        end
        sel_out = select_instr_warp(ready_warps_temp, instr_warp_ptr);
        next_instr_warp_ptr = sel_out[3:2];
        instr_warp = sel_out[1:0];
    end

endmodule