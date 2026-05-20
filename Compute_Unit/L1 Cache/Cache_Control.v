// simple DM cache control

`timescale 1ns / 1ps

module Cache_Control#(parameter BLOCK_SIZE = 8)(
    input clk, reset,
    output reg refill_accepted,
    output reg cache_req_latch,

    // LSU connect
    input instr_type, // from the instruction, indicating whether the current instruction is a store '1' or a load '0'
    input cache_req, // from control, indicating whether there is a memory request from the instruction
    input [BLOCK_SIZE-1:0] active_threads, 
    output reg ready, 
    output reg cache_req_accepted,
    output reg cache_req_rejected,

    // IHB connect
    input ihb_instr_ready,
    input ihb_full,
    output reg ihb_instr_accepted,
    output reg ihb_update_en,

    // Cache data connect
    input locked,
    input [BLOCK_SIZE-1:0] hit, dirty,
    output reg write_en,

    output reg wb_seq_active,
    output reg alloc_seq_active,

    // Arbiter connect
    input seq_over,
    output reg seq_active,
    output reg wb_init_mask_valid,
    output reg alloc_init_mask_valid,

    // memory connect
    input mem_read_ready, 
    output reg mem_read_req, mem_write_req,
    output reg refill_active
    );

    reg [2:0] state, next;
    wire warp_miss, warp_dirty;

    localparam IDLE = 3'b000;
    localparam LOCK_CHECK = 3'b001;
    localparam COMPARE = 3'b010;
    localparam IHB_ALLOC = 3'b011;
    localparam MISS_WRITE_BACK = 3'b100; // sequentially push dirty lines to mem
    localparam MISS_ALLOC = 3'b101; // sequentially lock cache lines/allocate to cbw
    localparam REFILL_SRAM = 3'b110; // returning data -> SRAM
    localparam SEQ_ACCESS = 3'b111; // sequential hit processing

    assign warp_miss = |(active_threads & ~hit);
    assign warp_dirty = |(active_threads & dirty & ~hit);

    always@(posedge clk) begin
        if(reset) begin
            state <= IDLE;
        end
        else begin
            state <= next;
        end
    end

    always @(*) begin
        next = state;
        ready = 1'b0;
        cache_req_latch = 1'b0;
        cache_req_accepted = 1'b0;
        ihb_instr_accepted = 1'b0;
        ihb_update_en = 1'b0;
        write_en = 1'b0;
        lock_idx_en = 1'b0;
        seq_active = 1'b0;
        wb_init_mask_valid = 1'b0;
        alloc_init_mask_valid = 1'b0;
        cbw_alloc = 1'b0;
        mem_read_req = 1'b0;
        mem_write_req = 1'b0;
        refill_active = 1'b0;

        case (state) 
            IDLE: begin
                ready = 1'b1;
                // Give priority to new instruction as to avoid stalling processor
                // and data coming back can be easily buffered, but if buffer full then
                // we must stall the whole compute unit
                if(cache_req) begin // valid gpu request
                    cache_req_latch = 1'b1;
                    next = LOCK_CHECK;
                end
                else if(mem_read_ready) begin  // mem controller back w data
                    refill_accepted = 1'b1;
                    next = REFILL_SRAM;
                end
                else if(ihb_instr_ready) begin
                    ihb_instr_accepted = 1'b1;
                    next = COMPARE;
                end
            end

            LOCK_CHECK: begin
                if(locked) begin
                    cache_req_rejected = 1'b1; // to notify the load store queue to continue holding the current instruction because it can't be accepted
                    next = IDLE;
                end
                else begin
                    cache_req_accepted = 1'b1;
                    next = COMPARE;
                end
            end

            COMPARE: begin
                if(!warp_miss) begin
                    next = SEQ_ACCESS;
                end
                else begin
                    next = IHB_ALLOC; 
                end 
            end

            IHB_ALLOC: begin // place instruction with data/metadata in buffers for when memory allows instructions to complete
                // if the warp that is instr_typed in this cycle is dirty, then we go to wb, if not then to miss_alloc
                ihb_update_en = 1;

                if(warp_dirty) begin
                    next = MISS_WRITE_BACK;
                    wb_init_mask_valid = 1'b1;
                end
                else begin
                    next = MISS_ALLOC;
                    alloc_init_mask_valid = 1'b1;
                end
            end

            MISS_WRITE_BACK: begin // write back all dirty cache lines to memory
                wb_seq_active = 1'b1;
                mem_write_req = 1'b1;
                if(seq_over) begin
                    alloc_init_mask_valid = 1'b1;
                    next = MISS_ALLOC;
                end
            end

            MISS_ALLOC: begin // request all needed cache lines from memory
                alloc_seq_active = 1'b1;
                mem_read_req = 1'b1;
                if(alloc_seq_over) begin
                    next = IDLE;
                end
            end

            REFILL_SRAM: begin
                refill_active = 1;
                write_en = 1;
                next = IDLE;
            end

            SEQ_ACCESS: begin
                seq_active = 1;
                write_en = instr_type;
                if(seq_over) begin
                    next = IDLE;
                end
            end

            default: next = IDLE;
        endcase
    end
endmodule