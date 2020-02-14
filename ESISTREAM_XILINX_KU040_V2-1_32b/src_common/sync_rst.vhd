
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
-- 1.1          2019            REFLEXCES    
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description :
-- Synchronize reset.
-- Asynchronous assertion, synchronous de-assertion.
--
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity sync_rst is
    generic (
          NB_RESET              : integer           := 1        -- number of reset to synchronize
    );
    port (
        -- Asynchronous inputs
          in_rst_n              : in    std_logic_vector(NB_RESET-1 downto 0)   := (others=>'1')      -- asynchronous active low resets                             /!\ choose only one reset source for each output /!\
        ; in_rst                : in    std_logic_vector(NB_RESET-1 downto 0)   := (others=>'0')      -- asynchronous active high resets                            /!\ choose only one reset source for each output /!\
        ; in_com_rst_n          : in    std_logic                               :=          '1'       -- asynchronous active low reset  common to all clock domains /!\ choose only one reset source for each output /!\
        ; in_com_rst            : in    std_logic                               :=          '0'       -- asynchronous active high reset common to all clock domains /!\ choose only one reset source for each output /!\
        
        -- Synchronized outputs
        ; out_clk               : in    std_logic_vector(NB_RESET-1 downto 0)                           -- clocks used to synchronize resets
        ; out_rst_n             : out   std_logic_vector(NB_RESET-1 downto 0)                           -- synchronous de-asserted active low resets
        ; out_rst               : out   std_logic_vector(NB_RESET-1 downto 0)                           -- synchronous de-asserted active high resets
    );
end entity sync_rst;

architecture rtl of sync_rst is
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
    signal s_in_rst_n       : std_logic_vector(NB_RESET-1 downto 0);
    signal s_out_rst_n      : std_logic_vector(NB_RESET-1 downto 0);
    signal s_out_rst        : std_logic_vector(NB_RESET-1 downto 0);
begin
    gen_rst : for i in 0 to NB_RESET-1 generate
        s_in_rst_n(i) <= (in_rst_n(i) and in_com_rst_n) and not(in_rst(i) or in_com_rst);
        process (out_clk(i), s_in_rst_n(i))
        begin
        if s_in_rst_n(i)='0' then 
            s_out_rst_n(i)  <= '0'; out_rst_n(i) <= '0';
            s_out_rst(i)    <= '1'; out_rst(i)   <= '1';
        elsif rising_edge(out_clk(i)) then
            s_out_rst_n(i)  <= '1'; out_rst_n(i) <= s_out_rst_n(i);
            s_out_rst(i)    <= '0'; out_rst(i)   <= s_out_rst(i);
        end if;
        end process;   
    end generate gen_rst;
    
end architecture rtl;
