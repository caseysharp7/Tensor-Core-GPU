// Warp Scheduler

`timescale 1ns / 1ps

module Warp_Scheduler#(parameter PC_WIDTH=5)(
    input clk, reset,
    output [PC_WIDTH-1:0] pc
    );

    wire [1:0] select_warp;
    wire [PC_WIDTH-1:0] pc_array [3:0];

    genvar i;
    generate  // create 4 warp states to hold metadata for the 4 warps
        for(i = 0; i < 4; i = i+1) begin : loop1
            Warp_State warp_inst(
                .clk(clk),
                .reset(reset),
                .pc(pc_array[i])
            );
        end
    endgenerate

    Mux4 mux4_inst(  // which warp is selected
        .a(pc_array[0]),
        .b(pc_array[1]),
        .c(pc_array[2]),
        .d(pc_array[3]),
        .sel(select_warp),
        .y(pc)
    );

endmodule
