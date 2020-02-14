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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_dual_master is
  generic(
    CLK_MHz     : real := 100.0;
    SPI_CLK_MHz : real := 10.0
    );
  port (
    clk           : in  std_logic := 'X';
    rst           : in  std_logic := 'X';
    spi_ncs1      : out std_logic;
    spi_ncs2      : out std_logic;
    spi_sclk      : out std_logic;
    spi_mosi      : out std_logic;
    spi_miso      : in  std_logic;
    spi_ss        : in  std_logic;
    spi_start     : in  std_logic;
    spi_cmd       : in  std_logic_vector(1 downto 0);
    spi_busy      : out std_logic;
    prbs_en       : in  std_logic := '1';
    data_en       : in  std_logic := '1';
    dc_balance_en : in  std_logic := '1');

end entity spi_dual_master;

architecture rtl of spi_dual_master is

  signal refclk    : std_logic := '0';
  signal refclk_re : std_logic := '0';
  signal refclk_fe : std_logic := '0';

begin

  spi_refclk_1 : entity work.spi_refclk
    generic map (
      CLK_MHz     => CLK_MHz,
      SPI_CLK_MHz => SPI_CLK_MHz)
    port map (
      clk       => clk,
      rst       => rst,
      refclk    => refclk,
      refclk_re => refclk_re,
      refclk_fe => refclk_fe);

  spi_dual_master_fsm_1 : entity work.spi_dual_master_fsm
    port map (
      clk           => clk,
      rst           => rst,
      refclk        => refclk,
      refclk_re     => refclk_re,
      refclk_fe     => refclk_fe,
      spi_ncs2      => spi_ncs2,
      spi_ncs1      => spi_ncs1,
      spi_sclk      => spi_sclk,
      spi_mosi      => spi_mosi,
      spi_miso      => spi_miso,
      spi_ss        => spi_ss,
      spi_start     => spi_start,
      spi_cmd       => spi_cmd,
      spi_busy      => spi_busy,
      prbs_en       => prbs_en,
      data_en       => data_en,
      dc_balance_en => dc_balance_en);


end rtl;
