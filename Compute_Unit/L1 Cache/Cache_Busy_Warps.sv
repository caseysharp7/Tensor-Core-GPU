// Cache Busy Warps Registers
// If a warp has a memory access that misses, it will then send a request to main
// memory. In order for this to not stall the cache for the duration of the main
// memory access, we will hold important information about the request in Registers
// here, which will then allow the cache to resolve the warp memory access once
// the memory is ready

`timescale 1ns / 1ps


// need to modify so that the write back and allocate occurs for every thread that misses
module Cache_Busy_Warps#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16, BLOCK_SIZE = 8)(
    input logic clk, reset,
    input logic cbw_update_en, // enable signal to update the busy warp registers
    input logic [ADDR_WIDTH-1:0] address_in,
    input logic [DATA_WIDTH-1:0] data_in [BLOCK_SIZE-1:0],
    input logic [1:0] warp_num_in,
    input logic instr_type_in, // load or store 0 for load, 1 for store
    input logic [7:0] threads_in // which threads accessed main memory


    );

    logic [1:0] current_warp_num;

    typedef struct{
        logic valid;
        logic [ADDR_WIDTH-1:0] address;
        logic [DATA_WIDTH-1:0] data [BLOCK_SIZE-1:0];
        logic [1:0] warp_num;
        logic instr_type;
        logic [7:0] threads;
    } cache_busy_warp_t;

    cache_busy_warp_t busy_array [3:0];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 4; i++) begin
                busy_array[i].valid <= 0;
                busy_array[i].address <= 0;
                for (int j = 0; j < BLOCK_SIZE; j++) begin
                    busy_array[i].data[j] <= 0;
                end
                busy_array[i].warp_num <= 0;
                busy_array[i].instr_type <= 0;
                busy_array[i].threads <= 0;
            end
        end
        else if(cbw_update_en) begin
            busy_array[warp_num].valid <= 1;
            busy_array[warp_num].address <= address_in;
            for (int j = 0; j < BLOCK_SIZE; j++) begin
                busy_array[warp_num].data[j] <= data_in[j];
            end
            busy_array[warp_num].warp_num <= warp_num_in;
            busy_array[warp_num].instr_type <= instr_type_in;
            busy_array[warp_num].threads <= threads_in;
        end
        else begin end
    end

    // small FSM for each warp
    localparam IDLE = 3'b00;
    localparam ALLOCATE = 3'b01;
    localparam WRITE_BACK = 3'b10;

    logic [1:0] warp_state [3:0];
    logic [1:0] next_warp_state [3:0];

    always_ff @(posedge clk) begin
        for (int i = 0; i < 4; i++) begin
            if (reset) begin
                warp_state[i] <= IDLE;
            end
            else begin
                warp_state[i] <= next_warp_state[i];
            end
        end
    end

    always_comb begin
        for(int i = 0; i < 4; i++) begin
            if(address_in == busy_array[i].address) begin
                current_warp_num = i;
            end
        end
        case(warp_state)
            IDLE: begin
                if(mem_read_req) begin
                    next_warp_state[current_warp_num] = ALLOCATE;
                end
                else if(mem_write_req) begin
                    next_warp_state[current_warp_num] = WRITE_BACK;
                end
                else begin
                    next_warp_state = warp_state;
                end
            end

            ALLOCATE: begin
                if(read_mem_ready) begin
                    next_warp_state[current_warp_num] = IDLE;
                end
                else begin
                    next_warp_state[current_warp_num] = ALLOCATE;
                end
            end

            WRITE_BACK: begin
                if(write_mem_ready) begin
                    mem_read_req = 1;
                    next_warp_state[current_warp_num] = ALLOCATE;
                end
                else begin
                    next_warp_state[current_warp_num] = WRITE_BACK;
                end
            end

            default: next_warp_state = IDLE;
        endcase
    end

    always_comb begin
        if(read_mem_ready) begin
            data_out = busy_array[current_warp_num].data;
            address_out = busy_array[current_warp_num].address;
        end
    end

endmodule