library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sps200CavityControl_regs is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(20 downto 2);
    awprot               : in    std_logic_vector(2 downto 0);
    wvalid               : in    std_logic;
    wready               : out   std_logic;
    wdata                : in    std_logic_vector(31 downto 0);
    wstrb                : in    std_logic_vector(3 downto 0);
    bvalid               : out   std_logic;
    bready               : in    std_logic;
    bresp                : out   std_logic_vector(1 downto 0);
    arvalid              : in    std_logic;
    arready              : out   std_logic;
    araddr               : in    std_logic_vector(20 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- AXI-4 lite bus hwInfo
    hwInfo_awvalid_o     : out   std_logic;
    hwInfo_awready_i     : in    std_logic;
    hwInfo_awaddr_o      : out   std_logic_vector(4 downto 0);
    hwInfo_awprot_o      : out   std_logic_vector(2 downto 0);
    hwInfo_wvalid_o      : out   std_logic;
    hwInfo_wready_i      : in    std_logic;
    hwInfo_wdata_o       : out   std_logic_vector(31 downto 0);
    hwInfo_wstrb_o       : out   std_logic_vector(3 downto 0);
    hwInfo_bvalid_i      : in    std_logic;
    hwInfo_bready_o      : out   std_logic;
    hwInfo_bresp_i       : in    std_logic_vector(1 downto 0);
    hwInfo_arvalid_o     : out   std_logic;
    hwInfo_arready_i     : in    std_logic;
    hwInfo_araddr_o      : out   std_logic_vector(4 downto 0);
    hwInfo_arprot_o      : out   std_logic_vector(2 downto 0);
    hwInfo_rvalid_i      : in    std_logic;
    hwInfo_rready_o      : out   std_logic;
    hwInfo_rdata_i       : in    std_logic_vector(31 downto 0);
    hwInfo_rresp_i       : in    std_logic_vector(1 downto 0);

    -- AXI-4 lite bus app
    app_awvalid_o        : out   std_logic;
    app_awready_i        : in    std_logic;
    app_awaddr_o         : out   std_logic_vector(18 downto 0);
    app_awprot_o         : out   std_logic_vector(2 downto 0);
    app_wvalid_o         : out   std_logic;
    app_wready_i         : in    std_logic;
    app_wdata_o          : out   std_logic_vector(31 downto 0);
    app_wstrb_o          : out   std_logic_vector(3 downto 0);
    app_bvalid_i         : in    std_logic;
    app_bready_o         : out   std_logic;
    app_bresp_i          : in    std_logic_vector(1 downto 0);
    app_arvalid_o        : out   std_logic;
    app_arready_i        : in    std_logic;
    app_araddr_o         : out   std_logic_vector(18 downto 0);
    app_arprot_o         : out   std_logic_vector(2 downto 0);
    app_rvalid_i         : in    std_logic;
    app_rready_o         : out   std_logic;
    app_rdata_i          : in    std_logic_vector(31 downto 0);
    app_rresp_i          : in    std_logic_vector(1 downto 0)
  );
end sps200CavityControl_regs;

