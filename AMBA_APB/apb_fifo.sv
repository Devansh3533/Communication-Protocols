`timescale 1ns / 1ps

module apb_fifo(
input wire              clk,            /////// Clock Input
input wire              rst,            /////// Reset Input
input wire              penable,        /////// APB Enable Input
input wire              pclk,           /////// APB Clock Input
input wire              presetn,        /////// APB Reset Input
input wire              psel,           /////// APB Select Input
input wire [31:0]       paddr,          /////// APB Address Input
input wire [31:0]       pwdata,         /////// APB Write Data Input
input wire              pwrite,         /////// APB Write Enable Input
output reg [31:0]       prdata,         /////// APB Read Data Output
output reg              pready          /////// APB Read Data Ready Output
    );
/// Define Parameters
parameter DEPTH = 16; //// Size of FIFO memory
parameter idle = 0, check_op = 1, write_data = 2, read_data = 3, send_ready = 4;
reg [3:0] state = idle;
reg [31:0] addr, wdata, rdata;

//// Internal FIFO Memory
reg [31:0] mem [16];
reg [3:0] wr_ptr;  /// pointer for 16 memory locations of FIFO
reg [3:0] rd_ptr;  /// pointer for 16 memory locations of FIFO fo read operations
reg [4:0] count;   /// count of valid entries in FIFO
reg [1:0] cwait = 0;

/// AP FIFO control logic
always @(posedge clk, negedge rst)
begin
    if(rst == 0) begin
       for(int i=0;i<16;i++)
       begin mem[i] <= 0;
       end
       wr_ptr <= 0;
       rd_ptr <= 0;
       count <= 0;
       pready <= 0;
       state <= idle;
       prdata <= 0;
       wdata <= 0;
       rdata <= 0;
       addr <= 0;
       cwait <= 0;
    end
    else begin
    ///// APB write operation
    case(state)
        idle: begin
              wr_ptr <= 0;
              rd_ptr <= 0;
              count <= 0;
              pready <= 0;
              state <= check_op;
              prdata <= 0;
              wdata <= 0;
              rdata <= 0;
              addr <= 0;
              cwait <= 0;
              end
        check_op: begin
                  if(psel && penable && pwrite && count!=15)
                    begin
                    state <= write_data;
                    addr <= paddr;
                    wdata <= pwdata;
                    end 
                  else if(psel && penable && !pwrite && count!=15)
                    begin
                    state <= read_data;
                    addr <= paddr;
                    end
                  else
                    state <= check_op;
                  end
        write_data: begin
                    mem[addr] <= wdata;
                    if(cwait < 2)
                    begin
                        state <= write_data;
                        cwait = cwait + 1;
                    end
                    else
                    begin
                        cwait <= 0;
                        pready <= 1'b1;
                        state <= send_ready;
                        wr_ptr <= wr_ptr + 1;
                        count <= count + 1;
                    end
                    end
        read_data: begin
                    rdata <= mem[addr];
                    if(cwait < 2)
                    begin
                        state <= read_data;
                        cwait <= cwait + 1;
                    end
                    else 
                    begin
                        cwait <= 0;
                        state <= send_ready;
                        pready <= 1'b1;
                        prdata <= rdata;
                        rd_ptr <= rd_ptr + 1;
                        count <= count - 1;
                    end
                   end
        send_ready: begin
                        state <= check_op;
                        pready <= 0;
                    end
    endcase
    end
end
endmodule
