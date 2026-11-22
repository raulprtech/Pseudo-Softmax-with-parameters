`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2023 13:51:52
// Design Name: 
// Module Name: subtractors_array
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


module subtractors_array #(
  parameter NUM_INPUTS = 10,
  parameter EXP_WIDTH = 9,
  parameter MANT_WIDTH = 8
)(
  input [EXP_WIDTH-1:0] exp_sum,
  input [NUM_INPUTS*MANT_WIDTH-1:0] input_bus,
  output [NUM_INPUTS*EXP_WIDTH-1:0] exp_out

);

  localparam DIFF_WIDTH = ((EXP_WIDTH > MANT_WIDTH) ? EXP_WIDTH : MANT_WIDTH) + 1;
  wire signed [DIFF_WIDTH-1:0] sum_exponent = $signed(exp_sum);

  genvar i;
  generate
    for (i = 0; i < NUM_INPUTS; i = i + 1) begin : lane
      wire signed [DIFF_WIDTH-1:0] logit = $signed(input_bus[i*MANT_WIDTH +: MANT_WIDTH]);
      wire signed [DIFF_WIDTH-1:0] difference = logit - sum_exponent;

      // Keep the existing exponent field width and its low-bit encoding.
      assign exp_out[i*EXP_WIDTH +: EXP_WIDTH] = difference[EXP_WIDTH-1:0];
    end
  endgenerate

endmodule
