# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# Define the write enable bit
WE = 1 << 7

@cocotb.test()
async def test_adder(dut):
  dut._log.info("Start")
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1

  # All the bidirectional ports are used for the data_in signal, so they should be inputs
  assert int(dut.uio_oe.value) == 0

  dut._log.info("write 4 bytes to addresses 8, 9, 10, 11")
  dut.ui_in.value = WE | 8
  dut.uio_in.value = 0x55
  await ClockCycles(dut.clk, 1)

  dut.ui_in.value = WE | 9 
  dut.uio_in.value = 0x66
  await ClockCycles(dut.clk, 1)

  dut.ui_in.value = WE | 10
  dut.uio_in.value = 0x77
  await ClockCycles(dut.clk, 1)

  dut.ui_in.value = WE | 11
  dut.uio_in.value = 0x88
  await ClockCycles(dut.clk, 1)

  dut._log.info("read back the bytes and verify they are correct")
  dut.uio_in.value = 0
  dut.ui_in.value = 8
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0x55

  dut.ui_in.value = 9
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0x66

  dut.ui_in.value = 10
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0x77

  dut.ui_in.value = 11
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0x88

  dut._log.info("write a byte at address 12")
  dut.ui_in.value = WE | 12
  dut.uio_in.value = 0x99
  await ClockCycles(dut.clk, 1)

  dut._log.info("overwrite the byte at address 10")
  dut.ui_in.value = WE | 10
  dut.uio_in.value = 0xaa
  await ClockCycles(dut.clk, 1)

  dut._log.info("read back the bytes and verify they are correct")
  dut.uio_in.value = 0
  dut.ui_in.value = 12
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0x99

  dut.ui_in.value = 10
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0xaa

  dut.ui_in.value = 8
  await ClockCycles(dut.clk, 2)
  assert int(dut.uo_out.value) == 0x55

  # Reset again
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1

  # Ensure that the memory is cleared
  for i in range(32):
    dut.ui_in.value = i
    await ClockCycles(dut.clk, 2)
    assert int(dut.uo_out.value) == 0

  dut._log.info("all good!")
