// fifo_axi.v
module fifo_axi #(
    parameter DATA_WIDTH = 32,  // Data width
    parameter ADDR_WIDTH = 4    // FIFO depth: DEPTH = 2^ADDR_WIDTH
)(
    input  wire                  clk,    // Clock (to be connected to PCIE_CLK)
    input  wire                  rst_n,  // Active low reset (connected to pcie_rstn)
    // Write interface
    input  wire [DATA_WIDTH-1:0] din,    // Data input
    input  wire                  wr_en,  // Write enable
    output wire                  full,   // FIFO full flag
    // Read interface
    output wire [DATA_WIDTH-1:0] dout,   // Data output
    input  wire                  rd_en,  // Read enable
    output wire                  empty   // FIFO empty flag
);

  localparam DEPTH = (1 << ADDR_WIDTH);

  reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
  reg [ADDR_WIDTH:0] wr_ptr; 
  reg [ADDR_WIDTH:0] rd_ptr;

  wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
  wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

  assign empty = (wr_ptr == rd_ptr);
  assign full  = ((wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                  (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]));
  assign dout = fifo_mem[rd_addr];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (wr_en && !full) begin
        fifo_mem[wr_addr] <= din;
        wr_ptr <= wr_ptr + 1;
      end
      if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

endmodule
