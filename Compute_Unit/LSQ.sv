// Load Store Queue
`timescale 1ns / 1ps
// to simulate the time to access main memory to show the processor works at hiding latency
// get the data from the reg for a store or the data from the data mem for a load and simply keep it here
// for some clock cycles and then release it to the rest of the processor

module LSQ( 
    input logic clk, reset,
    input logic [1:0] warp_num_in_q, // from scheduler 
    input logic [3:0] dest_reg_in_q, // from instruction, this will be a write reg to the threads reg file
    input logic [ADDR_WIDTH-1:0] addr_in_q [7:0],  
    input logic instr_bit_in_q, // from controller (tells if its a load (0) or store(1))
    input logic [3:0] threads_mask_in_q, // from instruction
    input logic [DATA_WIDTH-1:0] reg_data_in_q, // from threads register file

    input logic queue_write_en, // from controller

    output logic [1:0] warp_num_out_q,
    output logic [3:0] dest_reg_out_q,
    output logic [ADDR_WIDTH-1:0] addr_out_q [7:0], 
    output logic instr_bit_out_q,
    output logic done_bit_q,
    output logic [3:0] threads_mask_out_q,
    output logic [DATA_WIDTH-1:0] reg_data_out_q
    ); 

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 8;
    parameter QUEUE_SIZE = 32;

    logic [$clog2(QUEUE_SIZE)-1:0] write_ptr;
    logic [$clog2(QUEUE_SIZE)-1:0] read_ptr;

    logic full;
    logic empty;

    // counter to simulate the time it takes to access memory
    // first 3 bits will act as the counter
    typedef struct packed{
        logic [2:0] counter;
        logic instr_bit;
        logic [1:0] warp_num;
        logic [3:0] dest_reg;
        logic [ADDR_WIDTH-1:0] addr [7:0];
        logic valid_bit;
        logic [3:0] threads_mask;
        logic [DATA_WIDTH-1:0] reg_data;
    } queue_input;

    queue_input queue [QUEUE_SIZE-1:0];

    integer i;
    always_ff @(posedge clk) begin
        if(reset) begin
            for(i = 0; i < QUEUE_SIZE; i = i+1) begin
                queue[i].counter <= 3'd5;
                queue[i].instr_bit <= 1'd0;
                queue[i].warp_num <= 2'd0;
                queue[i].dest_reg <= 4'd0;
                queue[i].addr <= '{default:'0};
                queue[i].valid_bit <= 1'b0;
                queue[i].threads_mask <= 4'd0;
                queue[i].reg_data <= 16'd0;
            end
        end else begin
            for(i = 0; i < QUEUE_SIZE; i=i+1) begin
                if(queue[i].valid_bit && queue[i].counter > 0) begin
                    queue[i].counter <= queue[i].counter - 1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            write_ptr <= 0;
        end 
        else if(queue_write_en & !full) begin
            queue[write_ptr].counter <= 3'd5;
            queue[write_ptr].instr_bit <= instr_bit_in_q;
            queue[write_ptr].warp_num <= warp_num_in_q;
            queue[write_ptr].dest_reg <= dest_reg_in_q;
            queue[write_ptr].addr <= addr_in_q;
            queue[write_ptr].valid_bit <= 1'b1;
            queue[write_ptr].threads_masks <= threads_mask_in_q;
            queue[write_ptr].reg_data <= reg_data_in_q;
            write_ptr <= write_ptr + 1;
        end
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            read_ptr <= 0;
            done_bit_q <= 0;
        end
        else if(queue[read_ptr].counter == 0 && queue[read_ptr].valid_bit) begin
            instr_bit_out_q <= queue[read_ptr].instr_bit;
            warp_num_out_q <= queue[read_ptr].warp_num;
            dest_reg_out_q <= queue[read_ptr].dest_reg;
            addr_out_q <= queue[read_ptr].addr;
            threads_mask_out_q <= queue[read_ptr].threads_mask;
            reg_data_out_q <= queue[read_ptr].reg_data;
            
            done_bit_q <= 1;

            read_ptr <= read_ptr+1;
        end
        else begin
            done_bit_q <= 0;
        end
    end

    assign full = (write_ptr+1) == read_ptr;
    assign empty = write_ptr == read_ptr;

endmodule