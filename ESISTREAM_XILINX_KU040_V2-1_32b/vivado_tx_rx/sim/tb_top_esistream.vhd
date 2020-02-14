-------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
-- this software, either in source code form or as a compiled bitstream, for 
-- any purpose, commercial or non-commercial, and by any means.
--
-- In jurisdictions that recognize copyright laws, the author or authors of 
-- this software dedicate any and all copyright interest in the software to 
-- the public domain. We make this dedication for the benefit of the public at
-- large and to the detriment of our heirs and successors. We intend this 
-- dedication to be an overt act of relinquishment in perpetuity of all present
-- and future rights to this software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- THIS DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 
-------------------------------------------------------------------------------

library work;
use work.esistream_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library STD;
use STD.textio.all;

library unisim;
use unisim.vcomponents.all;


entity tb_top_esistream is
end entity tb_top_esistream;

architecture behavioral of tb_top_esistream is

---------------- Constants ----------------
  constant NB_LANES       : natural                               := 4;
  constant COMMA          : std_logic_vector(31 downto 0)         := x"FF0000FF";
  signal clk_xcvr_fmc_p   : std_logic                             := '0';
  signal clk_xcvr_fmc_n   : std_logic                             := '1';
  signal clk_125mhz_p     : std_logic                             := '0';
  signal clk_125mhz_n     : std_logic                             := '1';
  signal fmc_xcvr_out_p   : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal fmc_xcvr_out_n   : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  signal SW_C             : std_logic                             := '0'; 
  signal SW_S             : std_logic                             := '0'; 
  signal SW_W             : std_logic                             := '0'; 
  signal SW_E             : std_logic                             := '0'; 
  signal SW_N             : std_logic                             := '0'; 
  signal dipswitch        : std_logic_vector(4 downto 1)          := (others => '0');
  signal led_usr          : std_logic_vector(7 downto 0)          := (others => '0');
  --
  signal tx_ip_ready      : std_logic                             := '0';
  signal rx_ip_ready      : std_logic                             := '0';
  signal ip_ready         : std_logic                             := '0';
  signal rx_lanes_ready   : std_logic                             := '0';
  signal tx_d_ctrl        : std_logic_vector(1 downto 0)          := (others => '0');
  signal prbs_en          : std_logic                             := '0';
  signal tx_disp_en       : std_logic                             := '0';
  signal sync             : std_logic                             := '0';
  signal rst              : std_logic                             := '0';
  signal rst_check        : std_logic                             := '0';
  signal ber_status       : std_logic                             := '0';
  signal cb_status        : std_logic                             := '0';
  constant STATUS_SUCCESS : std_logic                             := '1';
--
begin
--
--############################################################################################################################
--############################################################################################################################
-- Clock Generation
--############################################################################################################################
--############################################################################################################################
  clk_xcvr_fmc_p <= not clk_xcvr_fmc_p after 2.5 ns;
  clk_xcvr_fmc_n <= not clk_xcvr_fmc_n after 2.5 ns;
  --
  clk_125mhz_p   <= not clk_125mhz_p   after 4 ns;
  clk_125mhz_n   <= not clk_125mhz_n   after 4 ns;
  --
--############################################################################################################################
--############################################################################################################################
-- Unit under test
--############################################################################################################################
--############################################################################################################################   
  top_esistream_1 : entity work.top_esistream
    generic map (
      NB_LANES => NB_LANES,
      COMMA    => COMMA)
    port map (
      clk_xcvr_fmc_p => clk_xcvr_fmc_p,
      clk_xcvr_fmc_n => clk_xcvr_fmc_n,
      clk_125mhz_p   => clk_125mhz_p,
      clk_125mhz_n   => clk_125mhz_n,
      fmc_xcvr_out_p => fmc_xcvr_out_p,
      fmc_xcvr_out_n => fmc_xcvr_out_n,
      fmc_xcvr_in_p  => fmc_xcvr_out_p,
      fmc_xcvr_in_n  => fmc_xcvr_out_n,
      SW_C           => SW_C,             
      SW_S           => SW_S, 
      SW_W           => SW_W,    
      SW_E           => SW_E, 
      SW_N           => SW_N, 
      dipswitch      => dipswitch,
      led_usr        => led_usr);

  dipswitch(4)          <= prbs_en;
  dipswitch(3)          <= tx_disp_en;
  dipswitch(2 downto 1) <= tx_d_ctrl;

  SW_C <= rst;
  SW_S <= sync;
  SW_W <= rst_check;
  SW_E <= '0';
  SW_N <= '0';

  tx_ip_ready    <= led_usr(0);
  rx_ip_ready    <= led_usr(1);
  rx_lanes_ready <= led_usr(2);
  cb_status      <= led_usr(3);
  ber_status     <= led_usr(4);
  --'0'            <= led_usr(5);
  --'0'            <= led_usr(6);
  --'0'            <= led_usr(7);

  ip_ready <= tx_ip_ready and rx_ip_ready;
--============================================================================================================================
-- Stimulus
--============================================================================================================================
  my_tb : process
  begin
    -------------------------------- 
    -- tb init
    -------------------------------- 
    tx_d_ctrl  <= "01";  -- data encoded is 14-bit positive ramp
    tx_disp_en <= '1';   -- Disparity prtocessingenabled
    rst        <= '0';
    rst_check  <= '0';
    sync       <= '0';
    prbs_en    <= '1';   -- Descramble processing enabled
    report "wait all cpll locked";
    wait until rising_edge(ip_ready);
    report "generate TX rst pulse";
    wait for 100 ns;
    rst        <= '1';
    wait for 100 ns;
    rst        <= '0';
    report "Wait for reset to complete";
    wait until rising_edge(ip_ready);
    --
    wait for 100 ns;
    report "RX synchronization";
    sync       <= '1';
    wait for 100 ns;
    sync       <= '0';
    wait until rising_edge(rx_lanes_ready);
    wait for 100 ns;
    rst_check  <= '1';
    wait for 100 ns;
    rst_check  <= '0';
    report "Check Begin";
    wait for 200 ns;
    assert ber_status = STATUS_SUCCESS report "BER OK step 1 ";
    assert cb_status = STATUS_SUCCESS report "CB  OK step 1 ";

    report "RX synchronization";
    sync      <= '1';
    wait for 100 ns;
    sync      <= '0';
    wait until rx_lanes_ready = '1';
    wait for 100 ns;
    rst_check <= '1';
    wait for 100 ns;
    rst_check <= '0';
    report "Check Begin";
    wait for 200 ns;
    assert ber_status = STATUS_SUCCESS report "BER OK step 2 ";
    assert cb_status = STATUS_SUCCESS report "CB  OK step 2 ";

    wait for 1000 ns;
    report "RX synchronization";
    sync      <= '1';
    wait for 100 ns;
    sync      <= '0';
    wait until rx_lanes_ready = '1';
    wait for 100 ns;
    rst_check <= '1';
    wait for 100 ns;
    rst_check <= '0';
    report "Check Begin";
    wait for 200 ns;
    assert ber_status = STATUS_SUCCESS report "BER OK step 3 ";
    assert cb_status = STATUS_SUCCESS report "CB  OK step 3 ";

    assert false report "Test finish" severity failure;
  end process;



end behavioral;
