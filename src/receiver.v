module receiver(RX, rx_en, clk, rst, arst_n, done, err, data, busy);

// states as parameter + encoding 
parameter IDLE  = 3'b000;
parameter START = 3'b001;
parameter DATA  = 3'b010;
parameter ERR   = 3'b011;
parameter DONE  = 3'b100;

// baud divisor (for 9600 baud, clk=100 MHz)
parameter DIVISOR = 10416; 

// inputs and outputs
input RX, rx_en, clk, rst, arst_n;

output reg done, busy, err;
output reg [7:0] data;

reg Edge_detec;
reg RX_prev;
reg [13:0] counter ; // count for the tick
reg baud_tick;
reg [3:0] bit_counter; // count the data

// FSM
reg [2:0] cs, ns;
reg [14:0] start_count; // to count 0.5 bit time

// state memory (seq)
always @(posedge clk or negedge arst_n) begin 
    if(~arst_n) 
        cs <= IDLE;
    else if(rst)
        cs <= IDLE;
    else  
        cs <= ns;
end

// counter to count 0.5 bit time
always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
        start_count <= 0;
    end 
    else if (rst) begin
        start_count <= 0;
    end 
    else if (cs == IDLE && ns == START) begin
    start_count <= (DIVISOR >> 1);  
    end

    else if (cs == START && start_count > 0) begin
        start_count <= start_count - 1; // count down
    end 
end

// Next state (comb) 
always @(*) begin
    case (cs)
        IDLE : begin
            if (rst) ns = IDLE;
            else if(Edge_detec && rx_en) ns = START;
            else ns = IDLE;
        end

        START : if(start_count == 0) ns = DATA;
                else ns = START;

        DATA : if (bit_counter == 4'd8 && baud_tick) begin
                   if (RX == 1) ns = DONE;   // stop bit OK
                   else ns = ERR;            // stop bit error
               end 
               else ns = DATA;

        DONE  : ns = IDLE;
        ERR   : ns = IDLE;
        default : ns = IDLE;
    endcase
end

// Edge detector
always @(posedge clk or negedge arst_n) begin 
    if (~arst_n) begin
        Edge_detec <= 0;
        RX_prev <= 1;   // RX idle
    end
    else if(rst) begin 
        Edge_detec <= 0;
        RX_prev <= 1; 
    end
    else begin 
        RX_prev <= RX;
        Edge_detec <= (RX_prev == 1 && RX ==0); // falling edge (start bit)
    end
end

// Baud counter
always @(posedge clk or negedge arst_n) begin 
    if(~arst_n) begin
        counter <= 14'b0;
        baud_tick <= 0;
    end
    else if (rst) begin
        counter <= 14'b0;
        baud_tick <= 0;
    end
    else if(cs == DATA) begin 
        if (counter == 0) begin
            counter <= DIVISOR - 1; // reload
            baud_tick <= 1; // pulse
        end
        else begin 
            counter <= counter - 1;
            baud_tick <= 0;
        end
    end
    else begin 
        counter <= DIVISOR -1; // reset counter
        baud_tick <= 0;
    end 
end

// SIPO shift register (LSB first)
always @(posedge clk or negedge arst_n) begin 
    if(~arst_n) begin
        bit_counter <= 4'b0;
        data <= 8'b0;
    end
    else if(rst) begin
        bit_counter <= 4'b0;
        data <= 8'b0;
    end
    else if(cs == DATA && baud_tick) begin

        if (bit_counter < 4'd8) begin  
             data <= {RX, data[7:1]};
             bit_counter <= bit_counter + 1;
        end

    end
    else if (cs == IDLE) begin
        bit_counter <= 0;
    end
end

// outputs 
always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
        busy <= 0;
        done <= 0;
        err  <= 0;
    end 
    
    else if (rst) begin
        busy <= 0;
        done <= 0;
        err  <= 0;

    end 
    else if(cs == IDLE) begin
        busy <= 0;
    end
    else begin
        busy <= (cs == START || cs == DATA);
        done <= (cs == DONE);
        err  <= (cs == ERR);
    end
end

endmodule
