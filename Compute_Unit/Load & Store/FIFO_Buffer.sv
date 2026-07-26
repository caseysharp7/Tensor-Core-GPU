// FIFO Buffer / Stack

`timescale 1ns / 1ps

module FIFO_Buffer#(parameter DEPTH = 4, DATA_WIDTH = 16, ADDR_WIDTH = , NUM_THREADS = 8)(
    input logic clk, reset,
    input logic write_en, read_en,
    input logic [DATA_WIDTH-1:0] data_in [NUM_THREADS-1:0],
    input logic [ADDR_WIDTH-1:0] address_in [NUM_THREADS-1:0],
    input logic [NUM_THREADS-1:0] active_threads_in,
    input logic [1:0] warp_num_in,
    input logic [3:0] reg_num_in,
    input logic instr_type_in,

    output logic empty, full,
    output logic [DATA_WIDTH-1:0] data_out [NUM_THREADS-1:0],
    output logic [ADDR_WIDTH-1:0] address_out [NUM_THREADS-1:0],
    output logic [NUM_THREADS-1:0] active_threads_out,
    output logic [1:0] warp_num_out,
    output logic [3:0] reg_num_out,
    output logic instr_type_out
    );

    reg [$clog2(DEPTH):0] wptr;
    reg [$clog2(DEPTH):0] rptr;

    typedef struct {
        logic [ADDR_WIDTH-1:0] address [NUM_THREADS-1:0];
        logic [DATA_WIDTH-1:0] data [NUM_THREADS-1:0];
        logic [NUM_THREADS-1:0] active_threads;
        logic [1:0] warp_num;
        logic [3:0] reg_num;
        logic instr_type;
    } fifo_struct;

    fifo_struct fifo [DEPTH-1:0];


    // add a check for if read and write en, then being full or empty is fine
    always@(posedge clk) begin
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
        end
        else begin
            if(write_en & !full) begin
                for(int i = 0; i < DEPTH; i = i+1) begin
                    fifo[wptr].address[i] <= address_in[i];
                    fifo[wptr].data[i] <= data_in[i];
                end
                fifo[wptr].active_threads <= active_threads_in;
                fifo[wptr].warp_num <= warp_num_in;
                fifo[wptr].reg_num <= reg_num_in;
                fifo[wptr].instr_type <= instr_type_in;
                wptr <= wptr + 1;
            end
            if(read_en & !empty) begin
                rptr <= rptr + 1;
            end
        end
    end

    always_comb begin
        for(int i = 0; i < DEPTH; i = i+1) begin
            address_out[i] = fifo[rptr].address[i];
            data_out[i] = fifo[rptr].data[i];
        end
        active_threads_out = fifo[rptr].active_threads;
        warp_num_out = fifo[rptr].warp_num;
        reg_num_out = fifo[rptr].reg_num;
        instr_type_out = fifo[rptr].instr_type;
    end

    assign full = (wptr + 1) == rptr;
    assign empty = rptr == wptr;

endmodule
