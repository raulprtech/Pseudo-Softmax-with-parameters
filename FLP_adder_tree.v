`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.03.2023 12:35:07
// Design Name: 
// Module Name: FLP_adder_tree
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
`include "FLP_adder.v"
`include "First_stage_FLP_adder.v"

module FLP_adder_tree #(
  parameter NUM_INPUTS=10, parameter EXP_WIDTH=9, parameter MANT_WIDTH=8
) (
  input clk,
  input [NUM_INPUTS*MANT_WIDTH-1:0] input_bus,
  output [EXP_WIDTH-1:0] exp,
  output [MANT_WIDTH-1:0] mant
);

  localparam integer PAIRS = NUM_INPUTS / 2;
  localparam integer LEAVES = (NUM_INPUTS + 1) / 2;
  localparam integer NODES = 2 * LEAVES - 1;
  localparam integer WORD_WIDTH = EXP_WIDTH + MANT_WIDTH;

  wire [NODES*EXP_WIDTH-1:0] exp_bus;
  wire [NODES*MANT_WIDTH-1:0] mant_bus;

  function automatic integer depth(input integer node);
    integer current;
    begin
      // FIFO nodes are ordered by nondecreasing depth, so the right
      // child always has the maximum depth among the two children.
      current = node;
      depth = 0;
      while (current >= LEAVES) begin
        current = 2 * (current - LEAVES) + 1;
        depth = depth + 1;
      end
    end
  endfunction

  for (genvar i=0; i<PAIRS; i=i+1) begin : first_stage
    First_stage_FLP_adder #(.EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) adder_first (
      .clk(clk),
      .exp1(input_bus[2*i*MANT_WIDTH +: MANT_WIDTH]),
      .exp2(input_bus[(2*i+1)*MANT_WIDTH +: MANT_WIDTH]),
      .exp(exp_bus[i*EXP_WIDTH +: EXP_WIDTH]),
      .mant(mant_bus[i*MANT_WIDTH +: MANT_WIDTH])
    );
  end

  if (NUM_INPUTS % 2 != 0) begin : unpaired_logit
    assign exp_bus[PAIRS*EXP_WIDTH +: EXP_WIDTH] =
      $signed(input_bus[(NUM_INPUTS-1)*MANT_WIDTH +: MANT_WIDTH]);
    assign mant_bus[PAIRS*MANT_WIDTH +: MANT_WIDTH] = {MANT_WIDTH{1'b0}};
  end

  // Keep the FIFO pairing order. Delay only a child that arrives earlier.
  for (genvar i=0; i<LEAVES-1; i=i+1) begin : sum_stage
    localparam integer DEST = LEAVES + i;
    wire [WORD_WIDTH-1:0] child [0:1];

    for (genvar side=0; side<2; side=side+1) begin : align_child
      localparam integer SOURCE = 2*i + side;
      localparam integer WAIT = depth(DEST) - 1 - depth(SOURCE);
      wire [WORD_WIDTH-1:0] stage [0:WAIT];
      assign stage[0] = {exp_bus[SOURCE*EXP_WIDTH +: EXP_WIDTH],
                         mant_bus[SOURCE*MANT_WIDTH +: MANT_WIDTH]};
      for (genvar j=0; j<WAIT; j=j+1) begin : delay_stage
        reg [WORD_WIDTH-1:0] delayed;
        always @(posedge clk)
          delayed <= stage[j];
        assign stage[j+1] = delayed;
      end
      assign child[side] = stage[WAIT];
    end

    FLP_adder #(.EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) adder (
      .clk(clk),
      .exp1(child[0][WORD_WIDTH-1:MANT_WIDTH]),
      .exp2(child[1][WORD_WIDTH-1:MANT_WIDTH]),
      .mant1(child[0][MANT_WIDTH-1:0]),
      .mant2(child[1][MANT_WIDTH-1:0]),
      .exp(exp_bus[DEST*EXP_WIDTH +: EXP_WIDTH]),
      .mant(mant_bus[DEST*MANT_WIDTH +: MANT_WIDTH])
    );
  end

  assign exp = exp_bus[(NODES-1)*EXP_WIDTH +: EXP_WIDTH];
  assign mant = mant_bus[(NODES-1)*MANT_WIDTH +: MANT_WIDTH];
endmodule
