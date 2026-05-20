// L1 cache Arbiter/Coalescer

module Cache_Arbiter#(parameter NUM_BLOCKS = 128, BLOCK_SIZE = 8, IDX_SIZE = $clog2(NUM_BLOCKS))(
    input logic clk, reset,
    input logic seq_active,
    input logic [NUM_THREADS-1:0] active_threads,
    input logic [IDX_SIZE-1:0] idx [BLOCK_SIZE-1:0],

    input logic wb_seq_active,
    input logic wb_init_mask_valid,
    input logic [NUM_THREADS-1:0] wb_init_mask,

    input logic alloc_seq_active,
    input logic alloc_init_mask_valid,
    input logic [NUM_THREADS-1:0] alloc_init_mask,

    input logic write_mem_valid, read_mem_valid,

    output logic [NUM_THREADS-1:0] threads_en,
    output logic [$clog2(NUM_BLOCKS)-1:0] cache_line, // which cache line is selected 
    output logic seq_over
    );

    logic [NUM_THREADS-1:0] threads_mask;
    logic [NUM_THREADS-1:0] remaining_threads;
    logic [$clog2(NUM_THREADS)-1:0] selected_thread;

    assign remaining_threads = active_threads & ~threads_mask;
    
    logic [7:0] first_bit_one_hot;

    // 8'b10110000 becomes 8'b00010000
    assign first_bit_one_hot = remaining_threads & (~remaining_threads + 1);

    // encode 1 bit into a 3 bit binary number
    always_comb begin
        selected_thread = 3'd0;
        if (first_bit_one_hot[1] || first_bit_one_hot[3] || first_bit_one_hot[5] || first_bit_one_hot[7]) begin
            selected_thread[0] = 1;
        end 
        if (first_bit_one_hot[2] || first_bit_one_hot[3] || first_bit_one_hot[6] || first_bit_one_hot[7]) begin
            selected_thread[1] = 1;
        end
        if (first_bit_one_hot[4] || first_bit_one_hot[5] || first_bit_one_hot[6] || first_bit_one_hot[7]) begin
            selected_thread[2] = 1;
        end

        cache_line = idx[selected_thread];

        if(remaining_threads == 8'd0) begin
            seq_over = 1'b1;
        end
    end

    // Coalesce threads that access the same cache line
    always_comb begin
        threads_en = 8'b0;
        for(int i = 0; i < BLOCK_SIZE; i = i+1) begin
            if(remaining_threads[i] && idx[i] == idx[selected_thread]) begin
                threads_en[i] = 1'b1;
            end
        end
    end

    always_ff@(posedge clk) begin
        if(reset || seq_over) begin
            threads_mask <= 8'b0;
        end
        else if(wb_init_mask_valid) begin
            threads_mask <= wb_init_mask;
        end
        else if(alloc_init_mask_valid) begin
            threads_mask <= alloc_init_mask;
        end
        else if(wb_seq_active)begin // only update if memory controller/bus is ready to accept next cache line
            if(write_mem_valid) begin // memory/memory controller allows us to write
                threads_mask <= threads_mask | threads_en;
            end
        end
        else if(alloc_seq_active) begin
            if(read_mem_valid) begin // memory/memory controller allows us to read
                threads_mask <= threads_mask | threads_en;
            end
        end
        else begin
            threads_mask <= threads_mask | threads_en;
        end
    end
endmodule