// axi_pcie_fifo_accel.v
module axi_pcie_fifo_accel #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 4,
    parameter ADDR_LSB    = 2      // Assuming word-aligned addresses
)(
    // AXI-Lite slave interface ports
    input  wire         s_axi_aclk,     // System clock (connect to PCIE_CLK)
    input  wire         s_axi_aresetn,  // Active low reset (connect to pcie_rstn)
    // Write address channel
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    // Write data channel
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    // Write response channel
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    // Read address channel
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    // Read data channel
    output reg [31:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready
);

  // Internal FIFO control signals
  wire fifo_full;
  wire fifo_empty;
  wire [DATA_WIDTH-1:0] fifo_dout;
  reg  [DATA_WIDTH-1:0] fifo_din;
  reg fifo_wr_en, fifo_rd_en;

  // Instantiate the FIFO module
  fifo_axi #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) fifo_inst (
      .clk(s_axi_aclk),
      .rst_n(s_axi_aresetn),
      .din(fifo_din),
      .wr_en(fifo_wr_en),
      .full(fifo_full),
      .dout(fifo_dout),
      .rd_en(fifo_rd_en),
      .empty(fifo_empty)
  );

  // Address map:
  // 0x00 : FIFO write register (write-only)
  // 0x04 : FIFO read register (read-only)
  // 0x08 : Status register [bit0: empty, bit1: full]

  // ==========================
  // Write Channel Implementation
  // ==========================
  reg [31:0] axi_awaddr_reg;
  reg        write_active;
  
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_awready   <= 0;
      s_axi_wready    <= 0;
      write_active    <= 0;
      axi_awaddr_reg  <= 32'd0;
    end else begin
      // Latch address when both AW and W are valid and not busy
      if (!write_active && s_axi_awvalid && s_axi_wvalid) begin
        axi_awaddr_reg <= s_axi_awaddr;
        s_axi_awready  <= 1;
        s_axi_wready   <= 1;
        write_active   <= 1;
      end else begin
        s_axi_awready  <= 0;
        s_axi_wready   <= 0;
      end
      
      if (write_active) begin
        case (axi_awaddr_reg[ADDR_LSB+1:ADDR_LSB])
          2'b00: begin
            // Write to FIFO register
            if (!fifo_full) begin
              fifo_din  <= s_axi_wdata;
              fifo_wr_en <= 1;
            end else begin
              fifo_wr_en <= 0;
            end
          end
          default: begin
            fifo_wr_en <= 0;
          end
        endcase
      end else begin
        fifo_wr_en <= 0;
      end
      
      // Write response (assume OKAY response)
      if (write_active) begin
        s_axi_bresp  <= 2'b00;
        s_axi_bvalid <= 1;
        write_active <= 0;  // Clear active transaction
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 0;
      end
    end
  end

  // ==========================
  // Read Channel Implementation
  // ==========================
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 0;
      s_axi_rvalid  <= 0;
      s_axi_rresp   <= 2'b00;
      fifo_rd_en    <= 0;
      s_axi_rdata   <= 32'd0;
    end else begin
      if (s_axi_arvalid && !s_axi_arready) begin
        s_axi_arready <= 1;
      end else begin
        s_axi_arready <= 0;
      end

      if (s_axi_arready && s_axi_arvalid) begin
        // Handle read based on address
        case (s_axi_araddr[ADDR_LSB+1:ADDR_LSB])
          2'b01: begin
            // Read from FIFO
            if (!fifo_empty) begin
              fifo_rd_en  <= 1;
              s_axi_rdata <= fifo_dout;
            end else begin
              fifo_rd_en  <= 0;
              s_axi_rdata <= 32'hDEAD_DEAD; // Return an error value if FIFO is empty
            end
          end
          2'b10: begin
            // Status register: bit0 = empty, bit1 = full
            s_axi_rdata <= {30'd0, fifo_full, fifo_empty};
          end
          default: begin
            s_axi_rdata <= 32'd0;
          end
        endcase
        s_axi_rresp  <= 2'b00;  // OKAY
        s_axi_rvalid <= 1;
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 0;
        fifo_rd_en   <= 0;
      end
    end
  end

endmodule
