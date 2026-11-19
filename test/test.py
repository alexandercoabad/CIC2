# SPDX-License-Identifier: Apache-2.0
# Tests of the CIC2 decimator wrapper against the bit-accurate Python model (cic_model.py).
import math
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge
import cic_model

R = 128


def dsm_bits(n, amp=0.5, cycles=3):
    """first-order delta-sigma bitstream of a sine (deterministic, integer-free but reproducible): amp = fraction of full scale"""
    bits = []; integ = 0.0; fb = 0.0
    for k in range(n):
        x = amp * math.sin(2 * math.pi * cycles * k / n)   # -1 .. +1
        integ += x - fb
        b = 1 if integ >= 0 else 0
        fb = 1.0 if b else -1.0
        bits.append(b)
    return bits


async def start(dut):
    cocotb.start_soon(Clock(dut.clk, 976, unit="ns").start())   # about 1.024 MHz
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1


def read_code(dut):
    return int(dut.uo_out.value) | ((int(dut.uio_out.value) & 0x3) << 8)


async def run_bits(dut, bits):
    """drive one bit per clock (changing at the falling edge), return the codes seen whenever code_valid pulses"""
    seen = []
    for b in bits:
        dut.ui_in.value = b
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        if (int(dut.uio_out.value) >> 2) & 1:
            seen.append(read_code(dut))
    return seen


@cocotb.test()
async def test_pins(dut):
    await start(dut)
    assert int(dut.uio_oe.value) == 0x07, "uio[2:0] must be outputs"
    assert (int(dut.uio_out.value) & 0xF8) == 0, "unused uio outputs must be 0"


@cocotb.test()
async def test_against_model(dut):
    """sine delta-sigma bitstream: every code the chip produces equals the model"""
    await start(dut)
    bits = dsm_bits(2048)
    exp = [cic_model.code10(w) for w in cic_model.cic2(bits)]
    seen = await run_bits(dut, bits)
    dut._log.info(f"{len(seen)} codes, first {seen[:6]}, model {exp[:6]}")
    assert len(seen) >= len(exp) - 1
    assert seen == exp[:len(seen)]
    assert max(seen[3:]) > 700 and min(seen[3:]) < 330, "the decimated sine should swing around mid-scale"


@cocotb.test()
async def test_dc_levels(dut):
    """all-ones saturates at 1023, all-zeros gives 0, 0101... gives mid-scale"""
    await start(dut)
    seen = await run_bits(dut, [1] * (6 * R))
    assert seen[-1] == 1023, seen
    seen = await run_bits(dut, [0] * (6 * R))
    assert seen[-1] == 0, seen
    seen = await run_bits(dut, [k & 1 for k in range(8 * R)])
    assert abs(seen[-1] - 512) <= 2, seen
