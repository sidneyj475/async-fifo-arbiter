`timescale 1ns/1ps

module counter_tb;
  localparam int WIDTH = 4;

  logic clk = 0;
  logic rst;
  logic en;
  logic [WIDTH-1:0] count;

  counter #(.WIDTH(WIDTH)) dut (
    .clk(clk), .rst(rst), .en(en), .count(count)
  );

  always #5 clk = ~clk;

  int errors = 0;

  task check(input logic [WIDTH-1:0] expected, input string label);
    if (count !== expected) begin
      $error("%s: expected %0d, got %0d", label, expected, count);
      errors++;
    end
  endtask

  initial begin
    rst = 1; en = 0;
    @(posedge clk);
    @(negedge clk);
    check(0, "after reset");

    rst = 0; en = 1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    check(3, "after 3 enabled cycles");

    en = 0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    check(3, "held with enable low");

    en = 1;
    repeat (13) @(posedge clk);
    @(negedge clk);
    check(0, "wrapped at 2^WIDTH");

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d errors", errors);
    $finish;
  end
endmodule