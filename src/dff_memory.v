`default_nettype none

module tt_um_urish_256_bits_dff_mem #(
    parameter RAM_BYTES = 32
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

  wire [addr_bits-1:0] addr = ui_in[addr_bits-1:0];
  wire wr_en = ui_in[7];
  assign uio_oe  = 8'b0;  // All bidirectional IOs are inputs
  assign uio_out = 8'b0;

  reg [7:0] RAM[RAM_BYTES - 1:0];

  genvar i;
  generate
  for (i = 0; i < RAM_BYTES; i = i+1) begin
    wire sel_byte = (addr == i);
    wire wr_en_this_byte = wr_en && sel_byte;
    always @(wr_en_this_byte or uio_in)
        if (wr_en_this_byte)
            RAM[i] <= uio_in;
  end
  endgenerate

/*
    sky130_fd_sc_hd__dlxtp_1 latch[WIDTH-1:0] (
        .Q(data),
        .D(data_in_buf),
        .RESET_B(reset_n),
        .GATE(empty)
    );
*/

  assign uo_out = RAM[addr];

endmodule  // tt_um_urish_256_bits_dff_mem
