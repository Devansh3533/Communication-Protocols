`timescale 1ns / 1ps

module I2C_Core_Top
#(
    parameter CLK_FREQ_HZ = 50_000_000,
    parameter I2C_FREQ_HZ = 100_000
)
(
    input  clk,
    input  resetn,
    input  i2c_start,
    input  i2c_read,
    input  [6:0] i2c_addr,
    input  [7:0] i2c_data_in,
    output [7:0] i2c_data_out,
    output i2c_done,
    output i2c_busy,
    output i2c_ack_error,
    inout  SCL,
    inout  SDA
);

    // Internal Wires
    wire sda_out_en, sda_data_out;
    wire i2c_clk_en;
    wire scl_i, sda_i, scl_pulse;

    // ------------------------------------------------------
    // Pull-ups for Simulation (Emulate external resistors)
    // ------------------------------------------------------
    tri1 SCL_pull = SCL;
    tri1 SDA_pull = SDA;

    pullup(SCL_pull);
    pullup(SDA_pull);

    // ------------------------------------------------------
    // Bus Interface (Bit-level timing generation)
    // ------------------------------------------------------
    I2C_bus_interface #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .I2C_FREQ_HZ(I2C_FREQ_HZ)
    ) i2c_bus_interface_inst (
        .clk          (clk),
        .resetn       (resetn),
        .scl          (SCL),
        .sda          (SDA),
        .i2c_clk_en   (i2c_clk_en),
        .sda_out_en   (sda_out_en),
        .sda_data_out (sda_data_out),
        .scl_i        (scl_i),
        .sda_i        (sda_i),
        .scl_pulse    (scl_pulse)
    );

    // ------------------------------------------------------
    // Controller (Byte-level FSM)
    // ------------------------------------------------------
    I2C_controller i2c_controller_inst (
        .clk           (clk),
        .resetn        (resetn),
        .start_i       (i2c_start),
        .read_i        (i2c_read),
        .addr_i        (i2c_addr),
        .data_i        (i2c_data_in),
        .data_o        (i2c_data_out),
        .done_o        (i2c_done),
        .busy_o        (i2c_busy),
        .ack_error_o   (i2c_ack_error),
        .scl_i         (scl_i),
        .sda_i         (sda_i),
        .scl_pulse     (scl_pulse),
        .i2c_clk_en    (i2c_clk_en),
        .sda_out_en    (sda_out_en),
        .sda_data_out  (sda_data_out)
    );

endmodule
