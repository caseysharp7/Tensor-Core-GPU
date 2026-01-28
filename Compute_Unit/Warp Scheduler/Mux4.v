`timescale 1ns / 1ps

module Mux4#(parameter MUX_WIDTH = 5) (
    input [MUX_WIDTH-1:0] a,b,c,d,
    input [1:0] sel,
    output [MUX_WIDTH-1:0] y
    );

    
    assign y = sel[1] ? (sel[0] ? d : c) : (sel[0] ? b : a);
endmodule
