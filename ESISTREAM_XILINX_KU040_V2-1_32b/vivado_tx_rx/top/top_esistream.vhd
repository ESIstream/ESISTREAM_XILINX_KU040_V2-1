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


entity top_esistream is
  generic(
    NB_LANES : natural                       := 4;
    COMMA    : std_logic_vector(31 downto 0) := x"FF0000FF"      -- comma for frame alignemnent (0x00FFFF00 or 0xFF0000FF).
    );
  port (
    clk_xcvr_fmc_p : in  std_logic;                              -- refclk from transceiver clock input; 
    clk_xcvr_fmc_n : in  std_logic;                              -- refclk from transceiver clock input
    clk_125mhz_p   : in  std_logic;                              -- sysclk
    clk_125mhz_n   : in  std_logic;                              -- sysclk
    fmc_xcvr_out_p : out std_logic_vector(NB_LANES-1 downto 0);  -- Serial output connected to FMC
    fmc_xcvr_out_n : out std_logic_vector(NB_LANES-1 downto 0);  -- Serial output connected to FMC
    fmc_xcvr_in_p  : in  std_logic_vector(NB_LANES-1 downto 0);  -- Serial input  connected to FMC
    fmc_xcvr_in_n  : in  std_logic_vector(NB_LANES-1 downto 0);  -- Serial input  connected to FMC
    SW_C           : in  std_logic;                              -- rst (global)            
    SW_S           : in  std_logic;                              -- sync        
    SW_W           : in  std_logic;                              -- rst check       
    SW_E           : in  std_logic;                              -- nc
    SW_N           : in  std_logic;                              -- nc
    dipswitch      : in  std_logic_vector(4 downto 1);           --
    led_usr        : out std_logic_vector(7 downto 0)            --
    );
end entity top_esistream;

