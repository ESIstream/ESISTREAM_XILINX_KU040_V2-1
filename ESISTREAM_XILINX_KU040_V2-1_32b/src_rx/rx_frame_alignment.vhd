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
-------------------------------------------------------------------------------
library work;
use work.esistream_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity rx_frame_alignment is
  generic (
    --DESER_WIDTH : integer                       := 32;                -- Deserialization factor / For ESIstream 16
    COMMA       : std_logic_vector(31 downto 0) := X"00FFFF00"        -- COMMA to look for  
    );
  port (
    clk              : in  std_logic;
    rst              : in  std_logic;
    din              : in  std_logic_vector(DESER_WIDTH-1 downto 0);  -- Input misaligned frames 
    sync             : in  std_logic;                                 -- Pulse when start synchronization
    align_busy       : out std_logic;
    aligned_data     : out slv_16_array_n(0 to (DESER_WIDTH/16)-1);  -- Output aligned frames
    aligned_data_rdy : out std_logic                                  -- Indicates that frame alignment is done
    );
end entity rx_frame_alignment;

architecture rtl of rx_frame_alignment is
  --signal NCOMMA         : std_logic_vector(31 downto 0) := (COMMA);
  signal data_buf       : std_logic_vector(DESER_WIDTH*2-1 downto 0) := (others => '0');  -- buffer used to get aligned data
  signal data_buf_comma : std_logic_vector(DESER_WIDTH*2-1 downto 0) := (others => '0');  -- buffer used to look for COMMA
  signal bitslip        : std_logic_vector(4 downto 0)               := (others => '0');  -- number of bit slip to align frames

  signal data_out_t    : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');
  signal frame_align_t : std_logic                                := '0';              -- If '1' frame alignment done
  signal frame_align_d : std_logic                                := '0';              -- If '1' frame alignment done
  signal busy          : std_logic                                := '0';              -- If '1', frame alignment in progress
  signal bitslip_t     : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');  -- Temp bitslip

begin

-- Output affectations
  align_busy       <= busy;
  
  gen_aligned_data : for index in 0 to (DESER_WIDTH/16)-1 generate
    aligned_data(index)  <= data_out_t((15 + 16*index) downto (0+16*index));
  end generate gen_aligned_data; 
  --aligned_data(0)  <= data_out_t(15 downto 0);
  --aligned_data(1)  <= data_out_t(31 downto 16);
  aligned_data_rdy <= frame_align_d;


  process(clk)
  begin
    if rising_edge(clk) then
      frame_align_d <= frame_align_t;

      -- Normal operation
      data_out_t <= data_buf(conv_integer(bitslip)+DESER_WIDTH downto conv_integer(bitslip)+1);
      
      data_buf(2*DESER_WIDTH-1 downto DESER_WIDTH) <= din;
      data_buf(DESER_WIDTH-1 downto 0)             <= data_buf(2*DESER_WIDTH-1 downto DESER_WIDTH);

      data_buf_comma(2*DESER_WIDTH-1 downto DESER_WIDTH) <= din;
      data_buf_comma(DESER_WIDTH-1 downto 0)             <= data_buf_comma(2*DESER_WIDTH-1 downto DESER_WIDTH);

      -- Alignment is asked
      if sync = '1' then
        frame_align_t <= '0';
        busy          <= '1';
        bitslip_t     <= (others => '0');
      -- COMMA is looked for    
      elsif busy = '1' then
        for i in COMMA'length-1 downto 0 loop

          if data_buf_comma(i+COMMA'length downto i+1) = (COMMA) then
            bitslip_t(i) <= '1';
          else
            bitslip_t(i) <= '0';
          end if;

          if bitslip_t(i) = '1' then
            bitslip       <= conv_std_logic_vector(i, bitslip'length);
            frame_align_t <= '1';
            busy          <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process;

end architecture rtl;
