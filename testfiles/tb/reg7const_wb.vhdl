library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg7const_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(4 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0)
  );
end reg7const_wb;

architecture syn of reg7const_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
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
      end if;
    end if;
  end process;

  -- Register reg1

  -- Register reg2

  -- Register reg3

  -- Register reg4

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0) begin
    case wr_adr_d0(4 downto 3) is
    when "00" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg reg1
        wr_ack_int <= wr_req_d0;
      when "1" =>
        -- Reg reg2
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg reg3
        wr_ack_int <= wr_req_d0;
      when "1" =>
        -- Reg reg3
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg reg4
        wr_ack_int <= wr_req_d0;
      when "1" =>
        -- Reg reg4
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(4 downto 3) is
    when "00" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg reg1
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= "10101011110011010001001000110100";
      when "1" =>
        -- Reg reg2
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '1';
        rd_dat_d0(15 downto 1) <= (others => '0');
        rd_dat_d0(17 downto 16) <= "11";
        rd_dat_d0(31 downto 18) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg reg3
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(8 downto 0) <= "011001011";
        rd_dat_d0(27 downto 9) <= (others => '0');
        rd_dat_d0(31 downto 28) <= "1010";
      when "1" =>
        -- Reg reg3
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '1';
        rd_dat_d0(19 downto 1) <= (others => '0');
        rd_dat_d0(23 downto 20) <= "0101";
        rd_dat_d0(31 downto 24) <= "10101001";
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg reg4
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= "10101011110011010001001000110100";
      when "1" =>
        -- Reg reg4
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= "01010110011110001001000011101111";
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
