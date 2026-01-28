// Pull Unit

module Pull_Unit(
    input clk, reset,
    input start_pull, // from scheduler (control) when a pull instruction is executed (this can be a global instructions bc threads don't need to do anything)
    input matmul_done, // from push unit to confirm matmul is done
    input [DATA_WIDTH-1:0] result0, result1, result2, result3, result4, result5, result6, result7, result8, result9, result10, result11, result12, result13, result14, result15, // from systolic array

    output [DATA_WIDTH-1:0] reg_write_data [7:0] // to threads reg file
    );

    reg [1:0] counter;

    always@(posedge clk or posedge reset)begin
        if(reset || (start_pull && matmul_done)) begin
            counter <= 0;
        end
        else if(counter < 2) begin
            counter <= counter + 1;
        end
    end

    always@(*) begin
        if(counter == 2'b00) begin
            reg_write_data[0] = result0;
            reg_write_data[1] = result1;
            reg_write_data[2] = result2;
            reg_write_data[3] = result3;
            reg_write_data[4] = result4;
            reg_write_data[5] = result5;
            reg_write_data[6] = result6;
            reg_write_data[7] = result7;
        end
        else if(counter == 2'b01) begin
            reg_write_data[0] = result8;
            reg_write_data[1] = result9;
            reg_write_data[2] = result10;
            reg_write_data[3] = result11;
            reg_write_data[4] = result12;
            reg_write_data[5] = result13;
            reg_write_data[6] = result14;
            reg_write_data[7] = result15;
        end

    end



endmodule