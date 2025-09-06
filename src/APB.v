module APB(
    PCLK, PRESETn, PADDR, PSEL, PENABLE, PWRITE, PWDATA, PRDATA, PREADY
);

// states as parameters + encoding
parameter IDLE  = 2'b00;
parameter WRITE = 2'b01;
parameter READ  = 2'b10;

// inputs and outputs
input  PCLK;              // APB clock
input  PRESETn;           // active low reset 
input  [31:0] PADDR;      // address bus
input  PSEL;              // peripheral select
input  PENABLE;           // asserted in the ACCESS state from the master to enable R/W operations
input  PWRITE;            // 1 = write cycle , 0 = read cycle 
input  [31:0] PWDATA;     // write data bus

output reg [31:0] PRDATA; // read data bus
output reg PREADY;        // 1 = transfer complete

// internal signals 
reg [1:0] cs, ns;
wire tx;

// registers
reg [31:0] CTRL_REG ;   // tx_en , tx_rst , rx_rst , rx_enable
wire [31:0] STATS_REG;   // rx_busy, tx_busy, rx_done, tx_done, rx_error
reg [31:0] TX_DATA;     // write....send data to transmitter
wire [31:0] RX_DATA;     // read......read from the receiver 

// wires for outputs 
wire rx_busy, rx_done, rx_err;
wire tx_busy, tx_done;
wire [7:0] rx_data;

// Instantiation
transmitter TX(
   .clk(PCLK),
   .arst_n(PRESETn),
   .rst(CTRL_REG[2]),
   .tx_en(CTRL_REG[3]),
   .busy(tx_busy),
   .done(tx_done),
   .data(TX_DATA[7:0]),
   .tx(tx)
);

receiver RX(
   .clk(PCLK),
   .arst_n(PRESETn),
   .rx_en(CTRL_REG[0]), 
   .rst(CTRL_REG[1]),
   .busy(rx_busy),
   .done(rx_done),
   .err(rx_err),
   .data(rx_data),
   .RX(tx)
);



// Update STATS_REG and RX_DATA from these wires
assign STATS_REG[31:5] = 'b0;
assign STATS_REG[0] = tx_busy;
assign STATS_REG[1] = tx_done;
assign STATS_REG[2] = rx_busy;
assign STATS_REG[3] = rx_done;
assign STATS_REG[4] = rx_err;
assign RX_DATA [31:8] = 'b0;
assign RX_DATA[7:0] = rx_data;
 
// state memory (seq)
always @(posedge PCLK or negedge PRESETn) begin 
    if (~PRESETn)
        cs <= IDLE;
    else  
        cs <= ns;
end

// next state (comb)
always @(*) begin 
    ns = cs;
    PREADY = 0;
    
    case (cs)
        IDLE: begin
            PREADY = 0;
            if (PENABLE && PSEL && PWRITE) 
                ns = WRITE;
    
            else if (PENABLE && PSEL && !PWRITE)
                ns = READ;
        end
        WRITE: begin
            ns = IDLE;
            PREADY = 1;
        end
        READ : begin
            ns = IDLE;
            PREADY = 1;
        end
        default : ns = IDLE;
    endcase
end

// sequential logic for registers
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        CTRL_REG <= 0;
        TX_DATA  <= 0;
        PRDATA   <= 0;
       
    end else begin
        case (cs)
            WRITE: begin
                case (PADDR)
                    32'd0: CTRL_REG <= PWDATA;
                    32'd2: TX_DATA  <= PWDATA;
                endcase
               
            end
            READ: begin
                case (PADDR)
                    32'd0: PRDATA <= CTRL_REG;
                    32'd1: PRDATA <= STATS_REG;
                    32'd2: PRDATA <= TX_DATA;
                    32'd3: PRDATA <= RX_DATA;
                endcase
               
            end
        
        endcase
    end
end

endmodule
