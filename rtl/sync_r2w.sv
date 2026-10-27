`timescale 1ns / 1ps
`default_nettype none

// Synchronizer module used to pass an n-bit pointer
// from the read clock domain to the write clock domain

module sync_r2w #(parameter int ASIZE = 4)
(
output logic [ASIZE:0] wq2_rptr,
input wire logic [ASIZE:0] rptr,
input wire logic wclk,
input wire logic wrst_n
    );
(* ASYNC_REG = "TRUE" *) logic [ASIZE:0] wq1_rptr;
(* ASYNC_REG = "TRUE" *) logic [ASIZE:0] wq2_rptr_ff;

assign wq2_rptr = wq2_rptr_ff;


always_ff @(posedge wclk or negedge wrst_n) begin : sync_stages
if (!wrst_n) begin
{wq2_rptr_ff, wq1_rptr} <= '0;
end
else begin
{wq2_rptr_ff, wq1_rptr} <= {wq1_rptr, rptr};
end
end

endmodule : sync_r2w

`default_nettype wire
