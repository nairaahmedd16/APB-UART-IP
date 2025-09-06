`timescale 1ns/100ps

module APB_tb();

// stimuls and response 
reg PCLK;           // APB clock
reg PRESETn;        // active low reset 
reg [31:0] PADDR;         // address bus
reg PSEL;            //peripheral select
reg PENABLE;         // asserted in the ACCESS state from the master to enable R/W operations
reg PWRITE;         // 1 = write cycle , 0 = read cycle 
reg [31:0] PWDATA;     // write data bus

wire  [31:0] PRDATA;     // read data bus
wire  PREADY;            // 1 = transfer complete

// Instantiation DUT
APB DUT (.PCLK(PCLK), .PRESETn(PRESETn), .PADDR(PADDR), .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE), .PWDATA(PWDATA), .PRDATA(PRDATA), .PREADY(PREADY));

// PCLK generation
initial begin 
    PCLK = 0;
    forever 
        #5 PCLK = ~PCLK; // 100 MHZ ..... 10 ns.... toggle each 5 ns
end

// start from known state >>> force >>> wait >>> chech 
initial begin 
    // reset 
    PRESETn = 0;
    PSEL = 0;
    PENABLE = 0;
    PADDR = 32'd0;
    PWRITE = 0;
    PWDATA = 0;
    repeat(2) @(negedge PCLK);
    PRESETn = 1; 

   // 1- tx_rst & rx_rst ......... write in CTRL_REG
   // write in CTRL_REG[1,2]

    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd0;
    PWDATA = 32'd6; // [1] rx_rst .... [2] tx_rst
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK);

    // turn off the rst
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd0;
    PWDATA = 32'd0; // [1] rx_rst .... [2] tx_rst
    repeat(2) @(negedge PCLK);
    PENABLE = 1;  

    wait(PREADY);
    @(posedge PCLK);


    // 2- write in TX_DATA
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd2;
    PWDATA = 32'd93; // 8 bits data
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK);

    // 3- tx_en , rx_en in CTRL_REG
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd0;
    PWDATA = 32'd9; // [0] rx_en .... [3] tx_en
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK);  


    // 4- tx_en = 0 , rx_en = 1 in CTRL_REG
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd0;
    PWDATA = 32'd1; // [0] rx_en .... [3] tx_en
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK); 

    // 5- read tx_done & tx busy & rx_done & rx busy & rx_error 
    // read from STATS_REG
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 0;
    PADDR = 32'd1;
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK);

    repeat(2) @(negedge PCLK);
    $display("Checking the states of the UART from PRDATA");
    $display("tx_busy = %0b, tx_done = %0b", PRDATA[0], PRDATA[1]);
    $display("rx_busy = %0b, rx_done = %0b, rx_error = %0b", PRDATA[2], PRDATA[3], PRDATA[4]);

    PENABLE = 0;

    repeat(11*10417) @(negedge PCLK);


    // 6- reading RX 
    // read from RX_DATA
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 0;
    PADDR = 32'd3;
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK);

    repeat(2) @(negedge PCLK);
    PENABLE = 0;

    $display("RX is = %0d", PRDATA[7:0]);

    // 7- read tx_done & tx busy & rx_done & rx busy & rx_error 
    // read from STATS_REG

    PSEL = 1;
    PWRITE = 0;
    PADDR = 32'd1;
    repeat(2) @(negedge PCLK);
    PENABLE = 1;

    wait(PREADY);
    @(posedge PCLK);

    $display("Checking the states of the UART from PRDATA");
    $display("tx_busy = %0b, tx_done = %0b", PRDATA[0], PRDATA[1]);
    $display("rx_busy = %0b, rx_done = %0b, rx_error = %0b", PRDATA[2], PRDATA[3], PRDATA[4]);




    $stop;
end

endmodule
