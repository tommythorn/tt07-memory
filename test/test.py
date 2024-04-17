import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

async def write(dut, addr, val):
  dut.addr.value = addr
  dut.data_in.value = random.randint(0, 255)
  dut.wr_en.value = 0
  await ClockCycles(dut.clk, 1)
  dut.data_in.value = val
  dut.wr_en.value = 1
  await ClockCycles(dut.clk, 1)
  dut.wr_en.value = 0

async def read(dut, addr):
  dut.addr.value = addr
  await ClockCycles(dut.clk, 1)
  dut.addr.value = random.randint(0, 63)
  await Timer(5, "ns")
  return dut.data_out.value

@cocotb.test()
async def test_basic(dut):
  dut._log.info("Start")

  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  await ClockCycles(dut.clk, 1)
  
  # Bidi IOs all used as inputs
  assert dut.uio_out.value == 0
  assert dut.uio_oe.value == 0
  
  dut._log.info("Write one")
  await write(dut, 0, 0xa5)
  await Timer(5, "ns")
  assert dut.data_out.value == 0xa5


@cocotb.test()
async def test_all(dut):
  dut._log.info("Start")

  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  await ClockCycles(dut.clk, 1)
  
  # Bidi IOs all used as inputs
  assert dut.uio_out.value == 0
  assert dut.uio_oe.value == 0
  
  dut._log.info("Write all locations")
  for i in range(64):
    await write(dut, i, i+5)
    await Timer(5, "ns")
    assert dut.data_out.value == i + 5

  dut._log.info("Read back")
  for i in range(64):
    assert await read(dut, i) == i + 5

@cocotb.test()
async def test_random(dut):
  dut._log.info("Start")

  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  await ClockCycles(dut.clk, 1)
  
  # Bidi IOs all used as inputs
  assert dut.uio_out.value == 0
  assert dut.uio_oe.value == 0
  
  dut._log.info("Fill memory")
  state = []
  for i in range(64):
    val = random.randint(0, 255)
    await write(dut, i, val)
    state.append(val)

  dut._log.info("Random reads and writes")
  for i in range(2000):
    addr = random.randint(0, 63)
    
    if random.randint(0, 1) == 0:
      # Write
      val = random.randint(0, 255)
      await write(dut, addr, val)
      state[addr] = val
      await Timer(5, "ns")
      assert dut.data_out.value == val
    
    else:
      # Read
      assert await read(dut, addr) == state[addr]
