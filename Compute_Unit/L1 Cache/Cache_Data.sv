// Cache Data

'timescale 1ns / 1ps

module Cache_Data#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16, BLOCK_SIZE = 8, NUM_BLOCKS = 16, IDX_SIZE = $clog2(NUM_BLOCKS))(
    input logic clk,
    input logic [ADDR_WIDTH-1:0] address [BLOCK_SIZE-1:0], // we need the address of each thread in the warp
    input logic [DATA_WIDTH-1:0] data_in [BLOCK_SIZE-1:0],
    input logic [BLOCK_SIZE-1:0] threads_en,
    input logic write_en,

    output logic [DATA_WIDTH-1:0] data_out [BLOCK_SIZE-1:0],
    output logic [IDX_SIZE-1:0] idx_out [BLOCK_SIZE-1:0],
    output logic [BLOCK_SIZE-1:0] valid, hit, dirty
    );

    localparam BLOCK_OFFSET = $clog2(BLOCK_SIZE);
    localparam BYTE_OFFSET = $clog2(DATA_WIDTH/8);
    localparam TAG_SIZE = ADDR_WIDTH - (IDX_SIZE + BLOCK_OFFSET + BYTE_OFFSET);
    localparam BLOCK_BITS = 2 + TAG_SIZE + DATA_WIDTH*BLOCK_SIZE; // +2 for valid and dirty

    logic [TAG_SIZE-1:0] tag [BLOCK_SIZE-1:0];
    logic [IDX_SIZE-1:0] idx [BLOCK_SIZE-1:0];
    logic [BLOCK_OFFSET-1:0] block_offset [BLOCK_SIZE-1:0];

    logic [DATA_WIDTH-1:0] cache_data [NUM_BLOCKS-1:0][BLOCK_SIZE-1:0];
    logic [TAG_SIZE-1:0] cache_tags [NUM_BLOCKS-1:0];
    logic [NUM_BLOCKS-1:0] cache_valid;
    logic [NUM_BLOCKS-1:0] cache_dirty;

    always_comb begin
        for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
            tag[i] = address[i][ADDR_WIDTH-1 -: TAG_SIZE];
            idx[i] = address[i][ADDR_WIDTH-TAG_SIZE-1 -: IDX_SIZE];
            block_offset[i] = address[i][BLOCK_OFFSET + BYTE_OFFSET - 1 -: BLOCK_OFFSET];

            hit[i] = (cache_valid[idx[i]] && cache_tags[idx[i]] == tag[i]) ? 1 : 0;
            valid[i] = cache_valid[idx[i]];
            dirty[i] = cache_dirty[idx[i]];
        end
    end

    assign idx_out = idx;

    // SRAM
    always_ff@(posedge clk) begin
        if(seq_active) begin
            if(write_en) begin
                for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
                    if(threads_en[i]) begin // this is wrong for now because we only want to update one or multiple words depending on how many threads hit to this specific cache line, not the whole cache line
                        cache_data[idx[i]][block_offset[i]] <= data_in[i];
                        cache_tags[idx[i]] <= tag[i];
                        cache_valid[idx[i]] <= 1'b1;
                        cache_dirty[idx[i]] <= 1'b1;
                    end
                end
            end
            else begin
                for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
                    if(threads_en[i]) begin
                        data_out[i] <= cache_data[idx[i]][block_offset[i]];
                    end
                end
            end
        end

        else if(read_mem_ready) begin
            for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
                if(threads_en[i]) begin
                    cache_data[idx[i]][block_offset[i]] <= data_in[i];
                    cache_tags[idx[i]] <= tag[i];
                    cache_valid[idx[i]] <= 1'b1;
                    cache_dirty[idx[i]] <= 1'b0;
                end
            end
        end
        else begin
            data_out <= data_in;
        end
    end

endmodule