## How it works

It uses 512 latches to implement a 64 byte RAM.
Resetting the project does not reset the RAM contents.

## How to test

To write:
- Set the `addr` pins to the desired address and set `wr_en` low
- Pulse `clk`
- Keep the `addr` pins set, set `data_in` (the bidirectional pins) to the desired value, set `wr_en` high
- Pulse `clk`
- The memory location is now written.
- Note the next cycle must have `wr_en` low.

To read:
- Set the `addr` pins to the desired address and set `wr_en` low
- Pulse `clk`
- `data_out` (the output pins) reads the value at the memory location.
