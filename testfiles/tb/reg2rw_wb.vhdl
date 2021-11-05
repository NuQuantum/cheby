library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg2rw_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(5 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG rrw
    rrw_o                : out   std_logic_vector(31 downto 0);

    -- REG rrw_rs
    rrw_rs_o             : out   std_logic_vector(31 downto 0);
    rrw_rs_rd_o          : out   std_logic;

    -- REG rrw_ws
    rrw_ws_o             : out   std_logic_vector(31 downto 0);
    rrw_ws_wr_o          : out   std_logic;

    -- REG rrw_rws
    rrw_rws_o            : out   std_logic_vector(31 downto 0);
    rrw_rws_wr_o         : out   std_logic;
    rrw_rws_rd_o         : out   std_logic;

    -- REG rrw_ws_wa
    rrw_ws_wa_o          : out   std_logic_vector(31 downto 0);
    rrw_ws_wa_wr_o       : out   std_logic;
    rrw_ws_wa_wack_i     : in    std_logic;

    -- REG wrw_ws
    wrw_ws_i             : in    std_logic_vector(31 downto 0);
    wrw_ws_o             : out   std_logic_vector(31 downto 0);
    wrw_ws_wr_o          : out   std_logic;

    -- REG wrw_rws
    wrw_rws_i            : in    std_logic_vector(31 downto 0);
    wrw_rws_o            : out   std_logic_vector(31 downto 0);
    wrw_rws_wr_o         : out   std_logic;
    wrw_rws_rd_o         : out   std_logic;

    -- REG wrw_ws_wa
    wrw_ws_wa_i          : in    std_logic_vector(31 downto 0);
    wrw_ws_wa_o          : out   std_logic_vector(31 downto 0);
    wrw_ws_wa_wr_o       : out   std_logic;
    wrw_ws_wa_wack_i     : in    std_logic;

    -- REG wrw_rws_wa
    wrw_rws_wa_i         : in    std_logic_vector(31 downto 0);
    wrw_rws_wa_o         : out   std_logic_vector(31 downto 0);
    wrw_rws_wa_wr_o      : out   std_logic;
    wrw_rws_wa_rd_o      : out   std_logic;
    wrw_rws_wa_wack_i    : in    std_logic;

    -- REG wrw_rws_ra
    wrw_rws_ra_i         : in    std_logic_vector(31 downto 0);
    wrw_rws_ra_o         : out   std_logic_vector(31 downto 0);
    wrw_rws_ra_wr_o      : out   std_logic;
    wrw_rws_ra_rd_o      : out   std_logic;
    wrw_rws_ra_rack_i    : in    std_logic;

    -- REG wrw_rws_rwa
    wrw_rws_rwa_i        : in    std_logic_vector(31 downto 0);
    wrw_rws_rwa_o        : out   std_logic_vector(31 downto 0);
    wrw_rws_rwa_wr_o     : out   std_logic;
    wrw_rws_rwa_rd_o     : out   std_logic;
    wrw_rws_rwa_wack_i   : in    std_logic;
    wrw_rws_rwa_rack_i   : in    std_logic
  );
end reg2rw_wb;

