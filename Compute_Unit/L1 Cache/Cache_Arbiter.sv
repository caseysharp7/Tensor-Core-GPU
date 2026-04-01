// L1 cache Arbiter/Coalescer

module Cache_Arbiter#(parameter BLOCK_SIZE = 8, IDX_SIZE = 4)(
    input logic clk, reset,
    input logic seq_active,
    input logic [BLOCK_SIZE-1:0] active_threads,
    input logic [IDX_SIZE-1:0] idx [BLOCK_SIZE-1:0],


    output logic [BLOCK_SIZE-1:0] threads_en,
    output logic seq_over
    );

    logic [BLOCK_SIZE-1:0] threads_mask;
    logic [BLOCK_SIZE-1:0] remaining_threads;
    logic [$clog2(BLOCK_SIZE)-1:0] selected_thread;

    assign remaining_threads = active_threads & ~threads_mask;
    
    logic [7:0] first_bit_one_hot;

    // This isolates the first available thread into a "one-hot" signal
    // e.g., 8'b10110000 becomes 8'b00010000
    assign first_bit_one_hot = remaining_threads & (~remaining_threads + 1);

    // Now, we just encode that one-hot bit into a 3-bit binary number
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
        else begin
            threads_mask <= threads_mask | threads_en;
        end
    end
endmodule