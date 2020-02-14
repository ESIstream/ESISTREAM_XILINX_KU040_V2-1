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
-- Check the incoming decodede data according to the Tx generation data.
-- It should be the same TX board configuration.  
-------------------------------------------------------------------------------

library work;
use work.esistream_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rx_check is
  generic(
    NB_LANES : natural
    );
  port (
    rst        : in  std_logic;                              -- Active high reset. Allow to start test after lanes synchronized.
    clk        : in  std_logic;                              -- Receiver clock output.
    data_ctrl  : in  std_logic_vector(1 downto 0);           -- Received data control, should be the same TX board configuration.   
    frame_out  : in  rx_frame_array(NB_LANES-1 downto 0);    -- Decoded output data + clk bit + disparity bit array
    data_out   : in  rx_data_array(NB_LANES-1 downto 0);     -- Decoded output data only array
    valid_out  : in  std_logic_vector(NB_LANES-1 downto 0);  -- Active high when frame_out and data_out are valid
    ber_status : out std_logic;                              -- Active high bit error detected.
    cb_status  : out std_logic                               -- Active high clock bit error detected.
    );
end entity rx_check;

architecture rtl of rx_check is
  --============================================================================================================================
  -- Constant and Type declarations
  --============================================================================================================================
  constant SLV_NB_LANES_ALL_ONE : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  constant POSITIVE_14B_RAMP    : std_logic_vector(1 downto 0)          := "01";
  constant NEGATIVE_14B_RAMP    : std_logic_vector(1 downto 0)          := "10";
  constant ALL_14B_ONE          : std_logic_vector(1 downto 0)          := "11";
  constant ALL_14B_ZERO         : std_logic_vector(1 downto 0)          := "00";
  constant DATA_14B_0           : std_logic_vector(14-1 downto 0)       := (others => '0');
  constant DATA_14B_1           : std_logic_vector(14-1 downto 0)       := (others => '1');
  constant STEP                 : std_logic_vector(14-1 downto 0)       := std_logic_vector(to_unsigned(DESER_WIDTH/32, 14));
  constant BER_NO_ERROR         : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  constant CB_NO_ERROR          : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  type u_14_array_n is array (natural range <>) of unsigned(14-1 downto 0);
  type data_uarray is array (natural range <>) of u_14_array_n(DESER_WIDTH/16-1 downto 0);
  type slv_deser_array_n is array (natural range <>) of std_logic_vector(DESER_WIDTH/16-1 downto 0);

  --============================================================================================================================
  -- Signal declarations
  --============================================================================================================================
  signal valid_d        : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal ber            : std_logic_vector(NB_LANES-1 downto 0);
  signal cb             : std_logic_vector(NB_LANES-1 downto 0);
  --signal data_out_ddl   : rx_data_array                         := (others => (others => (others => '0')));
  signal data_out_qdl   : rx_data_array(NB_lANES-1 downto 0)    := (others => (others => (others => '0')));
  signal data_a         : rx_data_array(NB_lANES-1 downto 0)    := (others => (others => (others => '0')));
  signal data_s         : rx_data_array(NB_lANES-1 downto 0)    := (others => (others => (others => '0')));
  signal u_data_out_qdl : data_uarray(NB_LANES-1 downto 0)      := (others => (others => (others => '0')));
  signal u_data_a       : data_uarray(NB_LANES-1 downto 0)      := (others => (others => (others => '0')));
  signal u_data_s       : data_uarray(NB_LANES-1 downto 0)      := (others => (others => (others => '0')));

