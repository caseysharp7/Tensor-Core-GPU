// FIFO Register Buffer

`timescale 1ns / 1ps

module FIFO_Register_Buffer#(parameter DEPTH = 32, DATA_WIDTH = 16)(
    input clk, reset,
    input write_en, read_en,
    input [3:0] write_reg,
    output [3:0] read_reg

    );

    reg[$clog2(DEPTH)-1:0] wptr;
    reg[$clog2(DEPTH)-1:0] rptr;

    reg[DATA_WIDTH-1:0] fifo[DEPTH-1:0];

    wire empty, full;

    always@(posedge clk) begin
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
        end
        else begin
            if(write_en & !full) begin
                fifo[wptr] <= write_reg;
                wptr <= wptr + 1;
            end
            if(read_en & !empty) begin
                rptr <= rptr + 1;
            end
        end
    end

    assign read_reg = fifo[rptr];

    assign full = (wptr + 1) == rptr;
    assign empty = rptr == wptr;

endmodule