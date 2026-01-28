// Address Generation Unit
// exist inside of LSU

`timescale 1ns / 1ps

module AGU#(parameter DATA_WIDTH = 16, parameter ADDR_WIDTH = 8)(
    input logic reset,
    input logic [DATA_WIDTH-1:0] threadIdx [7:0], // come from threads reg file
    input logic [1:0] warp_num, // come from scheduler
    input logic [DATA_WIDTH-1:0] base_addr_reg, // come from global reg file
    input logic [3:0] base_addr_imm, // from instruction (probably won't have this actually because those bits used for thread mask)

    output logic [ADDR_WIDTH-1:0] addr [7:0]
    );

    // Initially I will assume all memory to be contiguous
    logic [DATA_WIDTH-1:0] base_addr;
    assign base_addr = base_addr_imm + base_addr_reg;

    logic [DATA_WIDTH-1:0] thread_num [7:0];

    integer i;
    always_comb begin
        for(i = 0; i < 8; i = i+1) begin
            thread_num[i] = threadIdx[i] - (8*warp_num); // done because if not warp 0 then threadIdx will start at 8 or 16...
            addr[i] = base_addr + thread_num[i]*i;
        end
    end

endmodule