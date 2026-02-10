// Shared Memory Scratchpad
// User controlled memory space

`timescale 1ps / 1ps

module Shared_Memory#(parameter NUM_BANKS = 8, ADDRESS_WIDTH = 8, DATA_WIDTH = 16)(
    input logic clk,
    input logic write_en,
    input logic [ADDRESS_WIDTH-1:0] addr [7:0],
    input logic [DATA_WIDTH-1:0] write_data [7:0],
    
    output logic [DATA_WIDTH-1:0] read_data [7:0],
    output logic bank_conflict
    );
    // Implement detection logic for if multiple threads request data from same bank then serialize the request

    logic [2:0] banks [NUM_BANKS-1:0];
    logic [DATA_WIDTH-1:0] write_data_int [NUM_BANKS-1:0];
    logic [ADDRESS_WIDTH-4:0] addr_int [NUM_BANKS-1:0];
    logic write_active;

    assign write_active = (write_en) ? 1'b1 : 1'b0;

    always_comb begin
        for(integer i = 0; i < NUM_BANKS; i = i+1) begin
            banks[i] = addr[i][2:0];
        end
    end

    Shared_Memory_Arbiter shared_mem_arb(
        .clk(clk),

    );

    always_comb begin
        for(integer i = 0; i < NUM_BANKS; i = i+1) begin
            write_data_int[banks[i]] = write_data[i];
            addr_int[banks[i]] = addr[i][ADDRESS_WIDTH-1:3];
        end
    end
    
    always_comb begin
        bank_conflict = 1'b0;
        for (int i = 0; i < NUM_BANKS; i++) begin
            for (int j = i + 1; j < NUM_BANKS; j++) begin
                if (banks[i] == banks[j]) begin
                    bank_conflict = 1'b1; 
                end
            end
        end
    end

    genvar i;
    generate
        for(i = 0; i < NUM_BANKS; i = i+1) begin : loop
            Shared_Memory_Subunit shared_mem_sub(
                .clk(clk),
                .write_en(write_active),
                .addr(addr_int[i]),
                .write_data(write_data_int[i]),
                .read_data(read_data[i])
            );
        end
    endgenerate

    // Need to implement some sort of buffer system that serializes the reads or write of the threads






endmodule