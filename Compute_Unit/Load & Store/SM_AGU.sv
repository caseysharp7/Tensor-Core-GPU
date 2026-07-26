// Shared memory AGU

`timescale 1ns / 1ps

module SM_AGU#(parameter DATA_WIDTH = 16, SHARED_MEM_ADDR_WIDTH = , NUM_THREADS = 8)(
    input logic [DATA_WIDTH-1:0] threadIdx [NUM_THREADS-1:0],
    input logic [DATA_WIDTH-1:0] base_addr_reg,
    input logic [DATA_WIDTH-1:0] stride_reg,

    output logic [SHARED_MEM_ADDR_WIDTH-1:0] shared_mem_addr [NUM_THREADS-1:0];
    );

    // can modify this later if decide there's a better way to address for the shared mem
    // obviously we'd want to have no bank conflicts, so consider that in future work

    always_comb begin
        for(int i = 0; i < NUM_THREADS; i = i+1) begin
            shared_mem_addr[i] = base_addr_reg + (threadIdx[i] * stride_reg);
        end
    end

endmodule
