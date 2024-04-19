`default_nettype none

module tt_um_MichaelBell_latch_mem #(
    parameter RAM_BYTES = 64
) (
/*verilator lint_off UNUSEDSIGNAL*/
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
/*verilator lint_on UNUSEDSIGNAL*/
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
/*verilator lint_off UNUSEDSIGNAL*/
    input  wire       ena,      // will go high when the design is enabled
/*verilator lint_on UNUSEDSIGNAL*/
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  localparam addr_bits = $clog2(RAM_BYTES);
  assign uio_oe  = 8'b0;  // All bidirectional IOs are inputs
  assign uio_out = 8'b0;

  wire [addr_bits-1:0] addr_in = ui_in[addr_bits-1:0];
  reg  [3:0] addr_read;
  reg  [addr_bits-1:0] addr_write;
  wire wr_en_in = ui_in[7];
  reg  wr_en_next;
  reg  wr_en_valid;
  reg  wr_en_ok;
  reg  [7:0] data_to_write;

  // Writing: Ensuring stable inputs to the latches.
  //
  // The write address, addr_write, is always set to the same value for 2 clocks when doing a write.
  // When the write is requested addr_write and data_to_write are captured.  wr_en_next is set high.
  // If wr_en_next was already high the write is ignored, so the inputs to the latches aren't 
  // modified when a write is about to happen.
  //
  // On the next clock, wr_en_valid is set to wr_en_next.  addr_write is stable at this time so the
  // sel_byte wires will already be stable at the point wr_en_valid goes high.
  //
  // wr_en_ok is a negative edge triggered flop that is set to !wr_en_valid.  This will therefore
  // go low half a clock after wr_en_valid is set high.  And because two consecutive writes are not
  // allowed it will always be high when wr_en_valid goes high.
  // 
  // The latch gate is set by anding together wr_en_valid, wr_en_ok and the sel_byte for that byte.
  // This means the latch gate for just the selected byte's latches goes high for the first half of
  // the write clock cycle.  data_to_write is stable across this time (it can not change until the
  // next clock rising edge), so will be cleanly captured by the latch when the latch gate goes low.
  wire wr_en_in_valid = wr_en_in && !wr_en_next;
  always @(posedge clk) begin
    if (!rst_n) begin
      wr_en_next <= 0;
      wr_en_valid <= 0;
    end else begin
      wr_en_next <= wr_en_in_valid;
      wr_en_valid <= wr_en_next;
    end
    addr_read <= addr_in[3:0];
    if (wr_en_in_valid) begin
      addr_write <= addr_in;
      data_to_write <= uio_in;
    end
  end

  always @(negedge clk) begin
    wr_en_ok <= !wr_en_valid;
  end

  reg [7:0] RAM[RAM_BYTES - 1:0];

  // wr_en is high only for the first half of the clock cycle, 
  // and when addr_r is the same as on last cycle, so sel_byte is stable.
  wire wr_en = wr_en_valid && wr_en_ok;

  genvar i;
  generate
  for (i = 0; i < RAM_BYTES; i = i+1) begin
    wire sel_byte = (addr_write == i);
    wire wr_en_this_byte;
`ifdef SIM    
    assign wr_en_this_byte = wr_en && sel_byte;
`else
    // Use an explicit and gate to minimize possibility of a glitch
    (* keep *) sky130_fd_sc_hd__and2_1 lm_gate ( .A(wr_en), .B(sel_byte), .X(wr_en_this_byte) );
`endif
    always @(wr_en_this_byte or uio_in)
        if (wr_en_this_byte)
            RAM[i] <= data_to_write;

  end
  endgenerate


  // Reading:  Mux and tri-state buffer.
  //
  // Reading the latches is straightforward.  However, a 64:1 mux for each bit is relatively area 
  // intensive so instead we have 4 16:1 muxes feeding 4 tri-state buffers.
  // Only the tri-state buffer corresponding to the selected read address is enabled, and the output is
  // taken from the wire driven by those 4 buffers.
  //
  // To minimize contention, the tri-state enable pin of the buffers is driven directly from a flop which
  // captures the selected read address directly from the inputs, at the same cycle as the addr_read flops 
  // are set.
  //
  // The combined output wire then goes to a final buffer before leaving the module, ensuring the outputs 
  // are driven cleanly.
  wire [7:0] combined_out;

  generate
  for (i = 0; i < RAM_BYTES / 16; i = i+1) begin
    wire [addr_bits-1:4] high_addr = i;
    wire [7:0] selected_out = RAM[{high_addr, addr_read}];
    reg partition_sel_n;
    always @(posedge clk) begin
      partition_sel_n <= addr_in[addr_bits-1:4] != high_addr;
    end 

`ifdef SIM
    bufif0 out_buf[7:0] (combined_out, selected_out, partition_sel_n);
`else
    sky130_fd_sc_hd__ebufn_4 lm_dt_out_buf[7:0] ( .A(selected_out), .Z(combined_out), .TE_B(partition_sel_n) );
`endif
  end
  endgenerate

`ifdef SIM
  buf final_buf[7:0] (uo_out, combined_out);
`else
  sky130_fd_sc_hd__clkbuf_4 lm_dt_final_buf[7:0] (.A(combined_out), .X(uo_out));
`endif

endmodule  // tt_um_latch_mem
