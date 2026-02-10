// Shared Memory Arbiter

`timescale 1ns / 1ps

module Shared_Memory_Arbiter(
    input logic clk,
    input logic [NUM_BANKS-1:0] banks,

    output logic [NUM_BANKS-1:0] enable
    );

    logic [NUM_BANKS-1:0] mask;
    logic [NUM_BANKS-1:0] conflicts;

    always_comb begin
        for(int i = 0; i < NUM_BANKS; i = i+1) begin
            for (int j = i + 1; j < NUM_BANKS; j++) begin
                if (banks[i] == banks[j] && mask[i] != 1'b1 && mask[j] != 1'b1) begin
                    conflicts[j] = 1'b1; 
                end
            end
        end
    end

    always_comb begin
        for(int i = 0; i < NUM_BANKS; i = i+1) begin
            enable[i] = !(conflicts & banks);
        end
    end

    always_ff@(posedge clk) begin
        mask <= mask | enable;
    end



endmodule