`timescale 1ns/1ps
`default_nettype none

// The memory buffer could be synthesized to ASIC or FPGA
// registers using the RTL code in this module

module fifomem #(
parameter int DSIZE = 8, // Memory data word width
parameter int ASIZE = 4) // Number of mem address bits

(
output logic [DSIZE-1:0] rdata,
input wire logic [DSIZE-1:0] wdata,
input wire logic [ASIZE-1:0] waddr,
input wire logic [ASIZE-1:0] raddr,
input wire logic wclken,
input wire logic wfull,
input wire logic wclk
);

`ifdef VENDORRAM
// instantiation of a vendor's dual-port RAM
vendor_ram u_ram (
.dout (rdata),
.din (wdata),
.waddr (waddr),
.raddr (raddr),
.wclken (wclken),
.wclken_n (wfull),
.clk (wclk)
);
`else
localparam DEPTH = 1 << ASIZE;

logic [DSIZE-1:0] mem [DEPTH];

assign rdata = mem[raddr];

always_ff @(posedge wclk) begin : mem_write
if (wclken && !wfull) begin
mem[waddr] <= wdata;
end
end
`endif

endmodule : fifomem

`default_nettype wire
