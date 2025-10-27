`timescale 1ns / 1ps

module Transmitter_uart
#(parameter DBITS = 8,
            SB_TICK = 16
)
(
input clk,
input reset,
input tx_start,                 /// begin data transmission (FIFO not empty)
input sample_tick,              /// from baud rate generator
input [DBITS-1:0] data_in,      /// data word from FIFO
output reg tx_done,             /// end of transmission
output tx                       /// transmission data line
);

// FSM States
localparam [1:0] idle = 2'b00,
                 start = 2'b01,
                 data = 2'b10,
                 stop = 2'b11;
// Registers
reg [1:0] state, next_state;
reg [3:0] tick_reg, tick_next;              /// no. of ticks received from baud rate generator
reg [2:0] nbits_reg, nbits_next;            /// no. of bits transmitted in data state
reg [DBITS-1:0] data_reg, data_next;        /// assembled data words to transmit serially
reg tx_reg, tx_next;                        /// data filters for potential glitches
 
/// Register Logic
always @(posedge clk, negedge reset) begin
    if(~reset) begin
    state <= idle;
    tick_reg <= 0;
    nbits_reg <= 0;
    data_reg <= 0;
    tx_reg <= 1'b1;
    end
    else begin
    state <= next_state;
    tick_reg <= tick_next;
    nbits_reg <= nbits_next;
    data_reg <= data_next;
    tx_reg <= tx_next;
    end
end 

// State Machine Logic
always @(*) begin
next_state = state;
tx_done = 1'b0;
tick_next = tick_next;
nbits_next = nbits_reg;
data_next = data_reg;
tx_next = tx_reg;

case(state)
    idle:begin                          /// no data in FIFO
            tx_next = 1'b1;             /// transmit idle
            if(tx_start) begin          /// When FIFO is not empty
                next_state = start;
                tick_next = 0;
                data_next = data_in;
            end
         end
    start:begin
          tx_next = 1'b0;                  ///start bit
          if(sample_tick) begin
            if(tick_reg == 15) begin
            next_state = data;
            tick_next = 0;
            nbits_next = 0;
            end
            else
                tick_next = tick_reg + 1;
          end 
          end
    data:begin
         tx_next = data_reg[0];
         if(sample_tick)
            if(tick_reg == 15) begin
                tick_next = 1'b0;
                data_next = data_reg >> 1;
                if(nbits_reg == (DBITS-1))
                    next_state = stop;
                else
                    nbits_next = nbits_reg + 1;
            end
            else
                tick_next = tick_reg + 1;
         end
    stop:begin
         tx_next = 1'b1;            /// back to idle
         if(sample_tick)
            if(tick_reg == (SB_TICK-1)) begin
                next_state = idle;
                tx_done = 1'b1;
            end
            else
                tick_next = tick_reg + 1;
         end
endcase
end
/// Output Logic
assign tx = tx_reg;
endmodule
