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
  dut._log.info("all good!")
