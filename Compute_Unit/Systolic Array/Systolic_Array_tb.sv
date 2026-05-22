`timescale 1ns / 1ps
`define DATA_WIDTH 16

module Systolic_Array_tb;
    // clock and control
    logic clk;
    logic reset;
    logic pause;

    logic start_push;
    logic start_pull;

    parameter DATA_WIDTH = `DATA_WIDTH;

    // load data array (threads 0..7)
    logic [DATA_WIDTH-1:0] load_data [7:0];

    // push outputs
    logic [DATA_WIDTH-1:0] left_corner0;
    logic [DATA_WIDTH-1:0] left1;
    logic [DATA_WIDTH-1:0] left2;
    logic [DATA_WIDTH-1:0] left3;
    logic [DATA_WIDTH-1:0] top_corner0;
    logic [DATA_WIDTH-1:0] top1;
    logic [DATA_WIDTH-1:0] top2;
    logic [DATA_WIDTH-1:0] top3;

    logic corner_valid;
    logic left1_valid;
    logic left2_valid;
    logic left3_valid;
    logic top1_valid;
    logic top2_valid;
    logic top3_valid;
    logic matmul_done;

    // systolic results
    logic [DATA_WIDTH-1:0] result0;
    logic [DATA_WIDTH-1:0] result1;
    logic [DATA_WIDTH-1:0] result2;
    logic [DATA_WIDTH-1:0] result3;
    logic [DATA_WIDTH-1:0] result4;
    logic [DATA_WIDTH-1:0] result5;
    logic [DATA_WIDTH-1:0] result6;
    logic [DATA_WIDTH-1:0] result7;
    logic [DATA_WIDTH-1:0] result8;
    logic [DATA_WIDTH-1:0] result9;
    logic [DATA_WIDTH-1:0] result10;
    logic [DATA_WIDTH-1:0] result11;
    logic [DATA_WIDTH-1:0] result12;
    logic [DATA_WIDTH-1:0] result13;
    logic [DATA_WIDTH-1:0] result14;
    logic [DATA_WIDTH-1:0] result15;

    // pull outputs (writes back to register file)
    logic [DATA_WIDTH-1:0] reg_write_data [7:0];

    // Instantiate Push Unit
    Push_Unit #(.DATA_WIDTH(DATA_WIDTH)) push_u (
        .clk(clk), .reset(reset), .pause(pause), .start_push(start_push),
        .load_data(load_data),
        .left_corner0(left_corner0), .left1(left1), .left2(left2), .left3(left3),
        .top_corner0(top_corner0), .top1(top1), .top2(top2), .top3(top3),
        .corner_valid(corner_valid), .left1_valid(left1_valid), .left2_valid(left2_valid), .left3_valid(left3_valid),
        .top1_valid(top1_valid), .top2_valid(top2_valid), .top3_valid(top3_valid),
        .matmul_done(matmul_done)
    );

    // Instantiate Systolic Array
    Systolic_Array #(.DATA_WIDTH(DATA_WIDTH)) sa (
        .clk(clk), .reset(reset), .pause(pause),
        .left_corner0_in(left_corner0), .left1_in(left1), .left2_in(left2), .left3_in(left3),
        .top_corner0_in(top_corner0), .top1_in(top1), .top2_in(top2), .top3_in(top3),
        .corner_valid(corner_valid), .left1_valid(left1_valid), .left2_valid(left2_valid), .left3_valid(left3_valid),
        .top1_valid(top1_valid), .top2_valid(top2_valid), .top3_valid(top3_valid),
        .result0(result0), .result1(result1), .result2(result2), .result3(result3),
        .result4(result4), .result5(result5), .result6(result6), .result7(result7),
        .result8(result8), .result9(result9), .result10(result10), .result11(result11),
        .result12(result12), .result13(result13), .result14(result14), .result15(result15)
    );

    // Instantiate Pull Unit
    Pull_Unit pull_u (
        .clk(clk), .reset(reset), .start_pull(start_pull), .matmul_done(matmul_done),
        .result0(result0), .result1(result1), .result2(result2), .result3(result3),
        .result4(result4), .result5(result5), .result6(result6), .result7(result7),
        .result8(result8), .result9(result9), .result10(result10), .result11(result11),
        .result12(result12), .result13(result13), .result14(result14), .result15(result15),
        .reg_write_data(reg_write_data)
    );

    // Clock generator: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Full 4x4 matrix multiplication test
    // Matrix A (4x4) and Matrix B (4x4) to compute C = A * B
    logic [DATA_WIDTH-1:0] matrix_a [3:0][3:0];
    logic [DATA_WIDTH-1:0] matrix_b [3:0][3:0];
    logic [DATA_WIDTH-1:0] matrix_c [3:0][3:0];
    
    initial begin
        $dumpfile("Systolic_Array_tb.vcd");
        $dumpvars(0, Systolic_Array_tb);

        // Initialize test matrices
        // Matrix A: simple incremental values
        matrix_a[0][0] = 16'd1;  matrix_a[0][1] = 16'd2;  matrix_a[0][2] = 16'd3;  matrix_a[0][3] = 16'd4;
        matrix_a[1][0] = 16'd5;  matrix_a[1][1] = 16'd6;  matrix_a[1][2] = 16'd7;  matrix_a[1][3] = 16'd8;
        matrix_a[2][0] = 16'd9;  matrix_a[2][1] = 16'd10; matrix_a[2][2] = 16'd11; matrix_a[2][3] = 16'd12;
        matrix_a[3][0] = 16'd13; matrix_a[3][1] = 16'd14; matrix_a[3][2] = 16'd15; matrix_a[3][3] = 16'd16;

        // Matrix B: different values
        matrix_b[0][0] = 16'd1;  matrix_b[1][0] = 16'd2;  matrix_b[2][0] = 16'd3;  matrix_b[3][0] = 16'd4;
        matrix_b[0][1] = 16'd5;  matrix_b[1][1] = 16'd6;  matrix_b[2][1] = 16'd7;  matrix_b[3][1] = 16'd8;
        matrix_b[0][2] = 16'd9;  matrix_b[1][2] = 16'd10; matrix_b[2][2] = 16'd11; matrix_b[3][2] = 16'd12;
        matrix_b[0][3] = 16'd13; matrix_b[1][3] = 16'd14; matrix_b[2][3] = 16'd15; matrix_b[3][3] = 16'd16;

        $display("=== 4x4 Systolic Array Matrix Multiplication Test ===");
        $display("Matrix A:");
        for(int i=0; i<4; i++) begin
            $display("%d %d %d %d", matrix_a[i][0], matrix_a[i][1], matrix_a[i][2], matrix_a[i][3]);
        end
        $display("Matrix B:");
        for(int i=0; i<4; i++) begin
            $display("%d %d %d %d", matrix_b[i][0], matrix_b[i][1], matrix_b[i][2], matrix_b[i][3]);
        end

        // Initialize signals
        reset = 1; pause = 0; start_push = 0; start_pull = 0;
        for(int i=0; i<8; i++) load_data[i] = 16'h0010;

        #20; // hold reset
        $display("\nCorner valid before clock edge: %b at time %0t", corner_valid, $time);

        reset = 0;
        #10;

        $display("\nCorner valid before clock edge: %b at time %0t", corner_valid, $time);


        // Start push instruction
        $display("\n--- Starting Push (Loading Systolic Array) at %0t ---", $time);
        $display("\nstart push value: %b", start_push);
        $display("\nCorner valid before clock edge: %b at time %0t", corner_valid, $time);
        
        @(posedge clk);
        start_push = 1;

        $display("\nCorner valid after clock edge: %b at time %0t", corner_valid, $time);
        $display("\nstart push value: %b", start_push);

        $display("\nCycle -1 prepared.");
            $display("Left input (A): %d %d %d %d", load_data[0], load_data[1], load_data[2], load_data[3]);
            $display("Top inputs (B): %d %d %d %d", load_data[4], load_data[5], load_data[6], load_data[7]);

            $display("\nCorner valid: %b, Left1 valid: %b, Left2 valid: %b, Left3 valid: %b, Top1 valid: %b, Top2 valid: %b, Top3 valid: %b",
                corner_valid, left1_valid, left2_valid, left3_valid, top1_valid, top2_valid, top3_valid);

            $display("\nResults from Systolic Array:");
            $display("result[0:3]   = %d %d %d %d", result0, result1, result2, result3);
            $display("result[4:7]   = %d %d %d %d", result4, result5, result6, result7);
            $display("result[8:11]  = %d %d %d %d", result8, result9, result10, result11);
            $display("result[12:15] = %d %d %d %d", result12, result13, result14, result15);


        // FIXED LOOP: Apply data immediately to the current counter phase, THEN cycle the clock
        for(int cycle=0; cycle<10; cycle++) begin
            
            // 1. Update load_data instantly using blocking assignments
            for(int i=0; i<4; i++) begin
                // Left PE inputs (Matrix A)
                if(cycle-i >= 0 && cycle-i < 4) begin
                    load_data[i] = matrix_a[i][cycle-i];
                end
                
                // Top PE inputs (Matrix B)
                if(cycle-i >= 0 && cycle-i < 4) begin
                    load_data[4+i] = matrix_b[cycle-i][i];
                end
            end
            
            // Display loading pattern for clarity
            $display("\nCycle %0d prepared.", cycle);
            $display("Left input (A): %d %d %d %d", load_data[0], load_data[1], load_data[2], load_data[3]);
            $display("Top inputs (B): %d %d %d %d", load_data[4], load_data[5], load_data[6], load_data[7]);

            $display("\nCorner valid: %b, Left1 valid: %b, Left2 valid: %b, Left3 valid: %b, Top1 valid: %b, Top2 valid: %b, Top3 valid: %b",
                corner_valid, left1_valid, left2_valid, left3_valid, top1_valid, top2_valid, top3_valid);

            $display("\nResults from Systolic Array:");
            $display("result[0:3]   = %d %d %d %d", result0, result1, result2, result3);
            $display("result[4:7]   = %d %d %d %d", result4, result5, result6, result7);
            $display("result[8:11]  = %d %d %d %d", result8, result9, result10, result11);
            $display("result[12:15] = %d %d %d %d", result12, result13, result14, result15);
            
            // NOW advance the clock. The hardware will sample perfectly aligned data.
            @(posedge clk);
            start_push = 0; // De-assert start_push after the first cycle to allow the counter to run freely
        end

        // Wait for matmul to complete
        wait(matmul_done == 1);
        $display("Matmul complete at %0t", $time);

        // Pull results
        $display("\n--- Pulling Results ---", $time);
        @(posedge clk);
        start_pull = 1;
        @(posedge clk);
        start_pull = 0;

        // Wait for pull to complete
        #50;

        // Display results
        $display("\nResults from Systolic Array:");
        $display("result[0:3]   = %d %d %d %d", result0, result1, result2, result3);
        $display("result[4:7]   = %d %d %d %d", result4, result5, result6, result7);
        $display("result[8:11]  = %d %d %d %d", result8, result9, result10, result11);
        $display("result[12:15] = %d %d %d %d", result12, result13, result14, result15);

        $display("\nData from Pull Unit (first batch):");
        $display("reg_write[0:7] = %d %d %d %d %d %d %d %d", 
            reg_write_data[0], reg_write_data[1], reg_write_data[2], reg_write_data[3],
            reg_write_data[4], reg_write_data[5], reg_write_data[6], reg_write_data[7]);

        // Compute expected results for verification
        $display("\n--- Expected Results (A * B) ---");
        for(int i=0; i<4; i++) begin
            for(int j=0; j<4; j++) begin
                int sum = 0;
                for(int k=0; k<4; k++) begin
                    sum += matrix_a[i][k] * matrix_b[k][j];
                end
                matrix_c[i][j] = sum;
                $write("%d ", matrix_c[i][j]);
            end
            $display("");
        end

        $finish;
    end

endmodule
