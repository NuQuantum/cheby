library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity s3 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
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
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- AXI-4 lite bus sub
    sub_awvalid_o        : out   std_logic;
    sub_awready_i        : in    std_logic;
    sub_awprot_o         : out   std_logic_vector(2 downto 0);
    sub_wvalid_o         : out   std_logic;
    sub_wready_i         : in    std_logic;
    sub_wdata_o          : out   std_logic_vector(31 downto 0);
    sub_wstrb_o          : out   std_logic_vector(3 downto 0);
    sub_bvalid_i         : in    std_logic;
    sub_bready_o         : out   std_logic;
    sub_bresp_i          : in    std_logic_vector(1 downto 0);
    sub_arvalid_o        : out   std_logic;
    sub_arready_i        : in    std_logic;
    sub_arprot_o         : out   std_logic_vector(2 downto 0);
    sub_rvalid_i         : in    std_logic;
    sub_rready_o         : out   std_logic;
    sub_rdata_i          : in    std_logic_vector(31 downto 0);
    sub_rresp_i          : in    std_logic_vector(1 downto 0)
  );
end s3;

architecture syn of s3 is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal sub_aw_val                     : std_logic;
  signal sub_w_val                      : std_logic;
  signal sub_ar_val                     : std_logic;
  signal sub_rd                         : std_logic;
  signal sub_wr                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
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
        wr_req_d0 <= '0';
      else
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Interface sub
  sub_awvalid_o <= sub_aw_val;
  sub_awprot_o <= "000";
  sub_wvalid_o <= sub_w_val;
  sub_wdata_o <= wr_dat_d0;
  process (wr_sel_d0) begin
    sub_wstrb_o <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      sub_wstrb_o(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      sub_wstrb_o(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      sub_wstrb_o(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      sub_wstrb_o(3) <= '1';
    end if;
  end process;
  sub_bready_o <= '1';
  sub_arvalid_o <= sub_ar_val;
  sub_arprot_o <= "000";
  sub_rready_o <= '1';
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub_aw_val <= '0';
        sub_w_val <= '0';
        sub_ar_val <= '0';
      else
        sub_aw_val <= sub_wr or (sub_aw_val and not sub_awready_i);
        sub_w_val <= sub_wr or (sub_w_val and not sub_wready_i);
        sub_ar_val <= sub_rd or (sub_ar_val and not sub_arready_i);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, sub_bvalid_i) begin
    sub_wr <= '0';
    -- Submap sub
    sub_wr <= wr_req_d0;
    wr_ack <= sub_bvalid_i;
  end process;

  -- Process for read requests.
  process (rd_req, sub_rdata_i, sub_rvalid_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sub_rd <= '0';
    -- Submap sub
    sub_rd <= rd_req;
    rd_dat_d0 <= sub_rdata_i;
    rd_ack_d0 <= sub_rvalid_i;
  end process;
end syn;
