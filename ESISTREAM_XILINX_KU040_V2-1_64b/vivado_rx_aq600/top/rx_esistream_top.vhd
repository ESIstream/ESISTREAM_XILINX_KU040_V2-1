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

library work;
use work.esistream_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rx_esistream_top is
  generic(
    NB_CLK_CYC : std_logic_vector(31 downto 0) := x"0FFFFFFF"
    );
  port (
    aq600_sso_n : in std_logic;  -- mgtrefclk from transceiver clock input
    aq600_sso_p : in std_logic;  -- mgtrefclk from transceiver clock input

    clk_125mhz_p : in std_logic;  -- sysclk
    clk_125mhz_n : in std_logic;  -- sysclk

    ASLp : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    ASLn : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    BSLp : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    BSLn : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    CSLp : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    CSLn : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    DSLp : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes
    DSLn : in std_logic_vector(1 downto 0);  -- Serial input for NB_LANES lanes

    SW_C : in std_logic;  -- Active high asynchronous reset
    SW_S : in std_logic;  -- Active high asynchronous reset
    SW_W : in std_logic;  -- Active high asynchronous reset
    SW_E : in std_logic;  -- Active high asynchronous reset
    SW_N : in std_logic;  -- Active high asynchronous reset

    --bp                        : in    std_logic_vector(5 downto 1);            --
    dipswitch : in  std_logic_vector(4 downto 1);  --
    led_usr   : out std_logic_vector(7 downto 0);

    -- Kurth Module:
    aq600_rstn       : out std_logic;
    aq600_spi_sclk   : out std_logic;
    aq600_spi_csn    : out std_logic;  -- EV12AQ600  
    CSN_PLL          : out std_logic;  -- LMX2592 PLL
    aq600_spi_mosi   : out std_logic;
    --aq600_spi_miso     : in  std_logic;
    --VTEMP_DUT          : in  std_logic;
    --Viref_RTH          : in  std_logic;
    PLL_LOCK         : in  std_logic;
    aq600_synco_p    : in  std_logic;
    aq600_synco_n    : in  std_logic;
    aq600_synctrig_p : out std_logic;
    aq600_synctrig_n : out std_logic
    );
end entity rx_esistream_top;


