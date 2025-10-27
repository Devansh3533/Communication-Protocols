`timescale 1ns / 1ps

module apb_top_tb;
    // Define testbench ports
    reg clk = 0;
    reg rstn;
    reg wr;
    reg newd;
    reg [3:0] ain;
    reg [7:0] din;
    wire [7:0] dout;
    integer i = 0;
always #10 clk = ~clk;
    // Instantiate the top module
    abp_top dut (
        .clk(clk),
        .rstn(rstn),
        .wr(wr),
        .newd(newd),
        .ain(ain),
        .din(din),
        .dout(dout)
    );

    initial
    begin
    rstn = 0;
    repeat(5) @(posedge clk);
    rstn = 1;
    newd = 1;
    for(i = 0; i < 10; i=i+1)
    begin
    ain = $urandom;
    din = $urandom;
    wr = 1;
    @(posedge dut.m1.pready);
    end
    
    
    for(i = 0; i < 10; i=i+1)
    begin
    ain = $urandom;
    din = 0;
    wr = 0;
    @(posedge dut.m1.pready);
    end
    
    
    end

    initial begin
    #900;
    $stop;
    end
endmodule