begin

  delay_slv_1 : entity work.delay_slv
    generic map (
      DATA_WIDTH => NB_LANES,
      LATENCY  => 2)
    port map (
      clk => clk,
      d   => valid_out,
      q   => valid_d);

  --! @brief: Compare current value to calculated value from previous value to detect a bit error.
  ber_gen : for index_lane in 0 to (NB_LANES - 1) generate
    signal sb_ber   : std_logic_vector(DESER_WIDTH/16-1 downto 0);
    signal sb_ber_d : std_logic_vector(DESER_WIDTH/16-1 downto 0);
  begin

    dl_gen : for idx in 0 to DESER_WIDTH/16-1 generate

      delay_slv_2 : entity work.delay_slv
        generic map (
          DATA_WIDTH => 14,
          LATENCY  => 3)
        port map (
          clk => clk,
          d   => data_out(index_lane)(idx),
          q   => data_out_qdl(index_lane)(idx));
      u_data_out_qdl(index_lane)(idx) <= unsigned(data_out_qdl(index_lane)(idx));

      adder_1 : entity work.add_u14
        port map(
          A   => data_out(index_lane)(idx),
          B   => STEP,
          CLK => clk,
          S   => data_a(index_lane)(idx));

      subtract_1 : entity work.sub_u14
        port map(
          A   => data_out(index_lane)(idx),
          B   => STEP,
          CLK => clk,
          CE  => '1',
          S   => data_s(index_lane)(idx));

      process(clk)
      begin
        if rising_edge(clk) then
          u_data_a(index_lane)(idx) <= unsigned(data_a(index_lane)(idx));
          u_data_s(index_lane)(idx) <= unsigned(data_s(index_lane)(idx));
        end if;
      end process;
    end generate dl_gen;

    process(clk)
    begin
      if rising_edge(clk) then
        if valid_d(index_lane) = '0' then sb_ber <= (others => '0');
        else
          for idx in 0 to DESER_WIDTH/16-1 loop
            case data_ctrl is
              when ALL_14B_ZERO =>
                if data_out(index_lane)(idx) = DATA_14B_0 then sb_ber(idx) <= '0';
                else sb_ber(idx)                                           <= '1'; end if;
              when ALL_14B_ONE =>
                if data_out(index_lane)(idx) = DATA_14B_1 then sb_ber(idx) <= '0';
                else sb_ber(idx)                                           <= '1'; end if;
              when POSITIVE_14B_RAMP =>
                if u_data_a(index_lane)(idx) = u_data_out_qdl(index_lane)(idx) then sb_ber(idx) <= '0';
                else sb_ber(idx)                                                                <= '1'; end if;

              when others =>  --NEGATIVE_14B_RAMP =>
                if u_data_s(index_lane)(idx) = u_data_out_qdl(index_lane)(idx) then sb_ber(idx) <= '0';
                else sb_ber(idx)                                                                <= '1'; end if;
            end case;
          end loop;
        end if;
      end if;
    end process;

    process(clk)
    begin
      if rising_edge(clk) then
        sb_ber_d        <= sb_ber;
        ber(index_lane) <= or1(sb_ber);
      end if;
    end process;

  end generate ber_gen;

  --! @brief: BER status should be reset to indicate a correct status.
  --! When a bit error on useful data (14-bit) is detected, then ber_status is set to 1 until reset.
  p_ber_status : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ber_status <= '0';
      elsif ber /= BER_NO_ERROR then
        ber_status <= '1';
      --else
      --  ber_status <= ber_status;
      end if;
    end if;
  end process;

  cb_gen : for index_lane in 0 to (NB_LANES - 1) generate
    signal sb_cb   : slv_deser_array_n (NB_LANES-1 downto 0);
    signal sb_cb_d : slv_deser_array_n (NB_LANES-1 downto 0);
  begin
    cb_p : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          sb_cb(index_lane) <= (others => '0');
        else
          for idx in 0 to DESER_WIDTH/16-1 loop
            sb_cb(index_lane)(idx) <= '0';
            case (idx mod 2) is
              when 0 =>
                if frame_out(index_lane)(idx)(14) = '0' then sb_cb(index_lane)(idx) <= '1'; end if;
              when others =>
                if frame_out(index_lane)(idx)(14) = '1' then sb_cb(index_lane)(idx) <= '1'; end if;
            end case;
          end loop;
        end if;
      end if;
    end process;

    process(clk)
    begin
      if rising_edge(clk) then
        sb_cb_d        <= sb_cb;
        cb(index_lane) <= or1(sb_cb(index_lane));
      end if;
    end process;
  end generate cb_gen;

  --! @brief: clock bit (CB) status should be reset to indicate a correct status.
  --! When a clock bit error is detected, then cb_status is set to 1 until reset.
  p_cb_status : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cb_status <= '0';
      elsif cb /= CB_NO_ERROR then
        cb_status <= '1';
      --else
      --  cb_status <= cb_status;
      end if;
    end if;
  end process;

end architecture rtl;
