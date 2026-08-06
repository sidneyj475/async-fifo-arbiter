module counter #(parameter int DEPTH = 8) (
input logic clk,
input logic rst,
input logic en,
output logic [DEPTH-1:0] count
);
always_ff @(posedge clk) begin
if (rst)
count <= '0;
else if (en)
count <= count + 1'b1;
end
endmodule
