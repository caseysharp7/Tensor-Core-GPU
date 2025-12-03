// Threads Mask Decoder

module Threads_Mask_Decoder(
    input [3:0] threads_mask,
    output reg [7:0] active_threads
    );
    // just use threads_mask[1] if 2 is not active
    always @(*) begin
        if(threads_mask[3]) begin
            if(threads_mask[2]) begin
                case (threads_mask[1:0])
                    2'b00: active_threads = 8'b0000_0011; // 1100
                    2'b01: active_threads = 8'b0000_1100; // 1101
                    2'b10: active_threads = 8'b0011_0000; // 1110
                    2'b11: active_threads = 8'b1100_0000; // 1111
                    default: active_threads = 8'd0;
                endcase
            end
            else begin
                if (threads_mask[1])
                    active_threads = 8'b1111_0000; // 101x
                else
                    active_threads = 8'b0000_1111; // 100x
            end
        end
        else begin
            active_threads = 8'b1111_1111; // 0xxx
        end
    end

endmodule