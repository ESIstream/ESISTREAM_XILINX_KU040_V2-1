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
use ieee.math_real.all;

--library UNISIM;
--use UNISIM.VComponents.all;

entity sync_generator is
  generic (
    SYNCTRIG_PULSE_WIDTH : integer := 4
    );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    send_sync   : in  std_logic;
    sw_sync     : in  std_logic;
    synctrig    : out std_logic;
    synctrig_re : out std_logic
    );
end sync_generator;

architecture rtl of sync_generator is
  --------------------------------------------------------------------------------------------------------------------
  --! signal name description:
  -- _sr = _shift_register
  -- _re = _rising_edge (one clk period pulse generated on the rising edge of the initial signal)
  -- _d  = _delay
  -- _2d = _delay x2
  -- _ba = _bitwise_and
  -- _sw = _slide_window
  -- _o  = _output
  -- _i  = _input
  -- _t  = _temporary (fsm signals)
  --------------------------------------------------------------------------------------------------------------------
  signal send_sync_sr : std_logic_vector (2 downto 0) := (others => '0');
  constant cntr_msb   : integer                       := integer(floor(log2(real(SYNCTRIG_PULSE_WIDTH))))+1;
  signal cntr         : unsigned(cntr_msb downto 0)   := (others => '0');
  signal synctrig_o   : std_logic;

begin

  new_sync_proc : process (clk)
  begin
    if rising_edge (clk) then
      if rst = '1' then
        send_sync_sr <= (others => '0');
      else
        send_sync_sr(0)          <= send_sync;
        send_sync_sr(2 downto 1) <= send_sync_sr(1 downto 0);
      end if;
    end if;
  end process;

  gen_pulse_proc : process (clk)
  begin
    if rising_edge (clk) then
      if rst = '1' then
        cntr        <= (others => '0');
        synctrig_o  <= '0';
        synctrig_re <= '0';
      else
        if send_sync_sr(2 downto 1) = "10" or sw_sync = '1' then
          synctrig_re <= '1';
          -- falling edge
          cntr        <= to_unsigned(SYNCTRIG_PULSE_WIDTH, cntr'length);
          synctrig_o  <= '1';
        elsif cntr = 0 then
          synctrig_re <= '0';
          synctrig_o  <= '0';
          cntr        <= cntr;
        else
          synctrig_re <= '0';
          cntr        <= cntr - 1;
          synctrig_o  <= synctrig_o;
        end if;
      end if;
    end if;
  end process;

  delay_1: entity work.delay
    generic map (
      LATENCY => 10)
    port map (
      clk => clk,
      rst => rst,
      d   => synctrig_o,
      q   => synctrig);
  
  --synctrig <= synctrig_o;

end architecture rtl;
