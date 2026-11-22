
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2023 13:14:34
// Design Name: 
// Module Name: 1st_stage_FLP_adder
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

module First_stage_FLP_adder #(
  parameter EXP_WIDTH=9, parameter MANT_WIDTH=8
) (
  input clk,
  input signed [MANT_WIDTH-1:0] exp1,
  input signed [MANT_WIDTH-1:0] exp2,
  output signed [EXP_WIDTH-1:0] exp,
  output [MANT_WIDTH-1:0] mant
);

  localparam [MANT_WIDTH:0] ONE = {1'b1, {MANT_WIDTH{1'b0}}};
  wire exp1_is_larger = exp1 >= exp2;
  wire signed [MANT_WIDTH:0] max_exp = exp1_is_larger ? exp1 : exp2;
  wire signed [MANT_WIDTH:0] min_exp = exp1_is_larger ? exp2 : exp1;
  // One extra bit holds the difference of the two signed input extremes.
  wire [MANT_WIDTH:0] gap = max_exp - min_exp;
  wire [MANT_WIDTH:0] aligned_one = ONE >> gap;
  wire same_exp = exp1 == exp2;

  // On a tie, 1.0 + 1.0 normalizes to 1.0 at the next exponent.
  // Otherwise only the aligned operand contributes fractional bits.
  assign exp = max_exp + $signed({1'b0, same_exp});
  assign mant = aligned_one[MANT_WIDTH-1:0];
endmodule