architecture rtl of rx_esistream_top is

  --------------------------------------------------------------------------------------------------------------------
  --! signal name description:
  -- _sr = _shift_register
  -- _re = _rising_edge (one clk period pulse generated on the rising edge of the initial signal)
  -- _fe = _falling_edge (one clk period pulse generated on the falling edge of the initial signal)
  -- _d  = _delay
  -- _2d = _delay x2
  -- _ba = _bitwise_and
  -- _sw = _slide_window
  -- _o  = _output
  -- _i  = _input
  -- _t  = _temporary 
  -- _a  = _asychronous (fsm output decode signal)
  -- _s  = _synchronous (fsm synchronous output signal)
  -- _rs = _resynchronized (when there is a clock domain crossing)
  --------------------------------------------------------------------------------------------------------------------
  --attribute KEEP                : string;
  constant NB_LANES             : natural                               := 8;
  constant ALL_LANES_ON         : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  constant ALL_LANES_OFF        : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal sysclk                 : std_logic                             := '0';
  signal syslock                : std_logic                             := '0';
  signal rx_clk                 : std_logic                             := '0';
  signal sysrx_clk              : std_logic                             := '0';
  signal rst                    : std_logic                             := '0';
  signal rst_pulse              : std_logic                             := '0';
  signal rst_check              : std_logic                             := '0';
  signal rst_check_pulse        : std_logic                             := '0';
  signal sync_in                : std_logic                             := '0';
  signal sync_in_pulse          : std_logic                             := '0';
  signal synctrig_re            : std_logic                             := '0';
  signal synctrig_debug         : std_logic                             := '0';
  signal ip_ready               : std_logic                             := '0';
  signal lanes_ready            : std_logic                             := '0';
  signal prbs_en                : std_logic                             := '1';
  --
  signal wf                     : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal sdr                    : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal adr                    : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal lr                     : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  signal rec_clock              : std_logic                             := '0';
  signal rec_clock_o            : std_logic                             := '0';
  signal sysrst                 : std_logic                             := '1';
  signal sysnrst                : std_logic                             := '1';
  signal scl_o                  : std_logic                             := '0';
  signal scl_i                  : std_logic                             := '0';
  signal scl_t                  : std_logic                             := '0';
  signal sda_o                  : std_logic                             := '0';
  signal sda_i                  : std_logic                             := '0';
  signal sda_t                  : std_logic                             := '0';
  signal busy                   : std_logic                             := '0';
  --
  signal frame_out              : rx_frame_array(NB_LANES-1 downto 0);
  signal data_out               : rx_data_array(NB_LANES-1 downto 0);
  signal valid_out              : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  signal fifo_dout              : data_array(NB_LANES-1 downto 0);
  signal fifo_rd_en             : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal fifo_empty             : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  signal ber_status             : std_logic                             := '0';
  signal cb_status              : std_logic                             := '0';
  --
  signal rxp                    : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');  -- lane serial input p
  signal rxn                    : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');  -- lane Serial input n
  --
  signal aq600_prbs_en          : std_logic                             := '1';
  signal start_stop_event       : std_logic                             := '0';
  signal change_data_mode       : std_logic                             := '0';
  signal start_stop_event_pulse : std_logic                             := '0';
  signal change_data_mode_pulse : std_logic                             := '0';
  signal data_en                : std_logic                             := '1';
  signal dc_balance_en          : std_logic                             := '1';
  signal isrunning              : std_logic                             := '0';
  signal pll_lock_i             : std_logic                             := '0';
  signal pll_external           : std_logic                             := '0';
  signal otp_en                 : std_logic                             := '0';
  signal clk_acq                : std_logic                             := '0';
  signal ila_lane_select        : std_logic_vector(2 downto 0)          := (others => '0');
  --
  signal ila_probe0, probe0     : std_logic_vector(11 downto 0)         := (others => '0');
  signal ila_probe1, probe1     : std_logic_vector(11 downto 0)         := (others => '0');
  --
  constant c_all_tied_1         : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  signal all_valid              : std_logic                             := '0';
  signal ila_buffer_1_empty     : std_logic                             := '0';
  signal ila_buffer_1_rd_en     : std_logic                             := '0';
  signal ila_buffer_0_empty     : std_logic                             := '0';
  signal ila_buffer_0_rd_en     : std_logic                             := '0';

  signal s_rst_cntr     : std_logic_vector(11 downto 0) := (others => '1');
  signal s_rst_pll_cntr : std_logic_vector(3 downto 0)  := (others => '1');
  signal s_reset_i      : std_logic                     := '0';
  signal rst_rx_mux     : std_logic                     := '0';
  signal rst_pll        : std_logic                     := '1';
  signal rst_aq600      : std_logic                     := '1';
  signal aq600_rstn_i   : std_logic;

  type rx_data_array_12b is array (natural range <>) of slv_12_array_n(DESER_WIDTH/16-1 downto 0);
  signal data_out_12b : rx_data_array_12b(NB_LANES-1 downto 0);

  attribute MARK_DEBUG                           : string;
  attribute MARK_DEBUG of syslock                : signal is "true";
  attribute MARK_DEBUG of rst                    : signal is "true";
  attribute MARK_DEBUG of start_stop_event       : signal is "true";
  attribute MARK_DEBUG of sync_in                : signal is "true";
  attribute MARK_DEBUG of rst_check              : signal is "true";
  attribute MARK_DEBUG of ip_ready               : signal is "true";
  attribute MARK_DEBUG of isrunning              : signal is "true";
  attribute MARK_DEBUG of lanes_ready            : signal is "true";
  attribute MARK_DEBUG of cb_status              : signal is "true";
  attribute MARK_DEBUG of ber_status             : signal is "true";
  attribute MARK_DEBUG of start_stop_event_pulse : signal is "true";
  attribute MARK_DEBUG of data_out_12b           : signal is "true";
  attribute MARK_DEBUG of valid_out              : signal is "true";
  attribute MARK_DEBUG of pll_external           : signal is "true";
  attribute MARK_DEBUG of prbs_en                : signal is "true";
  attribute MARK_DEBUG of data_en                : signal is "true";
  attribute MARK_DEBUG of dc_balance_en          : signal is "true";
