`default_nettype none

module tt_um_MichaelBell_latch_mem #(
    parameter RAM_BYTES = 64
) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  localparam addr_bits = $clog2(RAM_BYTES);
  assign uio_oe  = 8'b0;  // All bidirectional IOs are inputs
  assign uio_out = 8'b0;

  wire [addr_bits-1:0] addr_in = ui_in[addr_bits-1:0];
  reg  [addr_bits-1:0] addr_r;
  wire wr_en_in = ui_in[7];
  reg  wr_en_valid;
  reg  wr_en_ok;
  reg  [7:0] data_to_write;

  // Ensure stable inputs to the latches:
  // wr_en_valid is only high if addr_r is stable
  always @(posedge clk) begin
    addr_r <= addr_in;
    wr_en_valid <= wr_en_in && (addr_r == addr_in) && wr_en_ok;
    data_to_write <= uio_in;
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
    wire sel_byte = (addr_r == i);
    wire wr_en_this_byte = wr_en && sel_byte;
    always @(wr_en_this_byte or uio_in)
        if (wr_en_this_byte)
            RAM[i] <= data_to_write;

  end
  endgenerate

`ifdef SIM
  wire [7:0] result [(RAM_BYTES / 16)-1:0];
  wire [(RAM_BYTES / 16)-1:0] select;
`else
  wire [7:0] combined_out;
`endif

  generate
  for (i = 0; i < RAM_BYTES / 16; i = i+1) begin
    wire [addr_bits-1:4] high_addr = i;
    wire [7:0] selected_out = RAM[{high_addr, addr_r[3:0]}];
    reg partition_sel_n;
    always @(posedge clk) begin
      partition_sel_n <= addr_in[addr_bits-1:4] != high_addr;
    end 

`ifdef SIM
    assign result[i] = selected_out;
    assign select[i] = !partition_sel_n;
`else
    sky130_fd_sc_hd__ebufn_2 lm_dt_out_buf[7:0] ( .A(selected_out), .Z(combined_out), .TE_B(partition_sel_n) );
`endif
  end
  endgenerate

`ifdef SIM
  reg [7:0] out;
  always @(*) begin
    case (select)
    4'b0001: out = result[0];
    4'b0010: out = result[1];
    4'b0100: out = result[2];
    4'b1000: out = result[3];
    endcase
  end

  assign uo_out = out;
`else
  sky130_fd_sc_hd__clkbuf_4 lm_dt_wrapper_buf[7:0] (.A(combined_out), .X(uo_out));
`endif

endmodule  // tt_um_latch_mem
