// Warp Scheduler

`timescale 1ns / 1ps

module Warp_Scheduler#(parameter PC_WIDTH=8)(
    input clk, reset,
    input buffer_write_en, // from controller
    input [3:0] opcode, // from decoder {
    input [3:0] target_reg,
    input [3:0] address_reg,
    input [3:0] imm_short,
    input [1:0] array_id, // }
    input [1:0] warp_num_store, // come from decoder or instr fetch once future instruction in being loaded

    output [PC_WIDTH-1:0] pc, // to instr fetch
    output [1:0] warp_num // to LSU + scoreboard, threads reg file
    );

    parameter DATA_WIDTH = 16;
    parameter NUM_THREADS = 32;

    wire [1:0] select_warp;
    wire [PC_WIDTH-1:0] pc_array [3:0];

    genvar i;
    generate  // create 4 warp states to hold metadata for the 4 warps
        for(i = 0; i < 4; i = i+1) begin : loop1
            Warp_State warp_inst(
                .clk(clk),
                .reset(reset),
                .future_ready(ready_warps[i])

                .pc(pc_array[i])
            );
        end
    endgenerate

    Instruction_Buffer instr_buff_inst(
        .clk(clk), .reset(reset)
        .buffer_write_en(buffer_write_en),
        .opcode_in(opcode),
        .target_reg_in(target_reg),
        .address_reg_in(address_reg),
        .imm_short_in(imm_short),
        .array_id_in(array_id),
        .warp_num_store(warp_num_store),

        .opcode_out(),
        .target_reg_out(),
        .address_reg_out(),
        imm_short_out(),
        .array_id_out()
    );

    wire [3:0] ready_warps;
    Warp_Readiness_Check wrc_inst#(parameter NUM_THREADS = 32) (
        .busy_threads(busy_threads),
        .warp_masks(),
        .ready_warps(ready_warps)
    );

    wire [NUM_THREADS-1:0] busy_threads;
    Scoreboard scoreboard_inst(
        .clk(clk), .reset(reset),
        .warp_num_busy(),
        .warp_num_clear(),
        .threads_mask_busy(),
        .threads_mask_clear(),
        .busy_en(),
        .done_bit(),
        .busy_threads(busy_threads)
    );


    Mux4 mux4_inst#(MUX_WIDTH = PC_WIDTH)(  // which warp is selected
        .a(pc_array[0]),
        .b(pc_array[1]),
        .c(pc_array[2]),
        .d(pc_array[3]),
        .sel(select_warp),
        .y(pc)
    );

endmodule
