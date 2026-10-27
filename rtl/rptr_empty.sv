`timescale 1ns / 1ps
`default_nettype none

// This module encloses all of the FIFO logic that
// is generated within the read clock domain except synchronizers
module rptr_empty #(parameter int ASIZE =4)
(
output logic rempty,
output logic [ASIZE-1:0] raddr,
output logic [ASIZE:0] rptr,
input wire logic [ASIZE:0] rq2_wptr,
input wire logic rinc,
input wire logic rclk,
input wire logic rrst_n
);

logic [ASIZE:0] rbin;
logic [ASIZE:0] rgraynext;
logic [ASIZE:0] rbinnext;
logic rempty_val;

// Gray pointer
always_ff @(posedge rclk or negedge rrst_n) begin : rptr_update
if (!rrst_n) begin
{rbin, rptr} <= '0;
end
else begin
{rbin, rptr} <= {rbinnext, rgraynext};
end
end

// Memory read-address pointer
assign raddr = rbin[ASIZE-1:0];

assign rbinnext = rbin + (ASIZE + 1)'(rinc & ~rempty);
assign rgraynext = (rbinnext >> 1) ^ rbinnext;

// Fifo empty when next rptr = synced wptr or on reset
assign rempty_val = (rgraynext == rq2_wptr);

always_ff @(posedge rclk or negedge rrst_n) begin : rempty_flag
if (!rrst_n) begin
rempty <= 1'b1;
end
else begin
rempty <= rempty_val;
end
end

endmodule : rptr_empty

`default_nettype wire