--

begin
  --
  --------------------------------------------------------------------------------------------
  -- User interface:
  --------------------------------------------------------------------------------------------
  --############################################################################################################################
  --############################################################################################################################
  -- System PLL / Reset
  --############################################################################################################################
  --############################################################################################################################  
  --============================================================================================================================
  -- PLL (inclock=125MHz)
  --  c1 : 100.0MHz (must be consistent with C_SYS_CLK_PERIOD)
  --============================================================================================================================  
  i_pll_sys : entity work.clk_wiz_0
    port map (
      -- Clock out ports  
      clk_out1  => sysclk,
      -- Status and control signals                
      reset     => '0',
      locked    => syslock,
      -- Clock in ports
      clk_in1_p => clk_125mhz_p,
      clk_in1_n => clk_125mhz_n
      );


  process(syslock, sysclk)
  begin
    if syslock = '0' then
      s_rst_cntr <= (others => '1');
      s_reset_i  <= '1';

    elsif rising_edge(sysclk) then
      if s_rst_cntr /= "000000000000" then
        s_rst_cntr <= std_logic_vector(unsigned(s_rst_cntr) - 1);
      end if;

      -- Global POR reset.
      if s_rst_cntr /= "000000000000" then
        s_reset_i <= '1';
      else
        s_reset_i <= '0';
      end if;
    end if;
  end process;


  rst_rx_mux <= rst_pulse or s_reset_i or (not aq600_rstn_i);

  rst_aq600 <= rst or s_reset_i;

  aq600_rstn <= aq600_rstn_i;



  --
  -- Push buttons
  rst              <= SW_C;
  sync_in          <= SW_S;
  rst_check        <= SW_W;
  start_stop_event <= SW_E;
  change_data_mode <= SW_N;



  -- 
  -- SW2 switch
  ila_lane_select(0) <= '0';  --dipswitch_b(1);
  ila_lane_select(1) <= '0';  --dipswitch_b(2);
  ila_lane_select(2) <= '0';  --dipswitch_b(3);
  otp_en             <= '1';  --dipswitch_b(4);

  pll_external  <= dipswitch(3);  -- '1'
  prbs_en       <= dipswitch(4);  -- '1'
  data_en       <= dipswitch(2);  -- '1'
  dc_balance_en <= dipswitch(1);  -- '1'
  --
  -- leds
  led_usr(0)    <= not rst;
  led_usr(1)    <= not sync_in;
  led_usr(2)    <= ip_ready;
  led_usr(3)    <= lanes_ready;
  led_usr(4)    <= isrunning;
  led_usr(5)    <= '0';
  led_usr(6)    <= ber_status;
  led_usr(7)    <= cb_status;


  --
  -- external pll 
  pll_lock_i <= PLL_LOCK;

  --------------------------------------------------------------------------------------------
  central_pushbutton_inst : entity work.pushbutton_request
    generic map(
      NB_CLK_CYC => NB_CLK_CYC  -- Reduce to X"00000008" to speed up simulation time
      )
    port map (
      pushbutton_in => rst,
      clk           => sysclk,
      request       => rst_pulse
      );

  south_pushbutton_inst : entity work.pushbutton_request
    generic map(
      NB_CLK_CYC => NB_CLK_CYC  -- Reduce to X"00000008" to speed up simulation time
      )
    port map (
      pushbutton_in => sync_in,
      clk           => rx_clk,
      request       => sync_in_pulse
      );

  west_pushbutton_inst : entity work.pushbutton_request
    generic map(
      NB_CLK_CYC => NB_CLK_CYC  -- Reduce to X"00000008" to speed up simulation time
      )
    port map (
      pushbutton_in => rst_check,
      clk           => rx_clk,
      request       => rst_check_pulse
      );

  est_pushbutton_inst : entity work.pushbutton_request
    generic map(
      NB_CLK_CYC => NB_CLK_CYC  -- Reduce to X"00000008" to speed up simulation time
      )
    port map (
      pushbutton_in => change_data_mode,
      clk           => sysclk,
      request       => change_data_mode_pulse
      );

  north_pushbutton_inst : entity work.pushbutton_request
    generic map(
      NB_CLK_CYC => NB_CLK_CYC  -- Reduce to X"00000008" to speed up simulation time
      )
    port map (
      pushbutton_in => start_stop_event,
      clk           => sysclk,
      request       => start_stop_event_pulse
      );


  --------------------------------------------------------------------------------------------
  -- ESIstream, receiver (rx) IP: 
  --------------------------------------------------------------------------------------------
  rxn(0) <= ASLn(0);
  rxp(0) <= ASLp(0);
  rxn(1) <= ASLn(1);
  rxp(1) <= ASLp(1);
  rxn(2) <= BSLn(0);
  rxp(2) <= BSLp(0);
  rxn(3) <= BSLn(1);
  rxp(3) <= BSLp(1);
  rxn(4) <= CSLn(0);
  rxp(4) <= CSLp(0);
  rxn(5) <= CSLn(1);
  rxp(5) <= CSLp(1);
  rxn(6) <= DSLn(0);
  rxp(6) <= DSLp(0);
  rxn(7) <= DSLn(1);
  rxp(7) <= DSLp(1);
  --


  --============================================================================================================================
  -- ESIstream RX IP
  --============================================================================================================================
  rx_esistream_inst : entity work.rx_esistream_with_xcvr
    generic map(
      NB_LANES => NB_LANES
, SYNC_DELAY   => 2
, COMMA        => x"FF0000FF"
      ) port map(
        rst    => rst_rx_mux  --rst_rx_pulse
, sysclk       => sysclk
, refclk_n     => aq600_sso_n
, refclk_p     => aq600_sso_p
, rxn          => rxn
, rxp          => rxp
, sync_in      => synctrig_re
, prbs_en      => prbs_en
, lanes_on     => ALL_LANES_ON
, read_data_en => lanes_ready
, clk_acq      => rx_clk
, rx_clk       => rx_clk
, sync_out     => open
, frame_out    => frame_out
, data_out     => data_out
, valid_out    => valid_out
, ip_ready     => ip_ready
, lanes_ready  => lanes_ready
        );

  -- Used for ILA only to display the ramp waveform using analog view in vivado simulator:
  lanes_assign : for i in 0 to NB_LANES-1 generate
    channel_assign : for j in 0 to DESER_WIDTH/16-1 generate
      data_out_12b(i)(j) <= data_out(i)(j)(12-1 downto 0);
    end generate channel_assign;
  end generate lanes_assign;

  rx_check_1 : entity work.rx_check_aq600
    generic map (
      NB_LANES => NB_LANES)
    port map (
      rst        => rst_check_pulse,
      clk        => rx_clk,
      frame_out  => frame_out,
      data_out   => data_out,
      valid_out  => valid_out,
      ber_status => ber_status,
      cb_status  => cb_status);


  aq600_interface_1 : entity work.aq600_interface
    generic map (
      CLK_MHz              => 100.0,
      SPI_CLK_MHz          => 5.0,
      SYNCTRIG_PULSE_WIDTH => 7)
    port map (
      clk              => sysclk,
      rst              => rst_aq600,
      rx_clk           => rx_clk,
      pll_spi_ncs      => CSN_PLL,
      pll_lock         => pll_lock_i,
      pll_external     => pll_external,
      otp_en           => otp_en,
      aq600_rstn       => aq600_rstn_i,
      aq600_spi_ncs    => aq600_spi_csn,
      aq600_spi_sclk   => aq600_spi_sclk,
      aq600_spi_mosi   => aq600_spi_mosi,
      aq600_spi_miso   => '0',
      aq600_synctrig_p => aq600_synctrig_p,
      aq600_synctrig_n => aq600_synctrig_n,
      aq600_synco_p    => aq600_synco_p,
      aq600_synco_n    => aq600_synco_n,
      sync_in          => sync_in_pulse,
      synctrig_re      => synctrig_re,
      synctrig_debug   => synctrig_debug,
      start_stop_event => start_stop_event_pulse,
      change_data_mode => change_data_mode_pulse,
      prbs_en          => prbs_en,
      data_en          => data_en,
      dc_balance_en    => dc_balance_en,
      isrunning        => isrunning);


end architecture rtl;