architecture syn of reg2rw_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rrw_reg                        : std_logic_vector(31 downto 0);
  signal rrw_wreq                       : std_logic;
  signal rrw_wack                       : std_logic;
  signal rrw_rs_reg                     : std_logic_vector(31 downto 0);
  signal rrw_rs_wreq                    : std_logic;
  signal rrw_rs_wack                    : std_logic;
  signal rrw_ws_reg                     : std_logic_vector(31 downto 0);
  signal rrw_ws_wreq                    : std_logic;
  signal rrw_ws_wack                    : std_logic;
  signal rrw_rws_reg                    : std_logic_vector(31 downto 0);
  signal rrw_rws_wreq                   : std_logic;
  signal rrw_rws_wack                   : std_logic;
  signal rrw_ws_wa_reg                  : std_logic_vector(31 downto 0);
  signal rrw_ws_wa_wreq                 : std_logic;
  signal rrw_ws_wa_wack                 : std_logic;
  signal wrw_ws_wreq                    : std_logic;
  signal wrw_rws_wreq                   : std_logic;
  signal wrw_ws_wa_wreq                 : std_logic;
  signal wrw_rws_wa_wreq                : std_logic;
  signal wrw_rws_ra_wreq                : std_logic;
  signal wrw_rws_rwa_wreq               : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register rrw
  rrw_o <= rrw_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rrw_reg <= "00000000000000000000000000000000";
        rrw_wack <= '0';
      else
        if rrw_wreq = '1' then
          rrw_reg <= wr_dat_d0;
        end if;
        rrw_wack <= rrw_wreq;
      end if;
    end if;
  end process;

  -- Register rrw_rs
  rrw_rs_o <= rrw_rs_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rrw_rs_reg <= "00000000000000000000000000000000";
        rrw_rs_wack <= '0';
      else
        if rrw_rs_wreq = '1' then
          rrw_rs_reg <= wr_dat_d0;
        end if;
        rrw_rs_wack <= rrw_rs_wreq;
      end if;
    end if;
  end process;

  -- Register rrw_ws
  rrw_ws_o <= rrw_ws_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rrw_ws_reg <= "00000000000000000000000000000000";
        rrw_ws_wack <= '0';
      else
        if rrw_ws_wreq = '1' then
          rrw_ws_reg <= wr_dat_d0;
        end if;
        rrw_ws_wack <= rrw_ws_wreq;
      end if;
    end if;
  end process;
  rrw_ws_wr_o <= rrw_ws_wack;

  -- Register rrw_rws
  rrw_rws_o <= rrw_rws_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rrw_rws_reg <= "00000000000000000000000000000000";
        rrw_rws_wack <= '0';
      else
        if rrw_rws_wreq = '1' then
          rrw_rws_reg <= wr_dat_d0;
        end if;
        rrw_rws_wack <= rrw_rws_wreq;
      end if;
    end if;
  end process;
  rrw_rws_wr_o <= rrw_rws_wack;

  -- Register rrw_ws_wa
  rrw_ws_wa_o <= rrw_ws_wa_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rrw_ws_wa_reg <= "00000000000000000000000000000000";
        rrw_ws_wa_wack <= '0';
      else
        if rrw_ws_wa_wreq = '1' then
          rrw_ws_wa_reg <= wr_dat_d0;
        end if;
        rrw_ws_wa_wack <= rrw_ws_wa_wreq;
      end if;
    end if;
  end process;
  rrw_ws_wa_wr_o <= rrw_ws_wa_wack;

  -- Register wrw_ws
  wrw_ws_o <= wr_dat_d0;
  wrw_ws_wr_o <= wrw_ws_wreq;

  -- Register wrw_rws
  wrw_rws_o <= wr_dat_d0;
  wrw_rws_wr_o <= wrw_rws_wreq;

  -- Register wrw_ws_wa
  wrw_ws_wa_o <= wr_dat_d0;
  wrw_ws_wa_wr_o <= wrw_ws_wa_wreq;

  -- Register wrw_rws_wa
  wrw_rws_wa_o <= wr_dat_d0;
  wrw_rws_wa_wr_o <= wrw_rws_wa_wreq;

  -- Register wrw_rws_ra
  wrw_rws_ra_o <= wr_dat_d0;
  wrw_rws_ra_wr_o <= wrw_rws_ra_wreq;

  -- Register wrw_rws_rwa
  wrw_rws_rwa_o <= wr_dat_d0;
  wrw_rws_rwa_wr_o <= wrw_rws_rwa_wreq;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, rrw_wack, rrw_rs_wack, rrw_ws_wack, rrw_rws_wack, rrw_ws_wa_wack_i, wrw_ws_wa_wack_i, wrw_rws_wa_wack_i, wrw_rws_rwa_wack_i) begin
    rrw_wreq <= '0';
    rrw_rs_wreq <= '0';
    rrw_ws_wreq <= '0';
    rrw_rws_wreq <= '0';
    rrw_ws_wa_wreq <= '0';
    wrw_ws_wreq <= '0';
    wrw_rws_wreq <= '0';
    wrw_ws_wa_wreq <= '0';
    wrw_rws_wa_wreq <= '0';
    wrw_rws_ra_wreq <= '0';
    wrw_rws_rwa_wreq <= '0';
    case wr_adr_d0(5 downto 2) is
    when "0000" =>
      -- Reg rrw
      rrw_wreq <= wr_req_d0;
      wr_ack_int <= rrw_wack;
    when "0001" =>
      -- Reg rrw_rs
      rrw_rs_wreq <= wr_req_d0;
      wr_ack_int <= rrw_rs_wack;
    when "0010" =>
      -- Reg rrw_ws
      rrw_ws_wreq <= wr_req_d0;
      wr_ack_int <= rrw_ws_wack;
    when "0011" =>
      -- Reg rrw_rws
      rrw_rws_wreq <= wr_req_d0;
      wr_ack_int <= rrw_rws_wack;
    when "0100" =>
      -- Reg rrw_ws_wa
      rrw_ws_wa_wreq <= wr_req_d0;
      wr_ack_int <= rrw_ws_wa_wack_i;
    when "0101" =>
      -- Reg wrw_ws
      wrw_ws_wreq <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "0110" =>
      -- Reg wrw_rws
      wrw_rws_wreq <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "0111" =>
      -- Reg wrw_ws_wa
      wrw_ws_wa_wreq <= wr_req_d0;
      wr_ack_int <= wrw_ws_wa_wack_i;
    when "1000" =>
      -- Reg wrw_rws_wa
      wrw_rws_wa_wreq <= wr_req_d0;
      wr_ack_int <= wrw_rws_wa_wack_i;
    when "1001" =>
      -- Reg wrw_rws_ra
      wrw_rws_ra_wreq <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "1010" =>
      -- Reg wrw_rws_rwa
      wrw_rws_rwa_wreq <= wr_req_d0;
      wr_ack_int <= wrw_rws_rwa_wack_i;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, rrw_reg, rrw_rs_reg, rrw_ws_reg, rrw_rws_reg, rrw_ws_wa_reg, wrw_ws_i, wrw_rws_i, wrw_ws_wa_i, wrw_rws_wa_i, wrw_rws_ra_rack_i, wrw_rws_ra_i, wrw_rws_rwa_rack_i, wrw_rws_rwa_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    rrw_rs_rd_o <= '0';
    rrw_rws_rd_o <= '0';
    wrw_rws_rd_o <= '0';
    wrw_rws_wa_rd_o <= '0';
    wrw_rws_ra_rd_o <= '0';
    wrw_rws_rwa_rd_o <= '0';
    case wb_adr_i(5 downto 2) is
    when "0000" =>
      -- Reg rrw
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rrw_reg;
    when "0001" =>
      -- Reg rrw_rs
      rrw_rs_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rrw_rs_reg;
    when "0010" =>
      -- Reg rrw_ws
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rrw_ws_reg;
    when "0011" =>
      -- Reg rrw_rws
      rrw_rws_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rrw_rws_reg;
    when "0100" =>
      -- Reg rrw_ws_wa
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rrw_ws_wa_reg;
    when "0101" =>
      -- Reg wrw_ws
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wrw_ws_i;
    when "0110" =>
      -- Reg wrw_rws
      wrw_rws_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wrw_rws_i;
    when "0111" =>
      -- Reg wrw_ws_wa
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wrw_ws_wa_i;
    when "1000" =>
      -- Reg wrw_rws_wa
      wrw_rws_wa_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wrw_rws_wa_i;
    when "1001" =>
      -- Reg wrw_rws_ra
      wrw_rws_ra_rd_o <= rd_req_int;
      rd_ack_d0 <= wrw_rws_ra_rack_i;
      rd_dat_d0 <= wrw_rws_ra_i;
    when "1010" =>
      -- Reg wrw_rws_rwa
      wrw_rws_rwa_rd_o <= rd_req_int;
      rd_ack_d0 <= wrw_rws_rwa_rack_i;
      rd_dat_d0 <= wrw_rws_rwa_i;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
