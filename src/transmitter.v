module transmitter(tx_en, data, clk, rst, arst_n, done, busy, tx);

// inputs and outputs
input tx_en, rst, arst_n, clk;
input [7:0] data;

output reg done, busy, tx;

reg bit_select;
reg [13:0] counter;
reg [9:0] shift_reg;
reg [3:0] bit_counter;

// Baud counter 
always @(posedge clk or negedge arst_n) begin

    if (!arst_n) begin
        counter  <= 14'd0;
        bit_select <= 1'b0;
    end 

    else if (rst) begin
        counter  <= 14'd0;
        bit_select <= 1'b0;
    end 

    else begin
        
        if (counter == 14'd10416) begin  
            counter  <= 14'd0;
            bit_select <= 1'b1;
        end 
        
        else begin
            counter <= counter + 14'd1;
            bit_select <= 1'b0;
        end
    end
end



// bit counter and shift register
always @(posedge clk or negedge arst_n) begin 

    if (~arst_n) begin
        bit_counter <= 0;
        shift_reg   <= 0;
        busy        <= 0;
        done        <= 0;
    end

    else if (rst) begin
        bit_counter <= 0;
        shift_reg   <= 0; 
        busy        <= 0;
        done        <= 0;
    end

    else begin 

        if (tx_en && ~done) begin // load new data when tx_en asserted 
            
            bit_counter <= 0;
            shift_reg   <= {1'b1, data , 1'b0};
            busy        <= 1;
        end 

        else if (busy && bit_select) begin 
            if (bit_counter == 4'd9) begin 
                bit_counter <= 0;
                busy <= 0;
                done <= 1; // one pulse when finished
            end 

            else begin
                bit_counter <= bit_counter + 1;
                shift_reg <= shift_reg >> 1;   

            end
        end
    end
end

// tx
always @(posedge clk or negedge arst_n) begin 
    if (~arst_n)
        tx <= 1;

    else if (rst) 
        tx <= 1;

    
    else begin 

        if (busy)
            case (bit_counter[3:0])
                4'd0 : tx <= 0; // start bit

                4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8 :  tx <= shift_reg [0];
                    

                4'd9 : tx <= 1; // stop bit
                    
                default : tx <= 1; // idle 
            endcase
    end
end

endmodule 
