// Controller

`timescale 1ns / 1ps

module Controller(
    input reset,
    input [3:0] opcode, // from instruction buffer
    input [3:0] global_opcode, // from instruction decode
    input instr_bit_in, // from LSU (LSQ)
    input done_bit, // from LSU (LSQ)

    // controlled by lsu signals
    output reg mem_write_en, // to data mem
    output reg mem_read_en, // to data mem
    output reg reg_write_en, // to threads reg file

    // controlled by opcode
    output reg glob_reg_write_en, // to global reg file
    output reg queue_write_en,  // to LSU (LSQ)
    output reg instr_bit_out // to LSU (LSQ)
    );

    wire [1:0] complete;
    assign complete = {done_bit, instr_bit_in};

    always @(*) begin
        if(reset) begin
            mem_write_en = 0;
            mem_read_en = 0;
            reg_write_en = 0;
            glob_reg_write_en = 0;
            queue_write_en = 0;
            instr_bit_out = 0;

        end
        else begin
            case(opcode)
            4'b0001: begin // LD
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b1;
                instr_bit_out = 1'b0;

            end
            4'b0010: begin // ST
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b1;
                instr_bit_out = 1'b1;

            end
            4'b0100: begin // PUSH
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b0;
                instr_bit_out = 1'b0;

            end
            4'b0101: begin // PULL
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b0;
                instr_bit_out = 1'b0;

            end
            4'b1000: begin // LDG
                glob_reg_write_en = 1'b1;
                queue_write_en = 1'b0;
                instr_bit_out = 1'b0;

            end

            endcase

            casex(complete)
            2'b10: begin // done + LD
                mem_write_en = 1'b0;
                mem_read_en = 1'b1;
                reg_write_en = 1'b1;
            end
            2'b11: begin // done + ST
                mem_write_en = 1'b1;
                mem_read_en = 1'b0;
                reg_write_en = 1'b0;
            end
            2'b0x: begin // not done
                mem_write_en = 1'b0;
                mem_read_en = 1'b0;
                reg_write_en = 1'b0;
            end
            endcase
        end
    end

endmodule