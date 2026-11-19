/*
 * Copyright (c) 2026
 * SPDX-License-Identifier: Apache-2.0
 *
 * CIC2 decimator for a 1-bit delta-sigma bitstream (R = 128, 15-bit word, 10-bit output code).
 * ui_in[0]    : bitstream input (1 = high), sampled on every rising clock edge
 * uo_out[7:0] : code[7:0]
 * uio_out[1:0]: code[9:8]     uio_out[2]: code_valid (one-clock pulse when `code` has just been updated, fclk/128)
 */

`default_nettype none

module tt_um_cic2_decimator (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [9:0] code;
  wire       code_valid;

  cic_adc_out u_dec (
      .clk       (clk),
      .rst_n     (rst_n),
      .din       (ui_in[0]),
      .code      (code),
      .code_valid(code_valid)
  );

  assign uo_out  = code[7:0];
  assign uio_out = {5'b00000, code_valid, code[9:8]};
  assign uio_oe  = 8'b00000111;   // uio[2:0] are outputs, uio[7:3] are unused inputs

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