architecture syn of sps200CavityControl_regs is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_addr                        : std_logic_vector(20 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_addr                        : std_logic_vector(20 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal hwInfo_aw_val                  : std_logic;
  signal hwInfo_w_val                   : std_logic;
  signal hwInfo_ar_val                  : std_logic;
  signal hwInfo_rd                      : std_logic;
  signal hwInfo_wr                      : std_logic;
  signal app_aw_val                     : std_logic;
  signal app_w_val                      : std_logic;
  signal app_ar_val                     : std_logic;
  signal app_rd                         : std_logic;
  signal app_wr                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(20 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
begin

  -- AW, W and B channels
  awready <= not axi_awset;
  wready <= not axi_wset;
  bvalid <= axi_wdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        wr_req <= '0';
        axi_awset <= '0';
        axi_wset <= '0';
        axi_wdone <= '0';
      else
        wr_req <= '0';
        if awvalid = '1' and axi_awset = '0' then
          wr_addr <= awaddr;
          axi_awset <= '1';
          wr_req <= axi_wset;
        end if;
        if wvalid = '1' and axi_wset = '0' then
          wr_data <= wdata;
          wr_sel(7 downto 0) <= (others => wstrb(0));
          wr_sel(15 downto 8) <= (others => wstrb(1));
          wr_sel(23 downto 16) <= (others => wstrb(2));
          wr_sel(31 downto 24) <= (others => wstrb(3));
          axi_wset <= '1';
          wr_req <= axi_awset or awvalid;
        end if;
        if (axi_wdone and bready) = '1' then
          axi_wset <= '0';
          axi_awset <= '0';
          axi_wdone <= '0';
        end if;
        if wr_ack = '1' then
          axi_wdone <= '1';
        end if;
      end if;
    end if;
  end process;
  bresp <= "00";

  -- AR and R channels
  arready <= not axi_arset;
  rvalid <= axi_rdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_req <= '0';
        axi_arset <= '0';
        axi_rdone <= '0';
        rdata <= (others => '0');
      else
        rd_req <= '0';
        if arvalid = '1' and axi_arset = '0' then
          rd_addr <= araddr;
          axi_arset <= '1';
          rd_req <= '1';
        end if;
        if (axi_rdone and rready) = '1' then
          axi_arset <= '0';
          axi_rdone <= '0';
        end if;
        if rd_ack = '1' then
          axi_rdone <= '1';
          rdata <= rd_data;
        end if;
      end if;
    end if;
  end process;
  rresp <= "00";

  -- pipelining for wr-in+rd-out
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_ack <= '0';
        rd_data <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0000000000000000000";
        wr_dat_d0 <= "00000000000000000000000000000000";
        wr_sel_d0 <= "00000000000000000000000000000000";
      else
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Interface hwInfo
  hwInfo_awvalid_o <= hwInfo_aw_val;
  hwInfo_awaddr_o <= wr_adr_d0(4 downto 2) & "00";
  hwInfo_awprot_o <= "000";
  hwInfo_wvalid_o <= hwInfo_w_val;
  hwInfo_wdata_o <= wr_dat_d0;
  process (wr_sel_d0) begin
    hwInfo_wstrb_o <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      hwInfo_wstrb_o(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      hwInfo_wstrb_o(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      hwInfo_wstrb_o(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      hwInfo_wstrb_o(3) <= '1';
    end if;
  end process;
  hwInfo_bready_o <= '1';
  hwInfo_arvalid_o <= hwInfo_ar_val;
  hwInfo_araddr_o <= rd_addr(4 downto 2) & "00";
  hwInfo_arprot_o <= "000";
  hwInfo_rready_o <= '1';
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        hwInfo_aw_val <= '0';
        hwInfo_w_val <= '0';
        hwInfo_ar_val <= '0';
      else
        hwInfo_aw_val <= hwInfo_wr or (hwInfo_aw_val and not hwInfo_awready_i);
        hwInfo_w_val <= hwInfo_wr or (hwInfo_w_val and not hwInfo_wready_i);
        hwInfo_ar_val <= hwInfo_rd or (hwInfo_ar_val and not hwInfo_arready_i);
      end if;
    end if;
  end process;

  -- Interface app
  app_awvalid_o <= app_aw_val;
  app_awaddr_o <= wr_adr_d0(18 downto 2) & "00";
  app_awprot_o <= "000";
  app_wvalid_o <= app_w_val;
  app_wdata_o <= wr_dat_d0;
  process (wr_sel_d0) begin
    app_wstrb_o <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      app_wstrb_o(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      app_wstrb_o(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      app_wstrb_o(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      app_wstrb_o(3) <= '1';
    end if;
  end process;
  app_bready_o <= '1';
  app_arvalid_o <= app_ar_val;
  app_araddr_o <= rd_addr(18 downto 2) & "00";
  app_arprot_o <= "000";
  app_rready_o <= '1';
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        app_aw_val <= '0';
        app_w_val <= '0';
        app_ar_val <= '0';
      else
        app_aw_val <= app_wr or (app_aw_val and not app_awready_i);
        app_w_val <= app_wr or (app_w_val and not app_wready_i);
        app_ar_val <= app_rd or (app_ar_val and not app_arready_i);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, hwInfo_bvalid_i, app_bvalid_i) begin
    hwInfo_wr <= '0';
    app_wr <= '0';
    case wr_adr_d0(20 downto 19) is
    when "00" =>
      -- Submap hwInfo
      hwInfo_wr <= wr_req_d0;
      wr_ack <= hwInfo_bvalid_i;
    when "10" =>
      -- Submap app
      app_wr <= wr_req_d0;
      wr_ack <= app_bvalid_i;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, hwInfo_rdata_i, hwInfo_rvalid_i, app_rdata_i,
           app_rvalid_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    hwInfo_rd <= '0';
    app_rd <= '0';
    case rd_addr(20 downto 19) is
    when "00" =>
      -- Submap hwInfo
      hwInfo_rd <= rd_req;
      rd_dat_d0 <= hwInfo_rdata_i;
      rd_ack_d0 <= hwInfo_rvalid_i;
    when "10" =>
      -- Submap app
      app_rd <= rd_req;
      rd_dat_d0 <= app_rdata_i;
      rd_ack_d0 <= app_rvalid_i;
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
