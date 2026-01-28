// Systolic Array

`timescale 1ns / 1ps

module Systolic_Array#(parameter DATA_WIDTH = 16)(
    input clk, reset, pause, 
    input [DATA_WIDTH-1:0] left_corner0_in, left1_in, left2_in, left3_in,
    input [DATA_WIDTH-1:0] top_corner0_in, top1_in, top2_in, top3_in,
    input corner_valid, 
    input left1_valid, left2_valid, left3_valid,
    input top1_valid, top2_valid, top3_valid

    output [DATA_WIDTH-1:0] result0, result1, result2, result3, result4, result5, result6, result7, result8, result9, result10, result11, result12, result13, result14, result15
    );

    wire [DATA_WIDTH-1:0] first_right1, first_right2, first_right3; // first row rights outputs
    wire [DATA_WIDTH-1:0] second_right1, second_right2, second_right3; // second row rights outputs
    wire [DATA_WIDTH-1:0] third_right1, third_right2, third_right3; // third row rights outputs
    wire [DATA_WIDTH-1:0] fourth_right1, fourth_right2, fourth_right3; // fourth row rights outputs

    wire [DATA_WIDTH-1:0] first_down1, first_down2, first_down3; // first column downs outputs
    wire [DATA_WIDTH-1:0] second_down1, second_down2, second_down3; // second column downs outputs
    wire [DATA_WIDTH-1:0] third_down1, third_down2, third_down3; // third column downs outputs
    wire [DATA_WIDTH-1:0] fourth_down1, fourth_down2, fourth_down3; // fourth column downs outputs

    PE_Edge top_left_corner      (.clk(clk), .reset(reset), .pause(pause), .left_in(left_corner0_in), .top_in(top_corner0_in), .valid_bit(corner_valid), .right_out(first_right1),  .bottom_out(first_down1),  .result(result0));
    PE_Edge left_edge1           (.clk(clk), .reset(reset), .pause(pause), .left_in(left1_in),        .top_in(first_down1),    .valid_bit(left1_valid),  .right_out(second_right1), .bottom_out(first_down2),  .result(result4));
    PE_Edge left_edge2           (.clk(clk), .reset(reset), .pause(pause), .left_in(left2_in),        .top_in(first_down2),    .valid_bit(left2_valid),  .right_out(third_right1),  .bottom_out(first_down3),  .result(result8));
    PE_Edge bottom_left_corner   (.clk(clk), .reset(reset), .pause(pause), .left_in(left3_in),        .top_in(first_down3),    .valid_bit(left3_valid),  .right_out(fourth_right1), .bottom_out(),             .result(result12));
    PE_Edge top_edge1            (.clk(clk), .reset(reset), .pause(pause), .left_in(first_right1),    .top_in(top1_in),        .valid_bit(top1_valid),   .right_out(first_right2),  .bottom_out(second_down1), .result(result1));
    PE_Edge top_edge2            (.clk(clk), .reset(reset), .pause(pause), .left_in(first_right2),    .top_in(top2_in),        .valid_bit(top2_valid),   .right_out(first_right3),  .bottom_out(third_down1),  .result(result2));
    PE_Edge top_right_corner     (.clk(clk), .reset(reset), .pause(pause), .left_in(first_right3),    .top_in(top3_in),        .valid_bit(top3_valid),   .right_out(),              .bottom_out(fourth_down1), .result(result3));

    PE_Center center1            (.clk(clk), .reset(reset), .pause(pause), .left_in(second_right1),   .top_in(second_down1),                             .right_out(second_right2), .bottom_out(second_down2), .result(result5));
    PE_Center center2            (.clk(clk), .reset(reset), .pause(pause), .left_in(second_right2),   .top_in(third_down1),                              .right_out(second_right3), .bottom_out(third_down2),  .result(result6));
    PE_Center center3            (.clk(clk), .reset(reset), .pause(pause), .left_in(third_right1),    .top_in(second_down2),                             .right_out(third_right2),  .bottom_out(second_down3), .result(result9));
    PE_Center center4            (.clk(clk), .reset(reset), .pause(pause), .left_in(third_right2),    .top_in(third_down2),                              .right_out(third_right3),  .bottom_out(third_down3),  .result(result10));
    PE_Center right_edge1        (.clk(clk), .reset(reset), .pause(pause), .left_in(second_right3),   .top_in(fourth_down1),                             .right_out(),              .bottom_out(fourth_down2), .result(result7));
    PE_Center right_edge2        (.clk(clk), .reset(reset), .pause(pause), .left_in(third_right3),    .top_in(fourth_down2),                             .right_out(),              .bottom_out(fourth_down3), .result(result11));
    PE_Center bottom_right_corner(.clk(clk), .reset(reset), .pause(pause), .left_in(fourth_right3),   .top_in(fourth_down3),                             .right_out(),              .bottom_out(),             .result(result15));
    PE_Center bottom_edge1       (.clk(clk), .reset(reset), .pause(pause), .left_in(fourth_right1),   .top_in(second_down3),                             .right_out(fourth_right2), .bottom_out(),             .result(result13));
    PE_Center bottom_edge2       (.clk(clk), .reset(reset), .pause(pause), .left_in(fourth_right2),   .top_in(third_down3),                              .right_out(fourth_right3), .bottom_out(),             .result(result14));


endmodule