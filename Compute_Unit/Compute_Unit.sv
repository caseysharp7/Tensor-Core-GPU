// Compute Unit
// Putting all modules together

`timescale 1ns / 1ps

module Compute_Unit#(parameter PC_WIDTH = 8,
                     parameter ADDR_WIDTH = 8,
                     parameter INST_WIDTH = 16,
                     parameter DATA_WIDTH = 16)(
    input clk, reset,
    input [DATA_WIDTH-1:0] mem_data [7:0],
    
    output [DATA_WIDTH-1:0] mem_write_data [7:0],
    output [ADDR_WIDTH-1:0] mem_write_addr [7:0]
    );

    // warp scheduler inputs
    wire instr_done_bit, matmul_done;
    wire [1:0] array_id;
    wire [3:0] opcode, target_reg, address_reg, imm_short, global_opcode, threads_mask_clear;
    // warp_num_write

    // decoder inputs
    wire[INST_WIDTH-1:0] instruction, global_instruction;

    // instruction fetch inputs
    wire[PC_WIDTH-1:0] pc, global_pc;

    // threads reg file inputs
    wire[1:0] instr_warp_out, push_warp_out, warp_num_write;
    wire[3:0] target_reg_out, push_reg_out, reg_write_addr;
    wire[DATA_WIDTH-1:0] reg_write_data [7:0];

    // global reg file inputs
    wire[3:0] address_reg_out, global_reg;
    wire [7:0] imm_long;

    // LSU inputs
    wire[3:0] imm_short_lsu;
    wire[DATA_WIDTH-1:0] glob_reg_data;
    wire [DATA_WIDTH-1:0] threadIdx [8];
    wire [DATA_WIDTH-1:0] reg_data_instr [8];
    // target_reg_out

    // Push Unit inputs
    wire pause;
    wire [DATA_WIDTH-1:0] reg_data_push [8];

    // Systolic Array input
    wire [DATA_WIDTH-1:0] left_corner0, left1, left2, left3, top_corner0, top1, top2, top3;
    wire corner_valid, left1_valid, left2_valid, left3_valid, top1_valid, top2_valid, top3_valid;
    
    Warp_Scheduler warp_sched_inst(
        .clk(clk), .reset(reset),
        .opcode(opcode), // from decoder {
        .target_reg(target_reg),
        .address_reg(address_reg),
        .imm_short(imm_short),
        .array_id(array_id), // }
        .global_opcode(global_opcode),
        .warp_num_clear(warp_num_write), // from LSU
        .threads_mask_clear(threads_mask_clear), // from LSU
        .done_bit(instr_done_bit), // from LSU
        .matmul_done(matmul_done), // from push or pull unit when matmul finishes

        .pc(pc), // to instr fetch
        .global_pc_out(global_pc), // to instr fetch
        .pause(pause), // to Push Unit
        .target_reg_out(target_reg_out), // to threads register file
        .address_reg_out(address_reg_out), // to global register file
        .imm_short_out(imm_short_lsu),
        .instr_warp_out(instr_warp_out), // to threads register file
        .push_warp_out(push_warp_out), // to threads register file
        .push_reg_out(push_reg_out) // to threads register file
    );

    Instruction_Decoder decoder_inst(
        .instruction(instruction), // from instruction_fetch
        .global_instruction(global_instruction), // from instruction fetch 

        .opcode(opcode), // to scheduler {
        .target_reg(target_reg),
        .address_reg(address_reg),
        .imm_short(imm_short),
        .array_id(array_id),
        .global_opcode(global_opcode), // }
        .global_reg(global_reg),
        .imm_long(imm_long)
    );

    Instruction_Fetch instr_fetch_inst(
        .pc(pc), // from warp scheduler
        .global_pc(global_pc), // from warp scheduler

        .instruction(instruction), // to instr decoder
        .global_instruction(global_instruction) // to instr decoder
    );

    Threads_Register_File thr_reg_file(
        .clk(clk), .reset(reset),
        .reg_write_en(),  // will come from controller
        .reg_write_addr(reg_write_addr), // will come from LSU
        .reg_write_data(reg_write_data), // will come from LSU
        .warp_num_write(warp_num_write), // from LSU
        .instr_reg_read_addr(target_reg_out), // will come from scheduler (instruction buffer)
        .push_reg_read_addr(push_reg_out), // from scheduler (FIFO Register Buffer)
        .instr_warp_num_read(instr_warp_out), // will come from scheduler (warp selector)
        .push_warp_num_read(push_warp_out), // come from scheduler (warp selector)
        
        .blockIdx(), // from outside of compute unit
        .blockDim(), // 1D, number of threads in a block, comes from outside of compute unit

        .reg_read_data_instr(reg_data_instr), 
        .threadIdx(threadIdx),  // goes to LSU (AGU)
        .reg_read_data_push(reg_data_push) // to push unit
    );

    Global_Register_File glob_reg_file(
        .clk(clk), .reset(reset),
        .glob_reg_write_en(),  // will come from controller
        .glob_reg_write_addr(global_reg), // will come from decoder (instruction)
        .glob_reg_write_data(imm_long), // from immediate in decoder (instruction)
        .glob_reg_read_addr(address_reg_out), // will come from scheduler (instruction)

        .glob_reg_read_data(glob_reg_data)
    );

    LSU lsu_inst(
        .clk(clk), .reset(reset), 
        .threadIdx(threadIdx), // come from threads reg file
        .warp_num(instr_warp_out), // come from scheduler
        .base_addr_reg(glob_reg_data), // come from global reg file
        .base_addr_imm(), // from instruction (don't need if instruction uses threads mask)

        .dest_reg_addr_in(target_reg_out), // from instruction
        .threads_mask(imm_short), // from instruction
        .instr_bit_in(), // from controller
        .queue_write_en(), // from controller

        .reg_read_data(reg_data_instr), // will come from threads reg file
        .mem_read_data(mem_data), // from data memory 


        .reg_write_data(reg_write_data), // to threads reg file (from data memory most likely)
        .mem_write_data(mem_write_data), // to data memory (from threads reg file most likely)
        
        .threads_mask_out(threads_mask_clear),
        .reg_addr_out(reg_write_addr), // to threads reg file after done bit activated, for a load (with a write we will already have data from threads reg file) 
        .warp_num_out(warp_num_write), // to scheduler (scoreboard)
        .done_bit_out(instr_done_bit), // to scheduler (scoreboard)

        .addr_out(mem_write_addr) // to data memory
    );

    Push_Unit push_unit_inst(
        .clk(clk), .reset(reset),
        .pause(pause), // from scheduler? if paused then whole systolic array must pause
        // .push_valid(), // from scheduler (controller)
        .load_data(reg_data_push), // from threads reg file


        .left_corner0(left_corner0),
        .left1(left1),
        .left2(left2),
        .left3(left3),

        .top_corner0(top_corner0),
        .top1(top1),
        .top2(top2),
        .top3(top3),

        .corner_valid(corner_valid), // to corner PE
        .left1_valid(left1_valid), 
        .left2_valid(left2_valid),
        .left3_valid(left3_valid),

        .top1_valid(top1_valid),
        .top2_valid(top2_valid),
        .top3_valid(top3_valid),

        .matmul_done(matmul_done)
    );

    Systolic_Array sys_array_inst(
        .clk(clk), .reset(reset), .pause(pause), 
        .left_corner0_in(left_corner0), .left1_in(left1), .left2_in(left2), .left3_in(left3),
        .top_corner0_in(top_corner0), .top1_in(top1), .top2_in(top2), .top3_in(top3),
        .corner_valid(corner_valid), 
        .left1_valid(left1_valid), .left2_valid(left2_valid), .left3_valid(left3_valid),
        .top1_valid(top1_valid), .top2_valid(top2_valid), .top3_valid(top3_valid)

    );


    endmodule