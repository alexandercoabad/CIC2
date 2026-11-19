// 10-bit output code from the CIC word: dout/16 saturated to 0..1023 (R*R/16 = 1024 -> 1023).
module cic_adc_out (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din,      // bitstream from the modulator comparator (1 = high)
    output reg  [9:0]  code,
    output reg         code_valid        // pulses in the cycle in which code holds the new value
);
    /* verilator lint_off UNUSEDSIGNAL */
    wire [14:0] w;                  // w[3:0] are dropped on purpose (code = w >> 4)
    /* verilator lint_on UNUSEDSIGNAL */
    wire        v;
    cic2 #(.LOG2R(7)) u_cic (.clk(clk), .rst_n(rst_n), .din(din), .dout(w), .dvalid(v));
    always @(posedge clk) begin
        if (!rst_n) begin code <= 10'd0; code_valid <= 1'b0; end
        else begin
            code_valid <= v;
            if (v) code <= (w[14:4] > 11'd1023) ? 10'd1023 : w[13:4];
        end
    end
endmodule
