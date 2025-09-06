`timescale 1ns / 1ps

module mux4(
    input [PC_WIDTH-1:0] a,b,c,d,
    input [1:0] sel,
    output [PC_WIDTH-1:0] y
    );

    parameter PC_WIDTH = 5;
    
    assign y = sel[1] ? (sel[0] ? d : c) : (sel[0] ? b : a);
endmodule