architecture behavioral of top_esistream is

  --============================================================================================================================
  -- Function and Procedure declarations
  --============================================================================================================================

  --============================================================================================================================
  -- Constant and Type declarations
  --============================================================================================================================
  constant tx_lfsr_init  : slv_17_array_n(NB_LANES-1 downto 0)   := (others => (others => '1'));
  constant ALL_LANES_ON  : std_logic_vector(NB_LANES-1 downto 0) := x"F";
  constant ALL_LANES_OFF : std_logic_vector(NB_LANES-1 downto 0) := x"0";
  --============================================================================================================================
  -- Component declarations
  --============================================================================================================================

  --============================================================================================================================
  -- Signal declarations
  --============================================================================================================================
  signal rst_tx                 : std_logic                                         := '0';
  signal rst_rx                 : std_logic                                         := '0';
  signal rst_tx_pulse           : std_logic                                         := '0';
  signal rst_rx_pulse           : std_logic                                         := '0';
  --
  signal sysclk                 : std_logic                                         := '0';
  signal sync_in_rx             : std_logic                                         := '0';
  signal sync_in_tx             : std_logic                                         := '0';
  signal sync_in_rx_pulse       : std_logic                                         := '0';
  signal sync_in_tx_pulse       : std_logic                                         := '0';
  signal sync_out_rx            : std_logic                                         := '0';
  --
  signal tx_clk                 : std_logic                                         := '0';
  signal tx_d_ctrl              : std_logic_vector(1 downto 0)                      := (others => '0');
  signal tx_d_ctrl_1            : std_logic_vector(1 downto 0)                      := (others => '0');
  signal tx_d_ctrl_2            : std_logic_vector(1 downto 0)                      := (others => '0');
  signal prbs_en                : std_logic                                         := '0';
  signal tx_disp_en             : std_logic                                         := '0';
  signal tx_ip_ready            : std_logic                                         := '0';
  --
  signal rx_clk                 : std_logic                                         := '0';
  signal rx_ip_ready            : std_logic                                         := '0';
  --
  signal data_to_encode_1       : std_logic_vector(13 downto 0)                     := (others => '0');
  signal data_to_encode_2       : std_logic_vector(13 downto 0)                     := (others => '0');
  signal data_to_encode_1_64b   : std_logic_vector(13 downto 0)                     := (others => '0');
  signal data_to_encode_2_64b   : std_logic_vector(13 downto 0)                     := (others => '0');
  signal rx_data                : std_logic_vector(16*4-1 downto 0)                 := (others => '0');
  signal rx_data_valid          : std_logic                                         := '0';
  signal rx_lanes_ready         : std_logic                                         := '0';
  signal esistream_com_ready    : std_logic                                         := '0';
  --
  signal tx_data                : tx_data_array(NB_LANES-1 downto 0);
  --
  signal rst_check              : std_logic                                         := '0';
  signal data_ctrl              : std_logic_vector(1 downto 0);
  signal frame_out, frame_out_d : rx_frame_array(NB_LANES-1 downto 0);
  signal data_out, data_out_d   : rx_data_array(NB_LANES-1 downto 0);
  signal valid_out, valid_out_d : std_logic_vector(NB_LANES-1 downto 0);
  signal ber_status             : std_logic;
  signal cb_status              : std_logic;
  signal pll_locked             : std_logic;
  signal tx_rstdone             : std_logic_vector(NB_LANES-1 downto 0)             := (others => '0');
  signal rst_tx_xcvr            : std_logic_vector(NB_LANES-1 downto 0)             := (others => '0');
  signal xcvr_data_tx           : std_logic_vector(DESER_WIDTH*NB_LANES-1 downto 0) := (others => '0');
  signal xcvr_pll_lock          : std_logic_vector(NB_LANES-1 downto 0)             := (others => '0');
  signal rx_rstdone             : std_logic_vector(NB_LANES-1 downto 0)             := (others => '0');
  signal rst_rx_xcvr            : std_logic                                         := '0';
  signal xcvr_data_rx           : std_logic_vector(DESER_WIDTH*NB_LANES-1 downto 0) := (others => '0');

  attribute MARK_DEBUG                   : string;
  attribute MARK_DEBUG of prbs_en        : signal is "true";
  attribute MARK_DEBUG of tx_disp_en     : signal is "true";
  attribute MARK_DEBUG of ber_status     : signal is "true";
  attribute MARK_DEBUG of cb_status      : signal is "true";
  attribute MARK_DEBUG of tx_d_ctrl      : signal is "true";
  attribute MARK_DEBUG of tx_ip_ready    : signal is "true";
  attribute MARK_DEBUG of rx_ip_ready    : signal is "true";
  attribute MARK_DEBUG of rx_lanes_ready : signal is "true";
  attribute MARK_DEBUG of sync_in_rx     : signal is "true";
  attribute MARK_DEBUG of sync_out_rx    : signal is "true";
  attribute MARK_DEBUG of rst_check      : signal is "true";
  attribute MARK_DEBUG of valid_out      : signal is "true";
  attribute MARK_DEBUG of data_out       : signal is "true";

--
begin

  --############################################################################################################################
  --############################################################################################################################
  -- System PLL
  --############################################################################################################################
  --############################################################################################################################        
  --============================================================================================================================
  -- PLL (inclock=100MHz)
  --  c1 : 100.0MHz (must be consistent with C_SYS_CLK_PERIOD)
  --============================================================================================================================  
  i_pll_sys : entity work.clk_wiz_0
    port map (
      -- Clock out ports  
      clk_out1  => sysclk,
      -- Status and control signals                
      reset     => '0',
      locked    => pll_locked,
      -- Clock in ports
      clk_in1_p => clk_125mhz_p,
      clk_in1_n => clk_125mhz_n
      );


  --############################################################################################################################
  --############################################################################################################################
  -- User interface
  --############################################################################################################################
  --############################################################################################################################
  -- dipswitch :
  prbs_en    <= dipswitch(4);
  tx_disp_en <= dipswitch(3);
  tx_d_ctrl  <= dipswitch(2 downto 1);
  -- Push-button:
  -- Each push-button switch provides a low logic level when it is not pressed,
  -- and provides a high logic level when pressed.
  process (rx_clk, SW_W)
  begin
    if SW_W = '1' then
      rst_check <= '1';
    elsif rising_edge(rx_clk) then
      rst_check <= '0';
    end if;
  end process;
  sync_in_rx <= SW_S;
  rst_tx     <= (not pll_locked) or SW_C;
  rst_rx     <= (not pll_locked) or SW_C;
  -- leds:
  led_usr(0) <= tx_ip_ready;
  led_usr(1) <= rx_ip_ready;
  led_usr(2) <= rx_lanes_ready;
  led_usr(3) <= cb_status;
  led_usr(4) <= ber_status;
  led_usr(5) <= '0';
  led_usr(6) <= '0';
  led_usr(7) <= '0';

