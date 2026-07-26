// Memory Buffer
// Buffer to hold data + address coming back from memory for cache refill

`timescale 1ns / 1ps

module Memory_Buffer#(parameter DEPTH = 8, DATA_WIDTH = 16, ADDR_WIDTH = , NUM_THREADS = 8)(
    input logic clk, reset,

    input write_en, // from memory controller when data back from memory
    input read_en, // from cache when cache accepts new data

    input logic [DATA_WIDTH-1:0] data_in [NUM_THREADS-1:0], // from main mem
    input logic [ADDR_WIDTH-1:0] address_in [NUM_THREADS-1:0], 

    output logic [DATA_WIDTH-1:0] data_out [NUM_THREADS-1:0], // to L1 cache
    output logic [ADDR_WIDTH-1:0] address_out [NUM_THREADS-1:0]
    );

    logic [$clog2(DEPTH):0] wptr;
    logic [$clog2(DEPTH):0] rptr;

    typedef struct{
        logic [ADDR_WIDTH-1:0] address [NUM_THREADS-1:0];
        logic [DATA_WIDTH-1:0] data [NUM_THREADS-1:0];
    } mem_buf_fifo_t;

    mem_buf_fifo_t mem_buffer [DEPTH-1:0];

    logic empty, full;

    // add a check for if read and write en, then being full or empty is fine
    always@(posedge clk) begin
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
        end
        else begin
            if(write_en & !full) begin
                for(int i = 0; i < NUM_THREADS; i = i+1) begin
                    mem_buffer[wptr].address[i] <= address_in[i];
                    mem_buffer[wptr].data[i] <= data_in[i];
                end

                wptr <= wptr + 1;
            end
            if(read_en & !empty) begin
                rptr <= rptr + 1;
            end
        end
    end

    always_comb begin
        for(int i = 0; i < NUM_THREADS; i = i+1) begin
            address_out[i] <= mem_buffer[rptr].address[i];
            data_out[i] <= mem_buffer[rptr].data[i];
        end
    end

    assign full = (wptr + 1) == rptr;
    assign empty = rptr == wptr;

endmodule
