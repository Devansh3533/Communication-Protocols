`timescale 1ns / 1ps

module I2C_controller(
    input clk,
    input resetn,
    input start_i,
    input read_i,
    input [6:0] addr_i,
    input [7:0] data_i,

    output reg [7:0] data_o,
    output reg done_o,
    output reg ack_error_o,
    output reg busy_o,

    // Bus Interface
    input scl_i,
    input sda_i,
    input scl_pulse,

    output reg i2c_clk_en,
    output reg sda_out_en,
    output reg sda_data_out
);

localparam [3:0]
    IDLE         = 4'h0,
    START        = 4'h1,
    TX_ADDR      = 4'h2,
    ACK_ADDR     = 4'h3,
    TX_DATA      = 4'h4,
    ACK_TX_DATA  = 4'h5,
    RX_DATA      = 4'h6,
    ACK_RX       = 4'h7,
    STOP         = 4'h8;

reg [3:0] current_state, next_state;
reg [2:0] bit_counter;
reg [7:0] shift_reg;

// Sequential FSM
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        current_state <= IDLE;
        busy_o        <= 0;
        done_o        <= 0;
        ack_error_o   <= 0;
        data_o        <= 0;
        shift_reg     <= 0;
        bit_counter   <= 0;
    end else begin
        current_state <= next_state;
    end
end

// Combinational FSM (next state & outputs)

always @(*) begin
    next_state    = current_state;
    i2c_clk_en    = 0;
    sda_out_en    = 0;
    sda_data_out  = 1;
    busy_o        = 0;
    done_o        = 0;

    case (current_state)
        IDLE: begin
            if (start_i) begin
                next_state    = START;
                ack_error_o   = 0;
                busy_o        = 1;
            end
        end

        START: begin
            sda_out_en   = 1;
            sda_data_out = 0;
            if (scl_i == 1'b1) begin
                next_state  = TX_ADDR;
            end
        end

        TX_ADDR: begin
            i2c_clk_en = 1;
            busy_o     = 1;
            if (scl_pulse) begin
                sda_out_en   = 1;
                sda_data_out = shift_reg[bit_counter];
                if (bit_counter == 0)
                    next_state = ACK_ADDR;
            end
        end

        ACK_ADDR: begin
            i2c_clk_en = 1;
            busy_o     = 1;
            if (scl_pulse) begin
                if (sda_i == 1'b1) begin
                    ack_error_o = 1;
                    next_state  = STOP;
                end else begin
                    if (read_i)
                        next_state = RX_DATA;
                    else
                        next_state = TX_DATA;
                end
            end
        end

        TX_DATA: begin
            i2c_clk_en = 1;
            busy_o     = 1;
            if (scl_pulse) begin
                sda_out_en   = 1;
                sda_data_out = shift_reg[bit_counter];
                if (bit_counter == 0)
                    next_state = ACK_TX_DATA;
            end
        end

        ACK_TX_DATA: begin
            i2c_clk_en = 1;
            busy_o     = 1;
            if (scl_pulse) begin
                if (sda_i == 1'b1)
                    ack_error_o = 1; // NACK
                next_state = STOP;
            end
        end

        RX_DATA: begin
            i2c_clk_en = 1;
            busy_o     = 1;
            sda_out_en = 0;
            
        end

        ACK_RX: begin
            i2c_clk_en = 1;
            busy_o     = 1;
            sda_out_en = 1;
            if (bit_counter == 0)
                sda_data_out = 1; // NACK for last byte
            else
                sda_data_out = 0; // ACK for intermediate bytes
            if (scl_pulse) begin
                next_state = STOP;
            end
        end

        STOP: begin
            busy_o = 1;
            sda_out_en = 0;
            if (scl_i == 1'b1) begin
                next_state = IDLE;
                done_o     = 1;
            end
        end

        default: next_state = IDLE;
    endcase
end

// Sequential updates for shift_reg and bit_counter
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        shift_reg   <= 0;
        bit_counter <= 0;
        data_o      <= 0;
    end else begin
        case (current_state)
            START: begin
                if (scl_i == 1'b1) begin
                    shift_reg   <= {addr_i, read_i};
                    bit_counter <= 7;
                end
            end

            TX_ADDR, TX_DATA: begin
                if (scl_pulse) begin
                    if (bit_counter != 0) begin
                        shift_reg   <= shift_reg << 1;
                        bit_counter <= bit_counter - 1;
                    end
                end
            end

            ACK_ADDR: begin
                if (scl_pulse && !sda_i && !read_i) begin
                    shift_reg   <= data_i;
                    bit_counter <= 7;
                end
            end

            RX_DATA: begin
                if (scl_pulse) begin
                    shift_reg   <= {shift_reg[6:0], sda_i};
                    if (bit_counter != 0)
                        bit_counter <= bit_counter - 1;
                    else
                        data_o <= {shift_reg[6:0], sda_i}; // Capture last bit
                end
            end

            ACK_RX: begin
                // Nothing to update sequentially; ACK is controlled by sda_data_out
            end
        endcase
    end
end

endmodule
