`timescale 1ns / 1ps
`default_nettype none

module wptr_full #(parameter int ASIZE =4)
(
output logic wfull,
output logic [ASIZE-1:0] waddr,
output logic [ASIZE:0] wptr,
input wire logic [ASIZE:0] wq2_rptr,
input wire logic winc,
input wire logic wclk,
input wire logic wrst_n
);

logic [ASIZE:0] wbin;
logic [ASIZE:0] wgraynext;
logic [ASIZE:0] wbinnext;
logic wfull_val;

// Gray pointer
always_ff @(posedge wclk or negedge wrst_n) begin : wptr_update
if (!wrst_n) begin
{wbin, wptr} <= '0;
end
else begin
{wbin, wptr} <= {wbinnext, wgraynext};
end
end

// Memory write-address pointer
assign waddr = wbin[ASIZE-1:0];

assign wbinnext = wbin + {{ASIZE{1'b0}}, (winc && !wfull)};
assign wgraynext = (wbinnext >> 1) ^ wbinnext;

// Fifo full when next wptr = synced rptr
assign wfull_val = (wgraynext == {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]});

always_ff @(posedge wclk or negedge wrst_n) begin : wfull_flag
if (!wrst_n) begin
wfull <= 1'b0;
end
else begin
wfull <= wfull_val;
end
end
endmodule : wptr_full

`default_nettype wire
