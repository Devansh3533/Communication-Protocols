`timescale 1ns / 1ps

module apb_m_err(
input pclk,
input presetn,
input [1:0] slv_addr_in, /// slave - 1, slave - 2
input [3:0] addrin,
input [7:0] datain,
input newd,
input wr,
input [7:0] prdata,
input pready,


output reg psel1, psel2,
output reg penable,
output reg slverr,
output reg [3:0] paddr,
output reg [7:0] pwdata,
output reg pwrite,
output [7:0] dataout
    );
 
 localparam [1:0] idle = 0, setup = 1, enable = 2;
 
 reg [1:0] state, nstate;
 
 //// reset decoder
always @(posedge pclk, negedge presetn)
begin
    if(presetn == 1'b0)
        state <= idle;
    else
        state <= nstate;
end

////// state decoder
always @(*)
begin
case(state)
    idle: begin
          if(newd == 1'b0)
            state = idle;
          else
            state = setup;
          end
    setup: nstate = enable;
    enable: begin
            if(newd == 1'b1)
                begin
                if(pready == 1'b1)
                    nstate = setup;
                else
                    nstate = enable;
                end
            else
                nstate = idle;
            end
    default: nstate = idle;
endcase
end

///////// address decoding
always @(posedge pclk, negedge presetn)
begin
    if(presetn == 1'b0)
    begin
        psel1 <= 1'b0;
        psel2 <= 1'b0;
    end
    else if(nstate == idle)
    begin
        psel1 <= 1'b0;
        psel2 <= 1'b0;    
    end
    else if(nstate == setup || nstate == enable)
    begin
        if(slv_addr_in == 2'b01)
        begin
            psel1 <= 1'b1;
            psel2 <= 1'b0;
        end
        else
        begin
            psel1 <= 1'b0;
            psel2 <= 1'b1;
        end
    end
    else 
    begin
        psel1 <= 1'b0;
        psel2 <= 1'b0;
    end
end

//////// address dcoding
always @(posedge pclk, negedge presetn)
begin
    if(presetn == 1'b0)
    begin
        penable <= 1'b0;
        paddr <= 1'b0;
        pwdata <= 8'h00;
        pwrite <= 1'b0;
    end
    else if(state == idle)
    begin
        penable <= 1'b0;
        paddr <= 1'b0;
        pwdata <= 8'h00;
        pwrite <= 1'b0;
    end
    else if(state == setup)
    begin
        penable <= 1'b0;
        paddr <= addrin;
        pwrite <= wr;
        if(wr == 1)
            pwdata <= datain;
    end
    else if(nstate == enable)
        penable <= 1'b1;
end

assign dataout = ((psel1 == 1'b1 || psel2 == 1'b1) && penable == 1'b1 && pwrite == 1'b0) ? prdata:8'h00;
endmodule
