// Shared Memory Scratchpad
// User controlled memory space
// 4KB

`timescale 1ps / 1ps

module Shared_Memory#(parameter NUM_BANKS = 8, TOTAL_ENTRIES = 2048,ADDRESS_WIDTH = $clog2(TOTAL_ENTRIES), DATA_WIDTH = 16, NUM_THREADS = 8)(
    input logic clk, reset,
    input logic mem_req, // will come from LSU when a shared mem load is requested
    input logic write_en,
    input logic [NUM_THREADS-1:0] active_threads,
    input logic [ADDRESS_WIDTH-1:0] threads_addr [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] threads_write_data [NUM_THREADS-1:0],
    
    output logic [DATA_WIDTH-1:0] threads_read_data [NUM_THREADS-1:0], 
    output logic warp_stall,
    output logic shared_mem_data_ready
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
        .mem_req(mem_req),
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

    // Internal storage for the reassembled warp data
    logic [DATA_WIDTH-1:0] read_completion_buffer [NUM_THREADS-1:0];
    
    // Delayed signals to account for 1-cycle memory latency
    logic [NUM_THREADS-1:0] threads_en_d1;
    logic [2:0] thread_banks_d1 [NUM_THREADS-1:0];
    logic warp_stall_d1;

    always_ff @(posedge clk) begin
        if (reset) begin
            threads_en_d1   <= '0;
            warp_stall_d1   <= '0;
            for (int i=0; i<NUM_THREADS; i++) begin
                thread_banks_d1[i] <= '0;
            end
        end 
        else begin
            threads_en_d1   <= threads_en; // From Arbiter
            warp_stall_d1   <= warp_stall; // From Arbiter
            thread_banks_d1 <= thread_banks;
        end
    end

    // Store data into the buffer as it arrives from banks
    // This happens in the cycle after the arbiter grants access
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i=0; i<NUM_THREADS; i++) begin
                read_completion_buffer[i] <= '0;
            end
        end 
        else begin
            for (int i=0; i<NUM_THREADS; i++) begin
                if (threads_en_d1[i]) begin
                    // Map the correct bank's data back to the specific thread
                    read_completion_buffer[i] <= banks_read_data[thread_banks_d1[i]];
                end
            end
        end
    end

    // only present data to LSU when the sequence is complete
    // warp was stalling, and now it isn't.
    logic data_collection_complete;
    assign data_collection_complete = (warp_stall_d1 == 1'b1 && warp_stall == 1'b0) || (warp_stall == 1'b0 && active_threads != 0);

    always_comb begin
        if (data_collection_complete) begin
            threads_read_data = read_completion_buffer;
            shared_mem_data_ready = 1'b1; // Signal to LSU that the block is valid
        end else begin
            threads_read_data = '{default: '0};
            shared_mem_data_ready = 1'b0;
        end
    end
endmodule