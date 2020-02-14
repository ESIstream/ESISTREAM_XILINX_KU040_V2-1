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
-- 1.0          2019            Teledyne e2v Creation
-- 1.1          2019            REFLEXCES    FPGA target migration, 64-bit data path
-------------------------------------------------------------------------------
-- Description :
-- For each lane : 
-- When SER_WIDTH = 32 : Encodes useful data 2x14-bits (data_in signal) into a
--                       2x16-bits ESIstream frame vector (32-bits, data_encoded signal).
-- When SER_WIDTH = 64 : Encodes useful data 4x14-bits (data_in signal) into a
--                       4x16-bits ESIstream frame vector (64-bits, data_encoded signal). 
-- It serializes and transmits data using a transceiver IP on the
-- differential serial link output (tx_n / tx_p).
----------------------------------------------------------------------------------------------------
library work;
use work.esistream_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;

entity tx_esistream_with_xcvr is
  generic(
     NB_LANES : natural                       := 4           -- number of lanes
   ; COMMA    : std_logic_vector(31 downto 0) := x"FF0000FF"  -- comma for frame alignemnent (0x00FFFF00 or 0xFF0000FF).
  );
  port (
     rst       : in  std_logic                                -- active high asynchronous reset
   ; refclk_n  : in  std_logic                                -- transceiver ip reference clock n input 
   ; refclk_p  : in  std_logic                                -- transceiver ip reference clock p input 
   ; sysclk    : in  std_logic                                -- transceiver ip system clock
   ; sync_in   : in  std_logic                                -- active high synchronization pulse input
   ; prbs_en   : in  std_logic                                -- active high scrambling processing enable input 
   ; disp_en   : in  std_logic                                -- active high disparity processing enable input
   ; lfsr_init : in  slv_17_array_n(NB_LANES-1 downto 0)      -- Select LFSR initialization value for each lanes.
   ; data_in   : in  tx_data_array(NB_LANES-1 downto 0)        -- data input to encode (13 downto 0)
   ; txn       : out std_logic_vector(NB_LANES-1 downto 0)    -- lane serial output n
   ; txp       : out std_logic_vector(NB_LANES-1 downto 0)    -- lane serial output p
   ; tx_clk    : out std_logic                                -- transmitter clock
   ; ip_ready  : out std_logic                                -- active high ip ready (transceiver pll locked and transceiver reset done)
  );
end entity tx_esistream_with_xcvr;

architecture rtl of tx_esistream_with_xcvr is
    --============================================================================================================================
    -- Function and Procedure declarations
    --============================================================================================================================

    --============================================================================================================================
    -- Constant and Type declarations
    --============================================================================================================================

    --============================================================================================================================
    -- Component declarations
    --============================================================================================================================
    
    --============================================================================================================================
    -- Signal declarations
    --============================================================================================================================   
    signal   tx_usrclk			: std_logic								:=            '0' ;
    signal   tx_rstdone   		: std_logic_vector(NB_LANES-1 downto 0)	:= (others => '0');
	signal   tx_usrrdy          : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
    signal   rst_xcvr			: std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
    signal   xcvr_pll_lock		: std_logic_vector(NB_LANES-1 downto 0)	:= (others => '0');
	signal   xcvr_data_tx 		: std_logic_vector(SER_WIDTH*NB_LANES-1 downto 0); 


begin

	tx_clk <= tx_usrclk;

  --============================================================================================================================
  -- Instantiate TX ESIstream module
  --============================================================================================================================
  i_tx_esistream : entity work.tx_esistream
    generic map(
      NB_LANES 		=> NB_LANES
	, COMMA			=> COMMA
    ) port map (
      rst       	=> rst
    , rst_xcvr      => rst_xcvr
    , tx_rstdone   	=> tx_rstdone
    , xcvr_pll_lock	=> xcvr_pll_lock
    , tx_usrclk    	=> tx_usrclk
    , xcvr_data_tx 	=> xcvr_data_tx
	, tx_usrrdy		=> tx_usrrdy
    , sync_in   	=> sync_in
    , prbs_en   	=> prbs_en
    , disp_en   	=> disp_en
    , lfsr_init 	=> lfsr_init
    , data_in   	=> data_in
    , ip_ready  	=> ip_ready
    );
   
  --============================================================================================================================
  -- Instantiate XCVR
  --============================================================================================================================
  i_tx_xcvr_wrapper : entity work.tx_xcvr_wrapper
	generic map  (
      NB_LANES      => NB_LANES    
    ) port map (
      rst           => rst           
    , rst_xcvr      => rst_xcvr      
    , tx_rstdone    => tx_rstdone    
    , tx_usrclk     => tx_usrclk     
    , sysclk        => sysclk        
    , refclk_n      => refclk_n      
    , refclk_p      => refclk_p      
    , txp           => txp           
    , txn           => txn           
    , xcvr_pll_lock => xcvr_pll_lock 
    , tx_usrrdy     => tx_usrrdy 
    , data_in       => xcvr_data_tx
    );
  

end architecture rtl;
