<!---
This file is used to generate your project datasheet.
-->

## How it works

A 2nd-order cascaded integrator-comb (CIC) decimator for the 1-bit output of a first-order switched-capacitor delta-sigma modulator
(the digital half of an open-source Sky130 delta-sigma ADC; the analog modulator is a separate design and is not in this tile).

- Input: one bit per clock on `ui[0]` (1 = high).
- Two integrators run at the clock rate, two combs at clock/128 (decimation ratio R = 128, 15-bit modular two's-complement words).
- Output: a 10-bit code (`CODE[9:0]` = the 15-bit CIC word divided by 16, saturated at 1023) on `uo[7:0]` and `uio[1:0]`, updated every 128 clocks. `uio[2]` (`CODE_VALID`) pulses for one clock when the code has just been updated.
- With the intended 1.024 MHz clock the output rate is 8 kS/s (4 kHz signal band). The design is synchronous, so it also works at any lower clock.

An all-ones input gives code 1023, all-zeros gives 0, and an alternating 0101... stream gives about 512. The Verilog is bit-exact against the Python model in `test/cic_model.py`.
The first two output codes after reset are the filter filling up and should be ignored.

## How to test

1. Hold `rst_n` low for a few clocks, then release it.
2. Drive a bitstream into `ui[0]`, one bit per clock edge, for example the 1-bit comparator output of a delta-sigma modulator, or a pattern from a microcontroller (a first-order sigma-delta of a constant gives a DC code).
3. Read `CODE[9:0]` when `CODE_VALID` pulses (or at any time: the code holds its value between updates).

The cocotb tests in `test/` check the pin mapping, compare every output code with the model for a sine delta-sigma bitstream, and check the DC levels.

## External hardware

None for the decimator alone. For a full ADC it needs a delta-sigma modulator driving `ui[0]` from a comparator output (the tile digital pins are 1.8 V, so a 3.3 V comparator output needs a level shifter or divider).
