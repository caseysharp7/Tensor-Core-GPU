// Shared Memory Scratchpad
// User controlled memory space
// 4KB

`timescale 1ps / 1ps

module Shared_Memory#(parameter NUM_BANKS = 8, ADDRESS_WIDTH = 8, DATA_WIDTH = 16, NUM_THREADS = 8)(
    input logic clk, reset,
    input logic write_en,
    input logic [NUM_THREADS-1:0] active_threads,
    input logic [ADDRESS_WIDTH-1:0] threads_addr [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] threads_write_data [NUM_THREADS-1:0],
    
    output logic [DATA_WIDTH-1:0] threads_read_data [NUM_THREADS-1:0], 
    output logic warp_stall,
    output logic shared_mem_ready
    );

    logic [2:0] thread_banks [NUM_BANKS-1:0];
    logic [NUM_BANKS-1:0] threads_en;

    logic [NUM_BANKS-1:0] banks_en;
    logic [DATA_WIDTH-1:0] banks_write_data [NUM_BANKS-1:0];
    logic [ADDRESS_WIDTH-4:0] banks_addr [NUM_BANKS-1:0];
    logic [DATA_WIDTH-1:0] banks_read_data [NUM_BANKS-1:0];

    logic [2:0] banks_selection_prev [NUM_THREADS-1:0];


    always_comb begin
        for(int i = 0; i < NUM_BANKS; i = i+1) begin
            thread_banks[i] = threads_addr[i][2:0];
        end
    end

    Shared_Memory_Arbiter shared_mem_arb(
        .clk(clk),
        .reset(reset),
        .active_threads(active_threads),
        .thread_banks(thread_banks),
        
        .threads_en(threads_en),
        .warp_stall(warp_stall),
        .shared_mem_ready(shared_mem_ready)
    );

    always_comb begin
        banks_write_data = '{default: '0};
        banks_addr = '{default: '0};
        banks_en = '0;
        
        for(int i = 0; i < NUM_BANKS; i = i+1) begin
            if(threads_en[i]) begin
                banks_write_data[thread_banks[i]] = threads_write_data[i];
                banks_addr[thread_banks[i]] = threads_addr[i][ADDRESS_WIDTH-1:3];
                banks_en[thread_banks[i]] = 1'b1;
            end
        end
    end

    genvar i;
    generate
        for(i = 0; i < NUM_BANKS; i = i+1) begin : loop
            Shared_Memory_Subunit shared_mem_sub(
                .clk(clk),
                .write_en(write_en),
                .bank_en(banks_en[i]),
                .addr(banks_addr[i]),
                .write_data(banks_write_data[i]),
                .read_data(banks_read_data[i])
            );
        end
    endgenerate
    
    always_ff @(posedge clk) begin
        if (reset) begin
            banks_selection_prev <= '{default: '0};
        end 
        else begin
            for (int i = 0; i < NUM_THREADS; i = i+1) begin
                if (threads_en[i]) begin
                    banks_selection_prev[i] <= thread_banks[i];
                end
            end
        end
    end

    always_comb begin
        for (int i = 0; i < NUM_THREADS; i = i+1) begin
            threads_read_data[i] = banks_read_data[banks_selection_prev[i]];
        end
    end
endmodule