
module sreg
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [2:0] awaddr,
    input   wire [2:0] awprot,
    input   wire wvalid,
    output  wire wready,
    input   wire [31:0] wdata,
    input   wire [3:0] wstrb,
    output  wire bvalid,
    input   wire bready,
    output  wire [1:0] bresp,
    input   wire arvalid,
    output  wire arready,
    input   wire [2:0] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // REG areg
    output  wire [31:0] areg_o,

    // REG breg
    output  wire [31:0] breg_o
  );
  reg wr_req;
  reg wr_ack;
  reg [2:2] wr_addr;
  reg [31:0] wr_data;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [2:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg [31:0] areg_reg;
  reg areg_wreq;
  reg areg_wack;
  reg [31:0] breg_reg;
  reg breg_wreq;
  reg breg_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // AW, W and B channels
  assign awready = ~axi_awset;
  assign wready = ~axi_wset;
  assign bvalid = axi_wdone;
  always @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        wr_req <= 1'b0;
        axi_awset <= 1'b0;
        axi_wset <= 1'b0;
        axi_wdone <= 1'b0;
      end
    else
      begin
        wr_req <= 1'b0;
        if (awvalid == 1'b1 & axi_awset == 1'b0)
          begin
            wr_addr <= awaddr[2:2];
            axi_awset <= 1'b1;
            wr_req <= axi_wset;
          end
        if (wvalid == 1'b1 & axi_wset == 1'b0)
          begin
            wr_data <= wdata;
            axi_wset <= 1'b1;
            wr_req <= axi_awset | awvalid;
          end
        if ((axi_wdone & bready) == 1'b1)
          begin
            axi_wset <= 1'b0;
            axi_awset <= 1'b0;
            axi_wdone <= 1'b0;
          end
        if (wr_ack == 1'b1)
          axi_wdone <= 1'b1;
      end
  end
  assign bresp = 2'b00;

  // AR and R channels
  assign arready = ~axi_arset;
  assign rvalid = axi_rdone;
  always @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        axi_rdone <= 1'b0;
        rdata <= 32'b0;
      end
    else
      begin
        rd_req <= 1'b0;
        if (arvalid == 1'b1 & axi_arset == 1'b0)
          begin
            rd_addr <= araddr[2:2];
            axi_arset <= 1'b1;
            rd_req <= 1'b1;
          end
        if ((axi_rdone & rready) == 1'b1)
          begin
            axi_arset <= 1'b0;
            axi_rdone <= 1'b0;
          end
        if (rd_ack == 1'b1)
          begin
            axi_rdone <= 1'b1;
            rdata <= rd_data;
          end
      end
  end
  assign rresp = 2'b00;

  // pipelining for wr-in+rd-out
  always @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_ack <= 1'b0;
        rd_data <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 1'b0;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end
  end

  // Register areg
  assign areg_o = areg_reg;
  always @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        areg_reg <= 32'b00000000000000000000000000000000;
        areg_wack <= 1'b0;
      end
    else
      begin
        if (areg_wreq == 1'b1)
          areg_reg <= wr_dat_d0;
        areg_wack <= areg_wreq;
      end
  end

  // Register breg
  assign breg_o = breg_reg;
  always @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        breg_reg <= 32'b00000000000000000000000000000000;
        breg_wack <= 1'b0;
      end
    else
      begin
        if (breg_wreq == 1'b1)
          breg_reg <= wr_dat_d0;
        breg_wack <= breg_wreq;
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, areg_wack, breg_wack)
  begin
    areg_wreq = 1'b0;
    breg_wreq = 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      begin
        // Reg areg
        areg_wreq = wr_req_d0;
        wr_ack = areg_wack;
      end
    1'b1:
      begin
        // Reg breg
        breg_wreq = wr_req_d0;
        wr_ack = breg_wack;
      end
    default:
      wr_ack = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(rd_addr, rd_req, areg_reg, breg_reg)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (rd_addr[2:2])
    1'b0:
      begin
        // Reg areg
        rd_ack_d0 = rd_req;
        rd_dat_d0 = areg_reg;
      end
    1'b1:
      begin
        // Reg breg
        rd_ack_d0 = rd_req;
        rd_dat_d0 = breg_reg;
      end
    default:
      rd_ack_d0 = rd_req;
    endcase
  end
endmodule
