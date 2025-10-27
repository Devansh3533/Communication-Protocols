`timescale 1ns / 1ps
module Receiver_uart
#(parameter DBITS = 8,
            SB_TICK = 16)
(
input clk,
input sample_tick,
input reset,
input rx,    // input data line
output reg data_ready,
output [DBITS-1:0] data_out
    );
// State Machine States
localparam [1:0] idle = 2'b00,
                 start = 2'b01,
                 data = 2'b10,
                 stop = 2'b11;

// Registers
reg [1:0] state, next_state;
reg [3:0] tick_reg, tick_next;
reg [2:0] nbits_reg,nbits_next; // no. of bits received in data state
reg [7:0] data_reg, data_next;

// Registers Logic
always @(posedge clk, negedge reset)
begin
    if(~reset) begin
        state <= idle;
        tick_reg <= 4'd0;
        nbits_reg <= 3'd0;
        data_reg <= 8'd0;
    end
    else begin
        state <= next_state;
        tick_reg <= tick_next;
        nbits_reg <= nbits_next;
        data_reg <= data_next;
    end
end

// State Machine Logic
always @(*) begin
next_state = state;
data_ready = 1'b0;
tick_next = tick_reg;
nbits_next = nbits_reg;
data_next = data_reg;
case(state)
    idle:if(~rx)
            begin
            next_state = start;
            tick_next = 0;
            end
         else
            next_state = idle;
    start:if(sample_tick) begin
            if(tick_reg == 7) begin
            next_state = data;
            tick_next = 0;
            nbits_next = 0;
            end
          else
            tick_next = tick_reg + 1;
          end  
    data:if(sample_tick)
            if(tick_reg == 15) begin
            tick_next = 0;
            data_next = {rx,data_reg[7:1]};
            if(nbits_reg == (DBITS-1))
                next_state = stop;
            else
                nbits_next = nbits_reg + 1;
            end
         else
            tick_next = tick_reg + 1;
    stop:if(sample_tick)
            if(tick_reg == (SB_TICK-1)) begin
            next_state = idle;
            data_ready = 1'b1;
            end
            else
            tick_next = tick_reg + 1;
endcase
end
// Output Logic
assign data_out = data_reg;
endmodule
