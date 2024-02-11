## How it works

It uses 256 DFFs to implement 32 byte RAM.
Reseting the project does not reset the RAM contents.

## How to test

Set the `addr` pins to the desired address, and set the `in` pins to the desired value. 
Then, set the `wr_en` pin to `1` to write the value to the RAM, or set it to `0` to read 
the value from the RAM, and pulse `clk`.
