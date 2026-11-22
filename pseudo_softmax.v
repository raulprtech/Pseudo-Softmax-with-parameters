`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2023 19:37:12
// Design Name: 
// Module Name: pseudo_softmax
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

`include "FLP_adder_tree.v"
`include "subtractors_array.v"
`include "reciprocal_pwl.v"

module pseudo_softmax #(parameter NUM_INPUTS=1, parameter EXP_WIDTH=4, parameter MANT_WIDTH=3)(
  input clk,
  input [NUM_INPUTS*MANT_WIDTH-1:0] input_bus,
  output [MANT_WIDTH-1:0] mant_out,
  output [NUM_INPUTS*EXP_WIDTH-1:0] exp_out
);

  // FIFO reduction over this many leaves has ceil(log2(leaves)) levels.
  localparam integer TREE_DEPTH = $clog2((NUM_INPUTS + 1) / 2);
  localparam integer INPUT_WIDTH = NUM_INPUTS * MANT_WIDTH;
  wire [EXP_WIDTH-1:0] exp_sum;
  wire [MANT_WIDTH-1:0] mant_sum;
  wire [NUM_INPUTS*EXP_WIDTH-1:0] exp_out_wire;
  reg [NUM_INPUTS*EXP_WIDTH-1:0] exp_aligned;

  wire [INPUT_WIDTH-1:0] logits_stage [0:TREE_DEPTH];
  wire [INPUT_WIDTH-1:0] root_logits = logits_stage[TREE_DEPTH];
  assign logits_stage[0] = input_bus;
  for (genvar i=0; i<TREE_DEPTH; i=i+1) begin : align_logits
    reg [INPUT_WIDTH-1:0] delayed;
    always @(posedge clk)
      delayed <= logits_stage[i];
    assign logits_stage[i+1] = delayed;
  end

  FLP_adder_tree #(.NUM_INPUTS(NUM_INPUTS), .EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) adder_tree (
    .clk(clk),
    .input_bus(input_bus),
    .exp(exp_sum),
    .mant(mant_sum)
  );

  subtractors_array #(.NUM_INPUTS(NUM_INPUTS), .EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) subtractors (
    .input_bus(root_logits),
    .exp_sum(exp_sum),
    .exp_out(exp_out_wire)
  );

  reciprocal_pwl #(.MANT_WIDTH(MANT_WIDTH)) pwl (
    .clk(clk),
    .in(mant_sum),
    .out(mant_out)
  );

  // Both outputs describe the same root transaction after this edge.
  always @(posedge clk)
    exp_aligned <= exp_out_wire;
  assign exp_out = exp_aligned;
endmodule
