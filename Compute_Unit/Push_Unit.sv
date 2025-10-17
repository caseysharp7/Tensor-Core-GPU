// Push Unit

`timescale 1ns / 1ps
// I think simply take in values from a warp and keep an internal 
// also need to make sure instructions execute 
// first half of the warp (threads 0,1,2,3) will load left PEs and second half (4,5,6,7) will load top PEs

module Push_Unit#(parameter DATA_WIDTH = 16)(
    input logic clk, reset,
    input logic pause, // from scheduler? if paused then whole systolic array must pause
    
    input logic [DATA_WIDTH-1:0] load_data [7:0], // from threads reg file

    output logic [DATA_WIDTH-1:0] left_corner0,
    output logic [DATA_WIDTH-1:0] left1,
    output logic [DATA_WIDTH-1:0] left2,
    output logic [DATA_WIDTH-1:0] left3,

    output logic [DATA_WIDTH-1:0] top_corner0,
    output logic [DATA_WIDTH-1:0] top1,
    output logic [DATA_WIDTH-1:0] top2,
    output logic [DATA_WIDTH-1:0] top3,

    output logic left_corner_valid, // to corner PE
    output logic left1_valid, 
    output logic left2_valid,
    output logic left3_valid,

    output logic top_corner_valid,
    output logic top1_valid,
    output logic top2_valid,
    output logic top3_valid,

    output logic matmul_done
    );

    logic [3:0] counter; // 11? total steps in the systolic array matrix processing

    assign left_corner0 = load_data[0];
    assign left1 = load_data[1];
    assign left2 = load_data[2];
    assign left3 = load_data[3];
    assign top_corner0 = load_data[4];
    assign top1 = load_data[5];
    assign top2 = load_data[6];
    assign top3 = load_data[7];

    always_comb begin
        left_corner_valid = (counter >= 0) && (counter < 4);
        left1_valid = (counter >= 1) && (counter < 5);
        left2_valid = (counter >= 2) && (counter < 6);
        left3_valid = (counter >= 3) && (counter < 7);

        top_corner_valid = (counter >= 0) && (counter < 4);
        top1_valid = (counter >= 1) && (counter < 5);
        top2_valid = (counter >= 2) && (counter < 6);
        top3_valid = (counter >= 3) && (counter < 7);
    end

    always_ff@(posedge clk or posedge reset) begin
        if(reset) begin
            counter <= 0;
        end
        else if(counter < 10 && !pause) begin
            counter <= counter + 1;
        end
    end

    assign matmul_done = counter == 10;

endmodule