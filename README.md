# Parameterized Pseudo-Softmax RTL

This implementation approximates base-2 softmax. The top module is
`pseudo_softmax` in `pseudo_softmax.v`; compile that file rather than globbing
all the included sources. For example, elaborate the ten-input INT8 configuration:

```sh
iverilog -g2012 -s pseudo_softmax -Ppseudo_softmax.NUM_INPUTS=10 \
  -Ppseudo_softmax.MANT_WIDTH=8 -Ppseudo_softmax.EXP_WIDTH=10 \
  -o pseudo_softmax.vvp pseudo_softmax.v
verilator --lint-only --Wno-fatal --top-module pseudo_softmax \
  -GNUM_INPUTS=10 -GMANT_WIDTH=8 -GEXP_WIDTH=10 pseudo_softmax.v
```

## Interface and timing

- Parameters retain their positional order and defaults:
  `NUM_INPUTS=1, EXP_WIDTH=4, MANT_WIDTH=3`.
- With N inputs, W mantissa bits and E exponent bits, `input_bus` has N×W
  bits and `exp_out` has N×E bits. Both use signed two's-complement lanes,
  with lane 0 in the least significant bits. The shared `mant_out` is unsigned
  Q0.W. Decode lane i as (mant_out / 2^W) × 2^(signed exponent i).
- The mantissa and exponent outputs now describe the **same input vector**.
  A vector sampled at rising edge k is available after edge k+D, where
  D = ceil(log2(ceil(N/2))). For N=10 this is the fourth rising edge when
  counting capture as the first. A new vector may be sampled every cycle.
  There is no reset or valid port; ignore outputs before the first result.
- Choose E so both the tree exponents and signed output differences fit.
  The RTL does not flag overflow; values outside range wrap. For signed INT8
  with N=1…127, E=10 covers the output range [−261, 0]. With E=9,
  −257 appears as +255. E=10 uses the existing parameter, changes the
  output bus width, and is not the paper's output format.

Icarus 12.0 and Verilator 5.032 were tested across N=1…127 with INT8.
Verilator diagnostics remain; its `-O0` C++ build is not validated and failed
in testing. Use normal optimization settings. These are RTL and simulation
checks, not a reproduction of the article's Fig. 5 or its physical results.

Reference: [Cardarilli et al., 2021](https://doi.org/10.1038/s41598-021-94691-7).
