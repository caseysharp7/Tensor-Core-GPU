`timescale 1ns / 1ps

module Mux2 #(parameter MUX_WIDTH = 16)
(   input [MUX_WIDTH-1:0] a, b,
    input sel,
    output [MUX_WIDTH-1:0] y
    );
    
    assign y = sel ? b : a;
endmodule