// Controller

`timescale 1ns / 1ps

module Controller(
    input reset,
    input [3:0] opcode, // from instruction buffer
    input instr_bit_in, // from LSU (LSQ)
    input done_bit, // from LSU (LSQ)

    // controlled by lsu signals
    output mem_write_en, // to data mem
    output mem_read_en, // to data mem
    output reg_write_en, // to threads reg file

    // controlled by opcode
    output glob_reg_write_en, // to global reg file
    output queue_write_en,  // to LSU (LSQ)
    output instr_bit_out, // to LSU (LSQ)
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
            0001: begin // LD
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b1;
                instr_bit_out = 1'b0;

            end
            0010: begin // ST
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b1;
                instr_bit_out = 1'b1;

            end
            0100: begin // PUSH
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b0;
                instr_bit_out = 1'b0;

            end
            0101: begin // PULL
                glob_reg_write_en = 1'b0;
                queue_write_en = 1'b0;
                instr_bit_out = 1'b0;

            end
            1000: begin // LDG
                glob_reg_write_en = 1'b1;
                queue_write_en = 1'b0;
                instr_bit_out = 1'b0;

            end

            endcase

            casex(complete)
            10: begin // done + LD
                mem_write_en = 1'b0;
                mem_read_en = 1'b1;
                reg_write_en = 1'b1;
            end
            11: begin // done + ST
                mem_write_en = 1'b1;
                mem_read_en = 1'b0;
                reg_write_en = 1'b0;
            end
            0x: begin // not done
                mem_write_en = 1'b0;
                mem_read_en = 1'b0;
                reg_write_en = 1'b0;
            end
            endcase
        end
    end




endmodule