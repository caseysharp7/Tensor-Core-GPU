// Instruction Buffer
// output all of their next instructions and then do a check with the warp mask to see if they'll be able to 
// do that instruction in the next cycle depending on if the threads the warp needs are active or not and then
// use a bit in the warp mask to dictate whether that warp can be used or not

module Instruction_Buffer(
    input logic clk, reset,
    input logic buffer_write_en, // from controller
    input logic [3:0] opcode_in, // from decoder {
    input logic [3:0] target_reg_in,
    input logic [3:0] address_reg_in,
    input logic [3:0] imm_short_in,
    input logic [1:0] array_id_in, // }
    input logic [1:0] warp_num_store, // come from decoder or instr fetch once future instruction in being loaded
    output logic [3:0] opcode_out [3:0], // to scheduler {
    output logic [3:0] target_reg_out [3:0],
    output logic [3:0] address_reg_out [3:0],
    output logic [3:0] imm_short_out [3:0],
    output logic [1:0] array_id_out [3:0] // }
    );

    parameter BUFFER_WIDTH = 4 + 4 + 4 + 4 + 2;
    parameter NUM_WARPS = 4;

    reg [BUFFER_WIDTH-1:0] buffer [3:0];

    integer i;
    always_ff @(posedge clk) begin
        if(reset) begin
            for(i = 0; i < NUM_WARPS; i = i+1) begin
                buffer[i] <= {BUFFER_WIDTH{0}};
            end
        end
        else if(buffer_write_en) begin
            buffer[warp_num_store] <= {opcode_in, target_reg_in, address_reg_in, imm_short_in, array_id_in};
        end
    end

    always_comb begin
        for(i = 0; i < NUM_WARPS; i = i+1) begin
            opcode_out[i] = buffer[i][BUFFER_WIDTH-1 -: 4];
            target_reg_out[i] = buffer[i][BUFFER_WIDTH-5 -: 4];
            address_reg_out[i] = buffer[i][BUFFER_WIDTH-9 -: 4];
            imm_short_out[i] = buffer[i][BUFFER_WIDTH-13 -: 4];
            array_id_out[i] = buffer[i][BUFFER_WIDTH-17 -: 2];
        end
    end

endmodule