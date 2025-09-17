// Load Store Queue

module LSQ( 
    input logic clk, reset,
    input logic [1:0] warp_num,
    input logic [3:0] dest_reg,
    input logic [ADDR_WIDTH-1:0] addr [7:0], 
    input logic instr_bit, // from controller (tells if its a load (0) or store(1))

    input logic queue_write_en, // from controller

    output logic [1:0] warp_num_q,
    output logic [3:0] dest_reg_q,
    output logic [ADDR_WIDTH-1:0] addr_q [7:0], 
    output logic instr_bit_q,
    output logic done_bit_q
    ); // need to add data slot for writes

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
    } queue_input;

    queue_input queue [QUEUE_SIZE-1:0];

    integer i;
    always_ff @(posedge clk) begin
        if(reset) begin
            for(i = 0; i < QUEUE_SIZE; i = i+1) begin
                queue[i].counter <= 3'd0;
                queue[i].instr_bit <= 1'd0;
                queue[i].warp_num <= 2'd0;
                queue[i].dest_reg <= 4'd0;
                queue[i].addr <= '{default:'0};
                queue[i].valid_bit <= 1'b0;
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
            queue[write_ptr].instr_bit <= instr_bit;
            queue[write_ptr].warp_num <= warp_num;
            queue[write_ptr].dest_reg <= dest_reg;
            queue[write_ptr].addr <= addr;
            queue[write_ptr].valid_bit <= 1'b1;
            write_ptr <= write_ptr + 1;
        end
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            read_ptr <= 0;
            done_bit <= 0;
        end
        else if(queue[read_ptr].counter == 0 && queue[read_ptr].valid_bit) begin
            instr_bit_q <= queue[read_ptr].instr_bit;
            warp_num_q <= queue[read_ptr].warp_num;
            dest_reg_q <= queue[read_ptr].dest_reg;
            addr_q <= queue[read_ptr].addr;
            
            done_bit <= 1;

            read_ptr = read_ptr+1;
        end
        else begin
            done_bit <= 0;
        end
    end

    assign full = (write_ptr+1) == read_ptr;
    assign empty = write_ptr == read_ptr;

endmodule