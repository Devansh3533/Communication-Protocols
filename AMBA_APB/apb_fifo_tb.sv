`timescale 1ns / 1ps

module apb_fifo_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // Clock period in ns

    // Signals
    reg clk = 0;            // Clock signal
    reg rst = 1;            // Reset signal (active high)
    reg pclk = 0;           // APB clock signal
    reg presetn = 1;        // APB reset signal (active low)
    reg psel = 1;           // APB select signal
    reg [1:0] paddr = 2'b00;  // APB address signal
    reg [31:0] pwdata = 0;  // APB write data signal
    reg penable = 0;        // APB enable signal
    reg pwrite = 0;         // APB write enable signal
    wire [31:0] prdata;     // APB read data signal
    wire pready;            // APB read data ready signal

    // Instantiate APB FIFO
    apb_fifo dut (
        .clk(clk),
        .rst(rst),
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel),
        .paddr(paddr),
        .pwdata(pwdata),
        .penable(penable),
        .pwrite(pwrite),
        .prdata(prdata),
        .pready(pready)
    );

    // Clock generation
    always #((CLK_PERIOD)/2) clk = ~clk;
    always #((CLK_PERIOD)/2) pclk = ~pclk;
    // Initial stimulus
    initial begin
        // Reset
        rst = 0;
        #10;
        rst = 1;
        #10;

        // APB write operation test
        for(int i = 0 ; i < 15; i++)
        begin
            psel = 1;
            penable = 0;
            pwrite = 1;
            pwdata = $urandom_range(0,255);
            paddr = $urandom_range(0,15);
            @(posedge clk);
            penable = 1;
            @(posedge clk);
            @(posedge pready);
            @(posedge clk);
        end
        
        for(int i = 0 ; i < 15; i++)
        begin
        psel = 1;
        penable = 0;
        pwrite  = 0;
        pwdata  = 0;
        paddr   =  $urandom_range(0,15);
        @(posedge clk);
        penable = 1;
        @(posedge clk);
        @(posedge pready);
        @(posedge clk);
        end
        
        $stop;
       
    end

endmodule
