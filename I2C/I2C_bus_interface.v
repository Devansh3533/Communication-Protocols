`timescale 1ns / 1ps

module I2C_bus_interface
#(
    parameter CLK_FREQ_HZ = 500_000_000,
    parameter I2C_FREQ_HZ = 100_000
)
(
    input  clk,
    input  resetn,
    inout  scl,
    inout  sda,
    input  i2c_clk_en,
    input  sda_out_en,
    input  sda_data_out,
    output reg scl_i,
    output reg sda_i,
    output reg scl_pulse
);

    localparam COUNT_VAL = (CLK_FREQ_HZ / I2C_FREQ_HZ) / 2;

    reg [15:0] scl_counter;
    reg scl_reg;
    reg scl_o_en;
    reg sda_d;
    reg scl_d;
    reg scl_prev;

    // Generate I2C Clock when enabled
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            scl_counter <= 0;
            scl_reg <= 1'b1;   // idle high
            scl_o_en <= 0;
            sda_d <= 1'b1;
            scl_d <= 1'b1;
        end 
        else if (i2c_clk_en) begin
            if (scl_counter == COUNT_VAL - 1) begin
                scl_counter <= 0;
                scl_reg <= ~scl_reg;
            end else begin
                scl_counter <= scl_counter + 1;
            end
            scl_o_en <= 1;
        end 
        else begin
            scl_counter <= 0;
            scl_reg <= 1'b1;   // keep high when idle
            scl_o_en <= 1;     // still drive line
        end
    end

    // -----------------------------
    // SIMULATION-PULLUP FIX
    // -----------------------------
    // In real hardware: pull-ups exist externally.
    // In simulation: we emulate it with weak pullups.
    tri1 scl_pull = scl;
    tri1 sda_pull = sda;

    pullup(scl_pull);
    pullup(sda_pull);

    // Drive lines (open-drain behavior)
    assign scl = (scl_o_en && (scl_reg == 1'b0)) ? 1'b0 : 1'bz;
    assign sda = (sda_out_en && (sda_data_out == 1'b0)) ? 1'b0 : 1'bz;

    // Input sampling and edge detection
    always @(posedge clk) begin
        sda_d <= sda;
        scl_d <= scl;
        sda_i <= sda_d;
        scl_i <= scl_d;
        scl_prev <= scl_i;
        scl_pulse <= (scl_prev == 1'b1) && (scl_i == 1'b0);
    end

endmodule
