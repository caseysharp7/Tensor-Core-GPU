// Address Generation Unit
// exist inside of LSU

`timescale 1ns / 1ps

module AGU#(parameter DATA_WIDTH = 16, parameter ADDR_WIDTH = )(
    input logic [DATA_WIDTH-1:0] threadIdx [7:0], // come from threads reg file
    input logic [DATA_WIDTH-1:0] base_addr_reg, // come from global reg file
    input logic [DATA_WIDTH-1:0] stride_reg, // from global reg file

    output logic [ADDR_WIDTH-1:0] addr [7:0]
    );

    integer i;
    always_comb begin
        for(i = 0; i < 8; i = i+1) begin
            // Can try later to not use multiplier because expensive
            addr[i] = base_addr_reg + (threadIdx[i] * stride_reg);
        end
    end

endmodule