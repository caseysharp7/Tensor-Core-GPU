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
    input [1:0] warp_num_clear, // from LSU
    input [3:0] threads_mask_clear, // from LSU
    input done_bit, // from LSU


    output [PC_WIDTH-1:0] pc, // to instr fetch
    output [1:0] warp_num // to LSU + scoreboard, threads reg file
    );

    parameter DATA_WIDTH = 16;
    parameter NUM_THREADS = 32;

    wire [1:0] select_warp;
    wire [PC_WIDTH-1:0] pc_array [3:0];
    reg push_active; // tells if the processor is currently pushing the systolic array

    wire [3:0] ready_warps_current;
    genvar i;
    generate  // create 4 warp states to hold metadata for the 4 warps
        for(i = 0; i < 4; i = i+1) begin : loop1
            Warp_State warp_inst(
                .clk(clk),
                .reset(reset),
                .future_ready(ready_warps_next[i]),

                .pc(pc_array[i]),
                .ready_out(ready_warps_current[i])
            );
        end
    endgenerate

    wire [3:0] imm_short [3:0];
    wire [3:0] opcode;
    Instruction_Buffer instr_buff_inst(
        .clk(clk), .reset(reset)
        .buffer_write_en(buffer_write_en),
        .opcode_in(opcode),
        .target_reg_in(target_reg),
        .address_reg_in(address_reg),
        .imm_short_in(imm_short),
        .array_id_in(array_id),
        .warp_num_store(warp_num_store),

        .opcode_out(opcode),
        .target_reg_out(),
        .address_reg_out(),
        .imm_short_out(imm_short), // will be used for threads masks but possibly other things for other instructions
        .array_id_out()
    );

    wire [3:0] ready_warps_next; // readiness for next cycle
    Warp_Readiness_Check wrc_inst#(parameter NUM_THREADS = 32) (
        .busy_threads(busy_threads),
        .threads_masks(imm_short),
        .ready_warps(ready_warps_next)
    );

    wire [NUM_THREADS-1:0] busy_threads;
    Scoreboard scoreboard_inst(
        .clk(clk), .reset(reset),
        .warp_num_busy(), // set once the next warp gets chosen
        .warp_num_clear(warp_num_clear),
        .threads_mask_busy(),
        .threads_mask_clear(threads_mask_clear),
        .busy_en(),
        .done_bit(done_bit),
        .busy_threads(busy_threads)
    );

    Controller(
        .reset(reset),
        .opcode(opcode),
        .instr_bit_in
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