// Warp Scheduler

`timescale 1ns / 1ps

module Warp_Scheduler#(parameter PC_WIDTH=8,
                       parameter DATA_WIDTH = 16,
                       parameter NUM_THREADS = 32)(
    input clk, reset,
    input [3:0] opcode, // from decoder {
    input [3:0] target_reg,
    input [3:0] address_reg,
    input [3:0] imm_short,
    input [1:0] array_id, // }
    input [3:0] global_opcode, // from decoder, to control
    input [1:0] warp_num_clear, // from LSU
    input [3:0] threads_mask_clear, // from LSU
    input done_bit, // from LSU
    input matmul_done, // from push or pull unit when matmul finishes


    output [PC_WIDTH-1:0] pc, // to instr fetch
    output [PC_WIDTH-1:0] global_pc_out, // to global instr fetch
    output pause, // to Push Unit
    output [3:0] target_reg_out, // to threads register file
    output [3:0] address_reg_out, // to global register file
    output [3:0] imm_short_out, // to LSU
    output [1:0] instr_warp_out, // to threads register file
    output [1:0] push_warp_out, // to threads register file
    output [3:0] push_reg_out // to threads register file
    );

    wire [1:0] select_warp;
    wire [PC_WIDTH-1:0] pc_array [3:0];
    reg push_active; // tells if the processor is currently pushing the systolic array
    reg global_pc;

    wire [3:0] ready_warps_current;
    genvar i;
    generate  // create 4 warp states to hold metadata for the 4 warps
        for(i = 0; i < 4; i = i+1) begin : loop1
            Warp_State warp_inst(
                .clk(clk),
                .reset(reset),
                .future_ready(ready_warps_next[i]),
                .pc_update_en(),

                .pc(pc_array[i]),
                .ready_out(ready_warps_current[i])
            );
        end
    endgenerate

    always_ff@(posedge clk) begin
        global_pc = global_pc+2;
    end

    assign global_pc_out = global_pc;

    wire [3:0] opcode_internal [3:0]; // must deal with these internally to choose the right one depending on which warps are selected
    wire [3:0] target_reg_out_internal [3:0];
    wire [3:0] address_reg_out_internal [3:0];
    wire [3:0] imm_short_out_internal [3:0];
    wire [3:0] opcode_control;
    wire [1:0] instr_warp_internal;
    Instruction_Buffer instr_buff_inst(
        .clk(clk), .reset(reset),
        .buffer_write_en(), // from controller
        .opcode_in(opcode),
        .target_reg_in(target_reg),
        .address_reg_in(address_reg),
        .imm_short_in(imm_short),
        .array_id_in(array_id),
        .warp_num_store(instr_warp_internal),

        .opcode_out(opcode_internal), // controller
        .target_reg_out(target_reg_out_internal), // out of scheduler to threads register file
        .address_reg_out(address_reg_out_internal), // out of scheduler to global register file 
        .imm_short_out(imm_short_out_internal), // will be used for threads masks but possibly other things for other instructions
        .array_id_out() // ignore for now, used to select with systolic array if multiple
    );
    
    assign opcode_control = opcode_internal[instr_warp_internal];
    assign target_reg_out = target_reg_out_internal[instr_warp_internal];
    assign address_reg_out = address_reg_out_internal[instr_warp_internal];
    assign imm_short_out = imm_short_out_internal[instr_warp_internal];

    wire [3:0] ready_warps_next; // readiness for next cycle
    wire [NUM_THREADS-1:0] busy_threads;
    Warp_Readiness_Check wrc_inst (
        .busy_threads(busy_threads),
        .threads_masks(imm_short_out_internal),
        .ready_warps(ready_warps_next)
    );

    Scoreboard scoreboard_inst(
        .clk(clk), .reset(reset),
        .warp_num_busy(instr_warp_internal), // from warp selector set once the next warp gets chosen
        .warp_num_clear(warp_num_clear),
        .threads_mask_busy(), 
        .threads_mask_clear(threads_mask_clear),
        .busy_en(), // from controller, only marked busy if the instruction is LD or ST (dram operation)
        .done_bit(done_bit),
        .busy_threads(busy_threads)
    );

    FIFO_Register_Buffer reg_buf_inst(
        .clk(clk), .reset(reset),
        .write_en(), // from controller when load instruction is issued
        .read_en(), // maybe from warp selector while push is active? Otherwise controller
        .write_reg(), // from instruction buffer when load is issued
        .read_reg(push_reg_out) // to threads register file
    );

    Warp_Selector selector_inst(
        .clk(clk), 
        .reset(reset),
        .ready_warps(ready_warps_current),
        .push_en(), // from controller
        .matmul_done(matmul_done), // from push or pull unit when push completes (external to scheduler)

        .push_warp(push_warp_out),
        .instr_warp(instr_warp_internal),
        .pause(pause), // to push unit
        .all_busy() // deal with later, indicates a whole compute unit stall
    );

    assign instr_warp_out = instr_warp_internal;

    Controller controller_inst(
        
    );


    Mux4#(.MUX_WIDTH(PC_WIDTH)) mux4_inst(  // which warp is selected
        .a(pc_array[0]),
        .b(pc_array[1]),
        .c(pc_array[2]),
        .d(pc_array[3]),
        .sel(select_warp),
        .y(pc)
    );

endmodule