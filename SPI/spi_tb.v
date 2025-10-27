`timescale 1ns / 1ps

module spi_tb;

// Inputs
reg clk;
reg reset;
reg [15:0] data_in;

//outputs
wire spi_cs_l;
wire spi_sclk;
wire spi_data;
wire [4:0] counter;

SPI dut(
.clk(clk),
.reset(reset),
.counter(counter),
.data_in(data_in),
.spi_cs_l(spi_cs_l),
.spi_sclk(spi_sclk),
.spi_data(spi_data)
);

initial begin
clk = 0;
reset = 1;
data_in = 0;
end

always #5 clk = ~clk;

initial begin
#10 reset = 1'b0;
#10 data_in = 16'hA569;
#335 data_in = 16'h2563;
#335 data_in = 16'h9B63;
#335 data_in = 16'h9A61;

#335 data_in = 16'hAB25;
#335 data_in = 16'h9274;
end
endmodule
