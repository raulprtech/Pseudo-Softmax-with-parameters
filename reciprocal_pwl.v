`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2023 16:42:26
// Design Name: 
// Module Name: reciprocal_pwl
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
module reciprocal_pwl #(parameter MANT_WIDTH = 8)(
  input clk,
  input [MANT_WIDTH-1:0] in,
  output [MANT_WIDTH-1:0] out
);
  // The input represents 1.in. Four guard bits keep every shift exact.
  localparam [MANT_WIDTH+4:0] ONE = {1'b1, {(MANT_WIDTH+4){1'b0}}};
  localparam [MANT_WIDTH+4:0] LOW_INTERCEPT =
    ONE + (ONE >> 1) + (ONE >> 4) + (ONE >> 5);  // 51/32
  localparam [MANT_WIDTH+4:0] HIGH_INTERCEPT = ONE + (ONE >> 3);  // 9/8

  wire [MANT_WIDTH+4:0] mantissa = {1'b1, in, 4'b0000};
  reg signal_1bit;
  reg [MANT_WIDTH+4:0] shifted_value1;
  reg [MANT_WIDTH+4:0] shifted_value2;
  reg [MANT_WIDTH+4:0] shifted_value3;
  reg [MANT_WIDTH+4:0] shifted_value4;

  always @(posedge clk) begin
    signal_1bit <= in[MANT_WIDTH-1];
    shifted_value1 <= mantissa >> 1;
    shifted_value2 <= mantissa >> 3;
    shifted_value3 <= mantissa >> 2;
    shifted_value4 <= mantissa >> 4;
  end

  wire [MANT_WIDTH+4:0] sum1 = LOW_INTERCEPT - shifted_value1 - shifted_value2;
  wire [MANT_WIDTH+4:0] sum2 = HIGH_INTERCEPT - shifted_value3 - shifted_value4;
  wire [MANT_WIDTH+4:0] selected_sum = signal_1bit ? sum2 : sum1;

  // Both selected polynomials return less than one. Quantize once to Q0.W.
  assign out = selected_sum[MANT_WIDTH+3:4];
endmodule
