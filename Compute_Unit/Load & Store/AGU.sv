// Address Generation Unit
// exist inside of LSU

`timescale 1ns / 1ps

module AGU#(parameter DATA_WIDTH = 16, ADDR_WIDTH = , NUM_THREADS = 8)(
    input logic [DATA_WIDTH-1:0] threadIdx [NUM_THREADS-1:0], // come from LSU
    input logic [DATA_WIDTH-1:0] base_addr_reg, // come from global reg file
    input logic [DATA_WIDTH-1:0] stride_reg, // from global reg file

    output logic [ADDR_WIDTH-1:0] addr [NUM_THREADS-1:0]
    );

    // future work: add different addressing methods than just base + thread*stride;

    integer i;
    always_comb begin
        for(i = 0; i < NUM_THREADS; i = i+1) begin
            // Can try later to not use multiplier because expensive
            addr[i] = base_addr_reg + (threadIdx[i] * stride_reg);
        end
    end

endmodule
