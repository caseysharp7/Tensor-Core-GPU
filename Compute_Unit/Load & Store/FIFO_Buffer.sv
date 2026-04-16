// FIFO Buffer / Stack

`timescale 1ns / 1ps

module FIFO_Buffer#(parameter DEPTH = 4, DATA_WIDTH = 16, NUM_THREADS = 8)(
    input logic clk, reset,
    input logic write_en, read_en,
    input logic [DATA_WIDTH-1:0] write_data [NUM_THREADS-1:0],

    output logic empty, full,
    output logic [DATA_WIDTH-1:0] read_data [NUM_THREADS-1:0]

    );

    reg [$clog2(DEPTH)-1:0] wptr;
    reg [$clog2(DEPTH)-1:0] rptr;

    reg [DATA_WIDTH-1:0] fifo [DEPTH-1:0][NUM_THREADS-1:0];

    wire empty, full;

    // add a check for if read and write en, then being full or empty is fine
    always@(posedge clk) begin
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
        end
        else begin
            if(write_en & !full) begin
                fifo[wptr] <= write_data;
                wptr <= wptr + 1;
            end
            if(read_en & !empty) begin
                rptr <= rptr + 1;
            end
        end
    end

    assign read_data = fifo[rptr];

    assign full = (wptr + 1) == rptr;
    assign empty = rptr == wptr;

endmodule