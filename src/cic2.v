// 2nd-order CIC decimator for a 1-bit delta-sigma bitstream.
// Hogenauer register width: Bmax = Bin + N*log2(R) = 1 + 2*7 = 15 bits (R = 128, N = 2),
// the same 15-bit word length as the thesis design (Abad, DLSU 2011, Sec. 5.9).
// din: 1-bit modulator output, 1 = high. Integrators/combs use modular two's-complement
// arithmetic, so overflow of the integrators is harmless as long as the final word fits W bits.
// dout = sum of the last 2R-1 input bits weighted by the triangular CIC impulse response,
// range 0 .. R*R (R*R = 16384 for an all-ones input). Valid once the first 2 outputs are flushed.
module cic2 #(
    parameter LOG2R = 7,                 // R = 2**LOG2R
    parameter W     = 2*LOG2R + 1        // register width (15 for R = 128)
) (
    input  wire         clk,
    input  wire         rst_n,           // active-low synchronous reset
    input  wire         din,
    output reg  [W-1:0] dout,
    output reg          dvalid           // one-clock pulse when dout is updated (fclk/R)
);
    reg [W-1:0]      i1, i2;             // integrators (run at fclk)
    reg [W-1:0]      c1_d, c2_d;         // comb delays (run at fclk/R)
    reg [LOG2R-1:0]  cnt;
    wire             tick = (cnt == {LOG2R{1'b1}});
    wire [W-1:0]     i1_n = i1 + {{(W-1){1'b0}}, din};
    wire [W-1:0]     i2_n = i2 + i1_n;   // non-delaying cascade
    wire [W-1:0]     c1   = i2_n - c1_d;
    wire [W-1:0]     c2   = c1   - c2_d;

    always @(posedge clk) begin
        if (!rst_n) begin
            i1 <= 0; i2 <= 0; c1_d <= 0; c2_d <= 0; cnt <= 0; dout <= 0; dvalid <= 1'b0;
        end else begin
            i1  <= i1_n;
            i2  <= i2_n;
            cnt <= cnt + 1'b1;
            dvalid <= tick;
            if (tick) begin
                c1_d <= i2_n;
                c2_d <= c1;
                dout <= c2;
            end
        end
    end
endmodule
