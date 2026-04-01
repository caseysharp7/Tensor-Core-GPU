// simple DM cache control

`timescale 1ns / 1ps

module Cache_Control#(parameter BLOCK_SIZE = 8)(
    input clk, reset,
    input [BLOCK_SIZE-1:0] valid, hit, dirty, active_threads,
    input seq_over,
    input read_mem_ready, write_mem_ready,
    input store, // from the instruction, indicating whether the current instruction is a store or a load
    input cache_req, // from instruction, indicating whether there is a memory request from the instruction

    output ready,
    output write_en,
    output sram_read_en,
    output seq_active,
    output mem_read_req,
    output mem_write_req,
    output [BLOCK_SIZE-1:0] mem_read_threads_en, mem_write_threads_en,
    output cbw_write_en
    );

    reg [2:0] state, next, prev;
    wire warp_hit, warp_dirty, warp_valid;

    localparam IDLE = 3'b00;
    localparam COMPARE = 3'b01;
    localparam SEQ_ACCESS = 3'b10;

    assign warp_hit = &hit;
    assign warp_dirty = |dirty;
    assign warp_valid = &valid;

    always@(posedge clk) begin
        if(reset) begin
            state <= IDLE;
        end
        else begin
            state <= next;
        end
    end

    always @(*) begin
        case (state) 
            IDLE: begin
                if(cache_req) begin // valid gpu request
                    next = COMPARE;
                end
                else if(read_mem_ready) begin
                    next = SEQ_ACCESS;
                end
            end

            COMPARE: begin
                if(hit_inter & valid_inter) begin
                    next = SEQ_ACCESS;
                end
                else begin
                    next = IDLE;
                end
            end

            SEQ_ACCESS: begin
                if(seq_over) begin
                    next = IDLE;
                end
                else begin
                    next = SEQ_ACCESS;
                end
            end

            default: next = IDLE;
        endcase
    end

    always@(*) begin
        ready = 0; 
        write_en = 0;
        read_en = 0;
        seq_active = 0;
        mem_read_req = 0;
        mem_write_req = 0;
        mem_read_threads_en = 0;
        mem_write_threads_en = 0;
        cbw_write_en = 0;
        
        case(state)
            IDLE: ready = 1;
            COMPARE: begin
                if(hit_inter & valid_inter) begin end
                else if(dirty_inter) begin
                    mem_write_req = 1;
                    mem_write_threads_en = dirty & ~hit;
                    cbw_write_en = 1;
                end
                else begin
                    mem_read_req = 1;
                    mem_read_threads_en = ~hit;
                    cbw_write_en = 1;
                end
            end
            SEQ_ACCESS: begin
                seq_active = 1;
                if(store) begin
                    write_en = 1;
                end
                read_en = 1;
            end
        endcase
    end
endmodule