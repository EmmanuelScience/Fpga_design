// accelerator_mod.sv  – minimal top that the Shell instantiates
module accelerator_mod #(
   parameter DATA_W = 32,
   parameter ADDR_W = 4
)(
   //----------------------------------------------------------
   // Shell ⇄ PCIe AXI‑Lite Slave (named pcie_axi in CSV)
   //----------------------------------------------------------
   input  wire            pcie_clk,          // PCIE_CLK domain
   input  wire            pcie_rstn,

   // AXI‑Lite Slave
   input  wire [31:0]     pcie_axi_awaddr,
   input  wire            pcie_axi_awvalid,
   output wire            pcie_axi_awready,
   input  wire [31:0]     pcie_axi_wdata,
   input  wire [3:0]      pcie_axi_wstrb,
   input  wire            pcie_axi_wvalid,
   output wire            pcie_axi_wready,
   output wire [1:0]      pcie_axi_bresp,
   output wire            pcie_axi_bvalid,
   input  wire            pcie_axi_bready,
   input  wire [31:0]     pcie_axi_araddr,
   input  wire            pcie_axi_arvalid,
   output wire            pcie_axi_arready,
   output wire [31:0]     pcie_axi_rdata,
   output wire [1:0]      pcie_axi_rresp,
   output wire            pcie_axi_rvalid,
   input  wire            pcie_axi_rready
);

   //-----------------------------------------------------------------
   // Instantiate the real accelerator  (AXI‑to‑FIFO wrapper)
   //-----------------------------------------------------------------
   axi_pcie_fifo_accel #(
      .DATA_WIDTH (DATA_W),
      .ADDR_WIDTH (ADDR_W)
   ) u_fifo_accel (
      .s_axi_aclk   (pcie_clk),
      .s_axi_aresetn(pcie_rstn),
      // AXI‑Lite ports 1‑to‑1
      .s_axi_awaddr (pcie_axi_awaddr),
      .s_axi_awvalid(pcie_axi_awvalid),
      .s_axi_awready(pcie_axi_awready),
      .s_axi_wdata  (pcie_axi_wdata),
      .s_axi_wstrb  (pcie_axi_wstrb),
      .s_axi_wvalid (pcie_axi_wvalid),
      .s_axi_wready (pcie_axi_wready),
      .s_axi_bresp  (pcie_axi_bresp),
      .s_axi_bvalid (pcie_axi_bvalid),
      .s_axi_bready (pcie_axi_bready),
      .s_axi_araddr (pcie_axi_araddr),
      .s_axi_arvalid(pcie_axi_arvalid),
      .s_axi_arready(pcie_axi_arready),
      .s_axi_rdata  (pcie_axi_rdata),
      .s_axi_rresp  (pcie_axi_rresp),
      .s_axi_rvalid (pcie_axi_rvalid),
      .s_axi_rready (pcie_axi_rready)
   );

endmodule
