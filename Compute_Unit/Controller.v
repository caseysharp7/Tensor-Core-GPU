// Controller

`timescale 1ns / 1ps

module Controller(
    input opcode, // from instruction decode

    output mem_write_en, // to data mem
    output mem_read_en, // to data mem
    output reg_write_en, // to threads reg file
    output glob_reg_write_en // to global reg file
    );




endmodule