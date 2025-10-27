`timescale 1ns / 1ps

module baud_rate_generator
// baud rate = 9600
#(parameter  N = 10,  //// number of counter bits
             M = 651) /// counter limit value
(
 input clk,
 input reset,
 output tick
    );

/// Counter Register
reg [N-1:0] counter;
wire [N-1:0] next;

/// Register Logic
always @(posedge clk, negedge reset)
begin
if(~reset)
    counter <= 0;
else
    counter <= next;
end  

/// Next counter value logic
assign next = (counter == (M-1)) ? 0 : counter + 1;

/// Output Logic
assign tick = (counter == (M-1)) ? 1'b1:1'b0;
endmodule
