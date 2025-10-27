`timescale 1ns / 1ps

module abp_s(
input pclk,
input presetn,
input [3:0] paddr,
input psel,
input penable,
input [7:0] pwdata,
input pwrite,
output reg [7:0] prdata,
output reg pready
    );

localparam [1:0] idle = 0, write = 1, read = 2;

reg [7:0] mem[15:0];
reg [1:0] state, nstate;

//// reset decoder

always @(posedge pclk, negedge presetn)
begin
if(presetn == 1'b0)
state <= idle;
else 
state <= nstate;
end

always @(*)
begin
case(state)
    idle: begin
          prdata = 8'h00;
          pready = 1'b0;
          if(psel == 1'b1 && pwrite == 1'b1)
            nstate = write;
          else if(psel == 1'b1 && pwrite == 1'b0)
            nstate = read;
          else 
            nstate = idle;
          end
    write: begin
           if(psel == 1'b1 && penable == 1'b1)
            begin
            pready = 1'b1;
            mem[paddr] = pwdata;
            nstate = idle;
            end
            else 
            begin
                nstate = idle;
            end
           end
    read: begin
          if(psel == 1'b1 && penable == 1'b1)
            begin
            pready = 1'b1;
            prdata = mem[paddr];
            nstate = idle;
            end
            else
                nstate = idle;
          end
    default: nstate = idle;
    endcase
end
endmodule
