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
-- Version      Date            Author       Description
-- 1.1          2019            REFLEXCES    Creation
----------------------------------------------------------------------------------------------------
-- Description :
-- Synchronize reset and generate a 'long' reset pulse.
-- Asynchronous assertion, synchronous de-assertion.
--
----------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity delayed_rst is
    generic (
          NB_BITS               : integer   := 2        -- number of bits for the internal counter. Ex. 2 will generate a 2**NB_BITS+3 cycles reset
    );
    port (
        -- Asynchronous inputs
          in_rst_n              : in    std_logic   := '1'  -- asynchronous active low reset (choose only one between active low or high reset).
        ; in_rst                : in    std_logic   := '0'  -- asynchronous active high reset (choose only one between active low or high reset).
        
        -- Synchronized outputs
        ; out_clk               : in    std_logic           -- clock used to synchronize reset and for counter
        ; out_rst_n             : out   std_logic           -- synchronous de-asserted active low reset
        ; out_rst               : out   std_logic           -- synchronous de-asserted active high reset
    );
end entity delayed_rst;

architecture rtl of delayed_rst is
	----------------------------------------------------------------
	-- Type declarations
	----------------------------------------------------------------
    
	----------------------------------------------------------------
	-- Function declarations
	----------------------------------------------------------------
    
	----------------------------------------------------------------
	-- Component declarations
	----------------------------------------------------------------
    
	----------------------------------------------------------------
	-- Constant declarations
	----------------------------------------------------------------

	----------------------------------------------------------------
	-- Signal declarations
	----------------------------------------------------------------
    signal s_in_rst         : std_logic;
    signal s_int_rst_x      : std_logic;
    signal s_int_rst        : std_logic;
    signal s_cnt            : std_logic_vector(NB_BITS downto 0);
begin
    s_in_rst <= not(in_rst_n) or in_rst;
    
    -- Internal resynchronized reset
    process (out_clk, s_in_rst)
    begin
    if s_in_rst='1' then 
        s_int_rst_x <= '1'; s_int_rst <= '1';
    elsif rising_edge(out_clk) then
        s_int_rst_x <= '0'; s_int_rst <= s_int_rst_x;
    end if;
    end process; 
    
    -- Long reset
    process (out_clk, s_int_rst)
    begin
    if s_int_rst='1' then 
        s_cnt       <= (others=>'0');
        out_rst     <= '1';
        out_rst_n   <= '0';
    elsif rising_edge(out_clk) then
        if s_cnt(s_cnt'high)='0' then s_cnt <= std_logic_vector(unsigned(s_cnt) + 1); end if;
        out_rst     <= not(s_cnt(s_cnt'high));
        out_rst_n   <=     s_cnt(s_cnt'high);
    end if;
    end process; 
    
end architecture rtl;
