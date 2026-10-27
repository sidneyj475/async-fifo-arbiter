`timescale 1ns / 1ps
`default_nettype none

// Synchronizer module used to pass an n-bit pointer
// from the write clock domain to the read clock domain

module sync_w2r #(parameter int ASIZE = 4)
(
output logic [ASIZE:0] rq2_wptr,
input wire logic [ASIZE:0] wptr,
input wire logic rclk,
input wire logic rrst_n
    );
(* ASYNC_REG = "TRUE" *) logic [ASIZE:0] rq1_wptr;
(* ASYNC_REG = "TRUE" *) logic [ASIZE:0] rq2_wptr_ff;

assign rq2_wptr = rq2_wptr_ff;


always_ff @(posedge rclk or negedge rrst_n) begin : sync_stages
if (!rrst_n) begin
{rq2_wptr_ff, rq1_wptr} <= '0;
end
else begin
{rq2_wptr_ff, rq1_wptr} <= {rq1_wptr, wptr};
end
end

endmodule : sync_w2r

`default_nettype wire
