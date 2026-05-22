// Cache Data

'timescale 1ns / 1ps

module Cache_Data#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16, BLOCK_SIZE = 8, NUM_BLOCKS = 16, IDX_SIZE = $clog2(NUM_BLOCKS), BLOCK_OFFSET_WIDTH = $clog2(BLOCK_SIZE))(
    input logic clk, reset,

    input logic [ADDR_WIDTH-1:0] addr_in [BLOCK_SIZE-1:0], // we need the address of each thread in the warp
    input logic [DATA_WIDTH-1:0] data_in [BLOCK_SIZE-1:0],

    input logic [BLOCK_SIZE-1:0] threads_en,
    input logic [BLOCK_SIZE-1:0] active_threads,
    input logic write_en,
    input logic refill_active,

    input logic wb_seq_active,
    input logic cache_line, // selected cache line for a write back
    input logic alloc_seq_active,


    output logic [DATA_WIDTH-1:0] data_out [BLOCK_SIZE-1:0],
    output logic [IDX_SIZE-1:0] idx_out [BLOCK_SIZE-1:0],
    output logic [BLOCK_SIZE-1:0] hit, dirty,

    output logic locked,

    output logic [NUM_THREADS-1:0] wb_init_mask,
    output logic [NUM_THREADS-1:0] alloc_init_mask,
    output logic [NUM_THREADS-1:0] ihb_init_mask
    );

    localparam BYTE_OFFSET_WIDTH = $clog2(DATA_WIDTH/8);
    localparam TAG_WIDTH = ADDR_WIDTH - (IDX_SIZE + BLOCK_OFFSET_WIDTH + BYTE_OFFSET_WIDTH);

    logic [TAG_WIDTH-1:0] tag_in [BLOCK_SIZE-1:0];
    logic [IDX_SIZE-1:0] idx_in [BLOCK_SIZE-1:0];
    logic [BLOCK_OFFSET_WIDTH-1:0] block_offset [BLOCK_SIZE-1:0];

    logic [IDX_SIZE-1:0] refill_idx;
    assign refill_idx = addr_in[0][ADDR_WIDTH-TAG_WIDTH-1 -: IDX_SIZE]; 


    logic [DATA_WIDTH-1:0] cache_data [NUM_BLOCKS-1:0][BLOCK_SIZE-1:0]; // SRAM

    // Registers:
    logic [TAG_WIDTH-1:0] cache_tags [NUM_BLOCKS-1:0]; 
    logic [NUM_BLOCKS-1:0] cache_valid;
    logic [NUM_BLOCKS-1:0] cache_dirty;
    logic [NUM_BLOCKS-1:0] lock_bits;

    always_comb begin
        for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
            tag_in[i] = addr_in[i][ADDR_WIDTH-1 -: TAG_WIDTH];
            idx_in[i] = addr_in[i][ADDR_WIDTH-TAG_WIDTH-1 -: IDX_SIZE];
            block_offset[i] = addr_in[i][BLOCK_OFFSET_WIDTH + BYTE_OFFSET_WIDTH - 1 -: BLOCK_OFFSET_WIDTH];

            hit[i] = (active_threads[i] && cache_valid[idx_in[i]] && (cache_tags[idx_in[i]] == tag_in[i]));
            dirty[i] = cache_valid[idx_in[i]] && cache_dirty[idx_in[i]];

            wb_init_mask[i] = hit[i] || ~dirty[i];
            alloc_init_mask[i] = hit[i];
            ihb_init_mask[i] = hit[i];

            locked = locked | lock_bits[idx_in[i]]
        end
    end

    assign idx_out = idx_in;

    // SRAM
    always_ff@(posedge clk) begin
        if(write_en) begin
            if(refill_active) begin
                cache_data[refill_idx] <= data_in;
            end
            else begin
                for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
                    if(threads_en[i]) begin 
                        cache_data[idx_in[i]][block_offset[i]] <= data_in[i];
                        cache_tags[idx_in[i]] <= tag_in[i];
                        cache_valid[idx_in[i]] <= 1'b1;
                        cache_dirty[idx_in[i]] <= 1'b1;
                    end
                end
            end
        end

        else if(wb_seq_active) begin
            data_out <= cache_data[cache_line];
            lock_bits[cache_line] <= 1'b1;
        end

        else if(alloc_seq_active) begin
            lock_bits[cache_line] <= 1'b1;
        end

        else begin
            for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
                if(threads_en[i]) begin
                    data_out[i] <= cache_data[idx_in[i]][block_offset[i]];
                end
            end
        end
    end

endmodule