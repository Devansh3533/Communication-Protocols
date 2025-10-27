`timescale 1ns / 1ps

module abp_m(
input pclk,
input presetn,
input [3:0] addrin,
input [7:0] datain,
input wr,
input newd,
input [7:0] prdata,
input pready,

output reg psel,
output reg penable,
output reg [3:0] paddr,
output reg [7:0] pwdata,
output reg pwrite,
output reg [7:0] dataout
    );

localparam [1:0] idle = 0, setup = 1, enable = 2;

reg [1:0] state, nstate;

///reset decoder
always@(posedge pclk) begin
    if (presetn)
    state <= idle;
    else
    state <= nstate;
end

always @(*) begin
    case(state)
    idle: begin
            if(newd == 1'd0)
                nstate = idle;
            else
                nstate = setup;
          end
    setup: begin
            nstate = enable;
           end
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

/// address decoding
always @(posedge pclk, negedge presetn)
begin
if(!presetn)
    psel <= 1'b0;
else if(nstate == idle)
    psel <= 1'b0;
else if(nstate == enable || nstate == setup)
    psel <= 1'b1;
else
    psel <= 1'b0;
end

///Output Logic

always @(posedge pclk,negedge presetn)
begin
if(presetn == 1'b0 || nstate == idle) begin
penable <= 1'b0;
paddr <= 4'h0;
pwdata <= 8'h00;
pwrite <= 1'b0;
end
else if(nstate == setup)
begin
penable <= 1'b0;
paddr <= addrin;
pwrite <= wr;
if(wr == 1'b1)
    pwdata <= datain;
end
else if(nstate == enable) begin
    penable <= 1'b1;
    if(wr == 1'b0)
        dataout <= prdata;
end
end
endmodule
