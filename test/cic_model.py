"""Bit-accurate model of src/cic2.v and the 10-bit wrapper (copy of model/cic_model.py of the ADC repository, without numpy)."""
def cic2(bits, log2r=7):
    R = 1 << log2r; W = 2 * log2r + 1; mask = (1 << W) - 1
    i1 = i2 = c1d = c2d = 0; out = []
    for n, b in enumerate(bits):
        i1 = (i1 + int(b)) & mask
        i2 = (i2 + i1) & mask
        if n % R == R - 1:
            c1 = (i2 - c1d) & mask; c2 = (c1 - c2d) & mask
            c1d, c2d = i2, c1
            out.append(c2)
    return out

def code10(w):
    return min(w >> 4, 1023)
