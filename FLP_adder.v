
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2023 13:14:34
// Design Name: 
// Module Name: FLP_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module FLP_adder #(
  parameter EXP_WIDTH = 9, parameter MANT_WIDTH = 8
) (
  input clk,
  input signed [EXP_WIDTH-1:0] exp1,
  input signed [EXP_WIDTH-1:0] exp2,
  input [MANT_WIDTH-1:0] mant1,
  input [MANT_WIDTH-1:0] mant2,
  output reg [MANT_WIDTH-1:0] mant,
  output reg signed [EXP_WIDTH-1:0] exp
);

  wire first_is_larger = exp1 >= exp2;
  wire signed [EXP_WIDTH:0] larger_exp = first_is_larger ? exp1 : exp2;
  wire signed [EXP_WIDTH:0] smaller_exp = first_is_larger ? exp2 : exp1;
  wire [EXP_WIDTH:0] gap = larger_exp - smaller_exp;

  wire [MANT_WIDTH:0] larger = {1'b1, first_is_larger ? mant1 : mant2};
  wire [MANT_WIDTH:0] smaller = {1'b1, first_is_larger ? mant2 : mant1};
  // The general adder discards the smaller operand at the paper's cutoff.
  wire [MANT_WIDTH:0] aligned = gap >= MANT_WIDTH ? '0 : smaller >> gap;
  wire [MANT_WIDTH+1:0] sum = {1'b0, larger} + {1'b0, aligned};
  wire renormalize = sum[MANT_WIDTH+1];

  // Capture the exponent and fraction of the same sum on one edge.
  always @(posedge clk) begin
    exp <= larger_exp[EXP_WIDTH-1:0] + {{(EXP_WIDTH-1){1'b0}}, renormalize};
    mant <= renormalize ? sum[MANT_WIDTH:1] : sum[MANT_WIDTH-1:0];
  end
endmodule
