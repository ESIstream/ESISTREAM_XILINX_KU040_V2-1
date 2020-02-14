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

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.esistream_pkg.all;

entity data_gen is
  port (
      nrst         : in  std_logic
    ; clk          : in  std_logic
    ; d_ctrl       : in  std_logic_vector(1 downto 0)   -- Control the data output type ("00" 0x000; "01" ramp+; "10" ramp-; "11" 0xFFF)
    ; data_out     : out std_logic_vector(13 downto 0)  -- Output data
    ; data_out_64b : out std_logic_vector(13 downto 0)  -- Output data
   );
end entity data_gen;

architecture rtl of data_gen is

---------- Signals ----------
  signal data_t     : std_logic_vector(13 downto 0) := (others => '0');
  signal data_t_64b : std_logic_vector(13 downto 0) := (others => '0');

begin
  
  process(clk, nrst)
  begin
    if nrst = '0' then
      data_t     <= (others => '0');
      data_t_64b <= (others => '0');
    elsif rising_edge(clk) then
      if d_ctrl = "00" then
        data_t     <= (others => '0');
        data_t_64b <= (others => '0');
      elsif d_ctrl = "01" then
        if (SER_WIDTH = 64) then data_t     <= data_t_64b + 1;
        else                     data_t     <= data_t     + 1; end if;   
        data_t_64b                          <= data_t_64b + 2;
      elsif d_ctrl = "10" then
        if (SER_WIDTH = 64) then data_t     <= data_t_64b - 1;
        else                     data_t     <= data_t     - 1; end if; 
        data_t_64b                          <= data_t_64b - 2;
      else
        data_t     <= (others => '1');
        data_t_64b <= (others => '1');
      end if;

    end if;

  end process;

  data_out     <= data_t    ;
  data_out_64b <= data_t_64b;
end architecture rtl;
