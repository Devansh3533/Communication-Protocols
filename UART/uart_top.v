`timescale 1ns / 1ps

module uart_top
#(parameter     DBITS = 8,              // number of data bits in word
                SB_TICK = 16,           // number of stop bits / oversampling ticks
                BR_LIMIT = 651,         // baud rate generator counter limit
                BR_BITS = 10,           // number of baud rate generator counter bits
                FIFO_EXP = 2            // exponent for number of FIFO address (2^2 = 4)
)
(
    input clk,
    input reset,
    input read_uart,
    input write_uart,
    input rx,
    input [DBITS-1:0] write_data,
    output rx_full,
    output rx_empty,
    output tx,
    output [DBITS-1:0] read_data
    );

// connection signals
wire tick;                              // sample tick from baud rate generator
wire rx_done_tick;                      // data word received
wire rx_done_tick;                      // data transmission complete
wire tx_empty;                          // Tx FIFO has no data to transmit
wire tx_fifo_not_empty;                 // Tx FIFO contains data to transmit
wire [DBITS-1:0] tx_fifo_out;           // from Tx FIFO to UART transmitter
wire [DBITS-1:0] rx_data_out;           // from UART receiver to Rx FIFO

// Instantiate Module for UART Core
baud_rate_generator
#(  .M(BR_LIMIT),
    .N(BR_BITS)
 )
BAUD_RATE_GEN
(
    .clk(clk),
    .reset(reset),
    .tick(tick)
);

Receiver_uart
#(
    .DBITS(DBITS),
    .SB_TICK(SB_TICK)
 )
 UART_RX_UNIT
(
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .sample_tick(sample_tick),
    .data_ready(rx_done_tick),
    .data_out(rx_data_out)
);

Transmitter_uart
#(
    .DBITS(DBITS),
    .SB_TICK(SB_TICK)
)
UART_TX_UNIT
(
    .clk(clk),
    .reset(reset),
    .tx_start(tx_fifo_not_empty),
    .sample_tick(tick),
    .data_in(tx_fifo_out),
    .tx_done(tx_done_tick),
    .tx(tx)
);

fifo
#(
    .DATA_SIZE(DBITS),
    .ADDR_SPACE_EXP(FIFO_EXP)
)
FIFO_RX_UNIT
(
    .clk(clk),
    .reset(reset),
    .write_to_fifo(rx_done_tick),
    .read_from_fifo(read_uart),
    .write_data_in(rx_data_out),
    .read_data_out(read_data),
    .empty(rx_empty),
    .full(rx_full)
);

    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_TX_UNIT
         (
            .clk(clk_100MHz),
            .reset(reset),
            .write_to_fifo(write_uart),
	        .read_from_fifo(tx_done_tick),
	        .write_data_in(write_data),
	        .read_data_out(tx_fifo_out),
	        .empty(tx_empty),
	        .full()                // intentionally disconnected
	      );

// signal logic
assign tx_fifo_not_empty = ~tx_empty;

endmodule
