`timescale 1ns / 1ps

module I2C_Slave
#(parameter SLAVE_ADDR = 7'h50)     // Default address of slave
(
    input clk,
    input resetn,
    inout scl,
    inout sda,
    input [7:0] data_tx_i,
    output reg write_en_o,
    output reg [7:0] data_rx_o,
    output is_addressed_o
);

    // FSM states
    localparam [3:0] 
        IDLE        = 4'h0,
        START_DETECT= 4'h1, 
        RX_ADDR     = 4'h2, 
        ACK_ADDR    = 4'h3, 
        RX_DATA     = 4'h4, 
        ACK_RX_DATA = 4'h5, 
        TX_DATA     = 4'h6, 
        ACK_TX_DATA = 4'h7, 
        STOP_DETECT = 4'h8;

    reg [3:0] current_state, next_state;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;

    // Sampling signals
    reg scl_d, scl_i, scl_prev;
    reg sda_d, sda_i;

    // SDA driver
    reg sda_driver_en;
    reg sda_driver_data;

    wire scl_low_pulse  = (scl_prev == 1'b1) && (scl_i == 1'b0);
    wire scl_high_pulse = (scl_prev == 1'b0) && (scl_i == 1'b1);

    // Tri-state SDA
    assign sda = (sda_driver_en && (sda_driver_data == 1'b0)) ? 1'b0 : 1'bz;

    // Indicates slave is addressed for read/write
    assign is_addressed_o = (current_state == RX_DATA || current_state == TX_DATA);

    // Sequential block for FSM and sampling
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            current_state <= IDLE;
            scl_d <= 1; scl_i <= 1; scl_prev <= 1;
            sda_d <= 1; sda_i <= 1;
            bit_count <= 0;
            shift_reg <= 0;
            write_en_o <= 0;
            data_rx_o <= 0;
        end else begin
            // Sample SDA and SCL
            scl_d <= scl;
            sda_d <= sda;
            scl_i <= scl_d;
            sda_i <= sda_d;
            scl_prev <= scl_i;

            // FSM state update
            current_state <= next_state;

            // Sequential updates for shift_reg and bit_count
            case (current_state)
                RX_ADDR, RX_DATA: begin
                    if (scl_low_pulse) begin
                        shift_reg <= {shift_reg[6:0], sda_i};
                        bit_count <= bit_count - 1;
                    end
                end

                TX_DATA: begin
                    if (scl_low_pulse) begin
                        shift_reg <= {shift_reg[6:0], 1'b0}; // shift left
                        bit_count <= bit_count - 1;
                    end
                end

                ACK_RX_DATA: begin
                    if (scl_high_pulse) begin
                        write_en_o <= 1;
                        data_rx_o <= shift_reg;
                    end else begin
                        write_en_o <= 0;
                    end
                end
            endcase
        end
    end

    // Combinational block for next_state and outputs
    always @(*) begin
        next_state = current_state;
        sda_driver_en = 0;
        sda_driver_data = 1;

        case (current_state)
            IDLE: begin
                bit_count = 8;
                if (scl_i == 1'b1 && sda_i == 1'b0) // START
                    next_state = RX_ADDR;
            end

            RX_ADDR: begin
                if (scl_i == 1'b1 && sda_i == 1'b1) // STOP
                    next_state = IDLE;
                else if (scl_low_pulse && bit_count == 1)
                    next_state = ACK_ADDR;
            end

            ACK_ADDR: begin
                if (shift_reg[7:1] == SLAVE_ADDR) begin
                    sda_driver_en = 1;
                    sda_driver_data = 0; // ACK
                    if (scl_high_pulse) begin
                        if (shift_reg[0] == 1'b1) begin
                            next_state = TX_DATA;
                            shift_reg = data_tx_i;
                            bit_count = 8;
                        end else begin
                            next_state = RX_DATA;
                            bit_count = 8;
                        end
                    end
                end else begin
                    if (scl_high_pulse)
                        next_state = IDLE;
                end
            end

            RX_DATA: begin
                if (scl_i == 1'b1 && sda_i == 1'b1) // STOP
                    next_state = STOP_DETECT;
                else if (scl_low_pulse && bit_count == 1)
                    next_state = ACK_RX_DATA;
            end

            ACK_RX_DATA: begin
                sda_driver_en = 1;
                sda_driver_data = 0; // ACK
                if (scl_high_pulse)
                    next_state = IDLE;
            end

            TX_DATA: begin
                if (scl_i == 1'b1 && sda_i == 1'b1) // STOP
                    next_state = STOP_DETECT;
                else if (scl_low_pulse && bit_count == 1)
                    next_state = ACK_TX_DATA;
                else if (scl_low_pulse)
                    sda_driver_en = 1;
                    sda_driver_data = shift_reg[7];
            end

            ACK_TX_DATA: begin
                sda_driver_en = 0; // Release SDA
                if (scl_low_pulse) begin
                    if (sda_i == 1'b1)
                        next_state = STOP_DETECT;
                    else
                        next_state = IDLE;
                end
            end

            STOP_DETECT: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule
