// Push Unit

`timescale 1ns / 1ps
// I think simply take in values from a warp and keep an internal 
// also need to make sure instructions execute 
// first half of the warp (threads 0,1,2,3) will load left PEs and second half (4,5,6,7) will load top PEs

module Push_Unit#(parameter DATA_WIDTH = 16)(
    input logic clk, reset,
    input logic pause, // from scheduler? if paused then whole systolic array must pause
    input logic start_push, // from scheduler (control) when new push starts
    
    // input logic push_valid, // from scheduler
    input logic [DATA_WIDTH-1:0] load_data [7:0], // from threads reg file

    output logic [DATA_WIDTH-1:0] left_corner0,
    output logic [DATA_WIDTH-1:0] left1,
    output logic [DATA_WIDTH-1:0] left2,
    output logic [DATA_WIDTH-1:0] left3,

    output logic [DATA_WIDTH-1:0] top_corner0,
    output logic [DATA_WIDTH-1:0] top1,
    output logic [DATA_WIDTH-1:0] top2,
    output logic [DATA_WIDTH-1:0] top3,

    output logic corner_valid, // to corner PE
    output logic left1_valid, 
    output logic left2_valid,
    output logic left3_valid,

    output logic top1_valid,
    output logic top2_valid,
    output logic top3_valid,

    output logic matmul_done
    );

    logic [3:0] counter; // 11? total steps in the systolic array matrix processing
    logic push_valid, counter_valid;


    assign push_valid = (counter < 8 && !pause);

    always_comb begin
        if(push_valid) begin
            left_corner0 = load_data[0];
            left1 = load_data[1];
            left2 = load_data[2];
            left3 = load_data[3];
            top_corner0 = load_data[4];
            top1 = load_data[5];
            top2 = load_data[6];
            top3 = load_data[7];
        end
        else begin
            left_corner0 = 0;
            left1 = 0;
            left2 = 0;
            left3 = 0;
            top_corner0 = 0;
            top1 = 0;
            top2 = 0;
            top3 = 0;
        end
    end

    always_comb begin
        if(pause) begin
            corner_valid = 0;
            left1_valid = 0;
            left2_valid = 0;
            left3_valid = 0;
            top1_valid = 0;
            top2_valid = 0;
            top3_valid = 0;
        end
        else begin
            corner_valid = (counter >= 1) && (counter < 5);
            left1_valid = (counter >= 2) && (counter < 6);
            left2_valid = (counter >= 3) && (counter < 7);
            left3_valid = (counter >= 4) && (counter < 8);

            top1_valid = (counter >= 2) && (counter < 6);
            top2_valid = (counter >= 3) && (counter < 7);
            top3_valid = (counter >= 4) && (counter < 8);
        end
    end

    always_ff@(posedge clk or posedge reset) begin
        if(reset) begin
            counter <= 0;
        end
        else if(start_push) begin // KEEP IN MIND: computation won't start until the cycle AFTER start_push is asserted
            counter <= 1;
            counter_valid <= 1;
        end
        else if(counter < 11 && !pause && counter_valid) begin
            counter <= counter + 1;
        end
        else if(counter == 11) begin
            counter_valid <= 0;
        end
    end

    assign matmul_done = counter == 11;

endmodule