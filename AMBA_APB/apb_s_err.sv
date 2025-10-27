`timescale 1ns / 1ps

module apb_s_err(
input pclk,
input presetn,
input [3:0] paddr,
input [7:0] pwdata,
input psel,
input penable,
input pwrite,

output reg [7:0] prdata,
output reg pready,
output reg pslverr
    );
    
localparam [1:0] idle = 0, write = 1, read = 2;
reg [1:0] state, nstate;
reg [7:0] mem[16];

bit addr_err, addv_err, data_err, setup_apb_err;

//// setup - correct apb cycles
///// addr_err - should be less than 16
//// addv_err - correct address value (addr >= 0)
//// data_err - correct data value (data >= 0)

////reset decoder
always @(posedge pclk, negedge presetn)
begin
if(presetn == 1'b0)
    state <= idle;
else
    state <= nstate;
end

/// next state, output decoder
always @ (*) begin
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
                if(!addr_err && !addv_err && data_err)
                    begin
                    pready = 1'b1;
                    mem[paddr] = pwdata;
                    nstate = idle;
                    end
                else
                    begin
                    nstate = idle;
                    pready = 1'b1;
                    end
           end
           end
    read: begin
          if(psel == 1'b1 && penable == 1'b1)
            begin
                if(!addr_err && !addv_err && !data_err)
                    begin
                    pready = 1'b1;
                    prdata = mem[paddr];
                    nstate = idle;
                    end
                else 
                    begin
                    pready = 1'b1;
                    prdata = 8'h00;
                    nstate = idle;
                    end
            end
          end
    default: begin
             pready = 1'b0;
             prdata = 8'h00;
             nstate = idle;
             end
    endcase
end

//////////////////////// checking valid value of address
reg av_t = 0;
always @(*)
begin
if(paddr >= 0)
    av_t = 1'b0;
else
    av_t = 1'b1;
end

//////////////////////// checking valid value of data
reg dv_t = 0;
always @(*)
begin
if(pwdata >= 0)
    dv_t = 1'b0;
else
    dv_t = 1'b1;
end

assign addr_err = ((nstate == write || read) && (paddr > 15)) ? 1'b1:1'b0;
assign addv_err = (nstate == write || read)? av_t : 1'b0;
assign data_err = (nstate == write || read)? dv_t : 1'b0;

assign pslerr = (penable == 1'b1 && psel == 1'b1)? (addr_err || addv_err || data_err):1'b0;
endmodule