--############################################################################################################################
--############################################################################################################################
-- TX side
--############################################################################################################################
--############################################################################################################################   
  --============================================================================================================================
  -- Generation data
  --============================================================================================================================  
  data_gen_inst_1 : entity work.data_gen
    port map (
      nrst         => tx_ip_ready,
      clk          => tx_clk,
      d_ctrl       => tx_d_ctrl_1,
      data_out     => data_to_encode_1,
      data_out_64b => data_to_encode_1_64b
      );
  tx_d_ctrl_1 <= tx_d_ctrl;

  data_gen_inst_2 : entity work.data_gen
    port map (
      nrst         => tx_ip_ready,
      clk          => tx_clk,
      d_ctrl       => tx_d_ctrl_2,
      data_out     => data_to_encode_2,
      data_out_64b => data_to_encode_2_64b
      );
  tx_d_ctrl_2 <= tx_d_ctrl;  --not tx_d_ctrl;

  gen_data_32b : if SER_WIDTH = 32 generate
  begin
    process(data_to_encode_1, data_to_encode_2)
    begin
      for idx_lane in 0 to NB_LANES-1 loop
        for idx in 0 to SER_WIDTH/16-1 loop
          case (idx mod 2) is
            when 0      => tx_data(idx_lane)(idx) <= data_to_encode_1;
            when others => tx_data(idx_lane)(idx) <= data_to_encode_2;
          end case;
        end loop;
      end loop;
    end process;
  end generate gen_data_32b;

  gen_data_64b : if SER_WIDTH = 64 generate
  begin
    process(data_to_encode_1, data_to_encode_2, data_to_encode_1_64b, data_to_encode_2_64b)
    begin
      for idx_lane in 0 to NB_LANES-1 loop
        for idx in 0 to SER_WIDTH/16-1 loop
          case idx is
            when 0      => tx_data(idx_lane)(idx) <= data_to_encode_1;
            when 1      => tx_data(idx_lane)(idx) <= data_to_encode_2;
            when 2      => tx_data(idx_lane)(idx) <= data_to_encode_1_64b;
            when others => tx_data(idx_lane)(idx) <= data_to_encode_2_64b;
          end case;
        end loop;
      end loop;
    end process;
  end generate gen_data_64b;

  --============================================================================================================================
  -- rst_tx EDGE DETECT
  --============================================================================================================================
  edge_detect_1 : entity work.edge_detect
    generic map (
      EDGE_TYPE => "RISING"
      ) port map (
        clk           => sysclk,
        din           => rst_tx,
        edge_detected => rst_tx_pulse
        );

  --============================================================================================================================
  -- sync_in_tx EDGE DETECT
  --============================================================================================================================
  sync_in_tx <= sync_out_rx;
  edge_detect_2 : entity work.edge_detect
    generic map (
      EDGE_TYPE => "RISING"
      ) port map (
        clk           => tx_clk,
        din           => sync_in_tx,
        edge_detected => sync_in_tx_pulse
        );

  --============================================================================================================================
  -- TX ESIstream IP
  --============================================================================================================================
  tx_esistream_inst : entity work.tx_esistream
    generic map(
      NB_LANES => 4,
      COMMA    => X"FF0000FF"
      ) port map (
        rst           => rst_tx_pulse,
        rst_xcvr      => rst_tx_xcvr,
        tx_rstdone    => tx_rstdone,
        xcvr_pll_lock => xcvr_pll_lock,
        tx_usrclk     => tx_clk,
        xcvr_data_tx  => xcvr_data_tx,
        tx_usrrdy     => open,
        sync_in       => sync_in_tx_pulse,
        prbs_en       => prbs_en,
        disp_en       => tx_disp_en,
        lfsr_init     => tx_lfsr_init,
        data_in       => tx_data,
        ip_ready      => tx_ip_ready
        );

