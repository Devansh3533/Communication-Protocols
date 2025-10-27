`timescale 1ns / 1ps

module abp_m_tb;
reg pclk = 0;
reg presetn;
reg [3:0] addrin;
reg [7:0] datain;
reg wr;
reg newd;
reg [7:0] prdata;
reg pready;

wire psel;
wire penable;
wire [3:0] paddr;
wire [7:0] pwdata;
wire pwrite;
wire [7:0] dataout;

abp_m d1(
.pclk(pclk),
.presetn(presetn),
.addrin(addrin),
.datain(datain),
.wr(wr),
.newd(newd),
.prdata(prdata),
.pready(pready),
.psel(psel),
.penable(penable),
.paddr(paddr),
.pwdata(pwdata),
.pwrite(pwrite),
.dataout(dataout)
);

always #10 pclk = ~pclk;

initial begin
presetn = 1'b0;
repeat(5) @(posedge pclk);
presetn = 1;
newd = 1;
addrin = 4;
datain = 255;
wr = 1;
prdata = 255;
@(posedge pclk);
pready = 1'b1;
@(posedge pclk);

newd = 1;
addrin = 4;
datain = 0;
wr = 0;
prdata = 255;
@(posedge pclk);
pready = 1'b1;
@(posedge pclk);
newd = 1'b0;
@(posedge pclk);
end
initial 
begin
#170
$finish();
end
endmodule
