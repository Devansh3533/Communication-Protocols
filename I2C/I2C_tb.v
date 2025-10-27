`timescale 1ns / 1ps

module I2C_tb;
    // --- Parameters ---
    localparam CLK_FREQ = 50_000_000;       // 50 MHz
    localparam I2C_FREQ = 100_000;          // 100 kHz
    localparam SLAVE_ADDR = 7'h50;
    localparam MASTER_WRITE_DATA = 8'hAA;
    localparam SLAVE_READ_DATA = 8'hCC;     // Data slave returns on read

    // --- Signals ---
    reg clk;
    reg resetn;
    reg i2c_start;
    reg i2c_read;
    reg [6:0] i2c_addr;
    reg [7:0] i2c_data_in;
    wire [7:0] i2c_data_out;
    wire i2c_done;
    wire i2c_busy;
    wire i2c_ack_error;

    // I2C Bus
    wire SCL;
    wire SDA;

    // Slave status
    wire slave_write_en;
    wire [7:0] slave_data_rx;
    wire slave_is_addressed;

    // Preloaded slave data
    reg [7:0] slave_data_to_send;

    // Master received data
    reg [7:0] master_data_received;

    // --- Clock generation ---
    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz

    // --- Master instance ---
    I2C_Core_Top #(
        .CLK_FREQ_HZ(CLK_FREQ),
        .I2C_FREQ_HZ(I2C_FREQ)
    ) master_inst (
        .clk           (clk),
        .resetn        (resetn),
        .i2c_start     (i2c_start),
        .i2c_read      (i2c_read),
        .i2c_addr      (i2c_addr),
        .i2c_data_in   (i2c_data_in),
        .i2c_data_out  (i2c_data_out),
        .i2c_done      (i2c_done),
        .i2c_busy      (i2c_busy),
        .i2c_ack_error (i2c_ack_error),
        .SCL           (SCL),
        .SDA           (SDA)
    );

    // --- Slave instance ---
    I2C_Slave #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) slave_inst (
        .clk           (clk),
        .resetn        (resetn),
        .scl           (SCL),
        .sda           (SDA),
        .data_tx_i     (slave_data_to_send),
        .write_en_o    (slave_write_en),
        .data_rx_o     (slave_data_rx),
        .is_addressed_o(slave_is_addressed)
    );

    // --- Monitoring ---
    always @(posedge clk) begin
        if (slave_write_en) begin
            $display("[%0t] SLAVE WRITE COMPLETE: Received=0x%h, Expected=0x%h", 
                     $time, slave_data_rx, MASTER_WRITE_DATA);
        end
        if (i2c_done && i2c_read) begin
            master_data_received <= i2c_data_out;
            $display("[%0t] MASTER READ COMPLETE: Received=0x%h, Expected=0x%h", 
                     $time, i2c_data_out, SLAVE_READ_DATA);
        end
    end

    // --- Test sequence ---
    initial begin
        // Initialize signals
        resetn = 0;
        i2c_start = 0;
        i2c_read = 0;
        i2c_addr = SLAVE_ADDR;
        i2c_data_in = 8'h00;
        slave_data_to_send = SLAVE_READ_DATA;

        // Apply reset
        #100;
        resetn = 1;

        // Small delay
        #50;

        // -----------------------------
        // TEST 1: MASTER WRITE
        // -----------------------------
        $display("\n--- MASTER WRITE TEST ---");
        i2c_read = 0;
        i2c_addr = SLAVE_ADDR;
        i2c_data_in = MASTER_WRITE_DATA;

        // Pulse start
        i2c_start = 1;
        #20;
        i2c_start = 0;

        // Wait for transaction to complete
        wait(!i2c_busy);
        #50;

        // -----------------------------
        // TEST 2: MASTER READ
        // -----------------------------
        $display("\n--- MASTER READ TEST ---");
        i2c_read = 1;
        i2c_addr = SLAVE_ADDR;

        // Pulse start
        i2c_start = 1;
        #20;
        i2c_start = 0;

        // Wait for transaction to complete
        wait(!i2c_busy);
        #50;

        // -----------------------------
        // Final check
        // -----------------------------
        if (!i2c_ack_error) begin
            $display("I2C Simulation Passed: No ACK errors.");
            if (master_data_received == SLAVE_READ_DATA && slave_data_rx == MASTER_WRITE_DATA)
                $display("I2C Simulation Passed: Data integrity verified.");
            else
                $display("I2C Simulation FAILED: Data mismatch.");
        end else begin
            $display("I2C Simulation FAILED: ACK error occurred.");
        end

        #500 $stop;
    end
endmodule