--############################################################################################################################
--############################################################################################################################
-- GTH Part
--############################################################################################################################
--############################################################################################################################
  rx_tx_xcvr_wrapper_i : entity work.rx_tx_xcvr_wrapper
    generic map(
      NB_LANES => NB_LANES
      )
    port map(
      rst           => rst_tx,
      rst_tx_xcvr   => rst_tx_xcvr,
      tx_rstdone    => tx_rstdone,
      tx_usrclk     => tx_clk,
      rst_rx_xcvr   => rst_rx_xcvr,
      rx_rstdone    => rx_rstdone,
      rx_usrclk     => rx_clk,
      sysclk        => sysclk,
      refclk_n      => clk_xcvr_fmc_n,
      refclk_p      => clk_xcvr_fmc_p,
      xcvr_pll_lock => xcvr_pll_lock,
      txp           => fmc_xcvr_out_p,
      txn           => fmc_xcvr_out_n,
      tx_usrrdy     => (others => '1'),
      data_in       => xcvr_data_tx,
      rxp           => fmc_xcvr_in_p,
      rxn           => fmc_xcvr_in_n,
      data_out      => xcvr_data_rx
      );


--############################################################################################################################
--############################################################################################################################
-- RX side
--############################################################################################################################
--############################################################################################################################
  --============================================================================================================================
  -- rst_rx_pulse
  --============================================================================================================================
  edge_detect_3 : entity work.edge_detect
    generic map (
      EDGE_TYPE => "RISING"
      ) port map (
        clk           => sysclk,
        din           => rst_rx,
        edge_detected => rst_rx_pulse
        );

  --============================================================================================================================
  -- sync_in_rx_pulse
  --============================================================================================================================
  edge_detect_4 : entity work.edge_detect
    generic map (
      EDGE_TYPE => "RISING")
    port map (
      clk           => sysclk,
      din           => sync_in_rx,
      edge_detected => sync_in_rx_pulse
      );

  --============================================================================================================================
  -- ESIstream RX IP
  --============================================================================================================================
  rx_esistream_inst : entity work.rx_esistream
    generic map(
      NB_LANES   => NB_LANES,
      SYNC_DELAY => 2,
      COMMA      => x"FF0000FF"
      ) port map(
        rst           => rst_rx_pulse,
        rst_xcvr      => rst_rx_xcvr,
        rx_rstdone    => rx_rstdone,
        xcvr_pll_lock => xcvr_pll_lock,
        rx_usrclk     => rx_clk,
        xcvr_data_rx  => xcvr_data_rx,
        sync_in       => sync_in_rx_pulse,
        prbs_en       => prbs_en,
        lanes_on      => ALL_LANES_ON,
        read_data_en  => rx_lanes_ready,
        clk_acq       => rx_clk,
        sync_out      => sync_out_rx,
        frame_out     => frame_out,
        data_out      => data_out,
        valid_out     => valid_out,
        ip_ready      => rx_ip_ready,
        lanes_ready   => rx_lanes_ready
        );

  --============================================================================================================================
  -- my tb results
  --============================================================================================================================ 
  --
  process(rx_clk)
  begin
    if rising_edge(rx_clk) then
      frame_out_d <= frame_out;
      data_out_d  <= data_out;
      valid_out_d <= valid_out;
    end if;
  end process;
  --
  i_rx_check : entity work.rx_check
    generic map (
      NB_LANES => NB_LANES
      ) port map (
        rst        => rst_check,
        clk        => rx_clk,
        data_ctrl  => tx_d_ctrl,
        frame_out  => frame_out_d,
        data_out   => data_out_d,
        valid_out  => valid_out_d,
        ber_status => ber_status,
        cb_status  => cb_status
        );

end behavioral;
