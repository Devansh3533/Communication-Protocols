`timescale 1ns / 1ps

module abp_s_tb;
reg pclk = 0,presetn = 1,psel = 0, penable = 0, pwrite = 1;
reg [3:0] paddr = 0;
reg  [7:0] pwdata = 0;

wire [7:0] prdata;
wire pready;

abp_s dut (pclk,presetn,paddr,psel, penable,pwdata, pwrite,prdata,pready);

always #10 pclk = ~pclk;

initial begin
pwrite = 1;
pwdata = 220;
paddr = 5;
psel = 1;
@(negedge pclk);
penable = 1;
@(posedge pclk);
pwrite = 0;
repeat(3) @(posedge pclk);
end


initial begin
#90;
$stop;
end

endmodule
