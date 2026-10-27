`timescale 1ns/1ps
`default_nettype none

// Top -level FIFO module with all sub-blocks instantiated
// and named port connections

module fifo1 #(parameter int DSIZE = 8, 
parameter int ASIZE = 4)

(
output logic [DSIZE-1:0] rdata, 
output logic wfull,
output logic rempty,
input wire logic [DSIZE-1:0] wdata, 
input wire logic winc, 
input wire logic wclk, 
input wire logic wrst_n,
input wire logic rinc, 
input wire logic rclk, 
input wire logic rrst_n
);

logic [ASIZE-1:0] waddr, raddr;
logic [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

sync_r2w #(.ASIZE(ASIZE)) u_sync_r2w (
.wq2_rptr (wq2_rptr),
.rptr (rptr),
.wclk (wclk),
.wrst_n (wrst_n)
);

sync_w2r #(.ASIZE(ASIZE)) u_sync_w2r (
.rq2_wptr (rq2_wptr),
.wptr (wptr),
.rclk (rclk),
.rrst_n (rrst_n)
);

fifomem #(
.DSIZE (DSIZE),
.ASIZE (ASIZE)
) u_fifomem (
.rdata (rdata),
.wdata (wdata),
.waddr (waddr),
.raddr (raddr),
.wclken (winc),
.wfull (wfull),
.wclk (wclk)
);

rptr_empty #(
.ASIZE (ASIZE)
) u_rptr_empty (
.rempty (rempty),
.raddr (raddr),
.rptr (rptr),
.rq2_wptr (rq2_wptr),
.rinc (rinc),
.rclk (rclk),
.rrst_n (rrst_n)
);

wptr_full #(
.ASIZE (ASIZE)
) u_wptr_full (
.wfull (wfull),
.waddr (waddr),
.wptr (wptr),
.wq2_rptr (wq2_rptr),
.winc (winc),
.wclk (wclk),
.wrst_n (wrst_n)
);


endmodule : fifo1

`default_nettype wire