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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity aq600_interface is
  generic(
    CLK_MHz              : real    := 100.0;
    SPI_CLK_MHz          : real    := 10.0;
    SYNCTRIG_PULSE_WIDTH : integer := 7
    );
  port (
    -- clock and reset
    clk              : in  std_logic := 'X';
    rst              : in  std_logic := 'X';
    rx_clk           : in  std_logic := 'X';
    -- pll interface
    pll_spi_ncs      : out std_logic;
    pll_lock         : in  std_logic;
    -- fsm control   
    pll_external     : in  std_logic;
    otp_en           : in  std_logic;
    -- spi interface
    aq600_rstn       : out std_logic;
    aq600_spi_ncs    : out std_logic;
    aq600_spi_sclk   : out std_logic;
    aq600_spi_mosi   : out std_logic;
    aq600_spi_miso   : in  std_logic;
    --
    aq600_synctrig_p : out std_logic;
    aq600_synctrig_n : out std_logic;
    aq600_synco_p    : in  std_logic;
    aq600_synco_n    : in  std_logic;
    sync_in          : in  std_logic;
    synctrig_re      : out std_logic;
    synctrig_debug   : out std_logic;
    -- push button:
    start_stop_event : in  std_logic;  -- when idle : start event, when runnin : stop event
    change_data_mode : in  std_logic;
    -- registers signal:
    prbs_en          : in  std_logic := '1';
    data_en          : in  std_logic := '1';
    dc_balance_en    : in  std_logic := '1';
    --
    isrunning        : out std_logic
    );
end aq600_interface;

architecture rtl of aq600_interface is
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
  -- _t  = _temporary 
  -- _a  = _asychronous (fsm output decode signal)
  -- _s  = _synchronous (fsm synchronous output signal)
  -- _rs = _resynchronized (when there is a clock domain crossing)
  --------------------------------------------------------------------------------------------------------------------
  --
  constant SPI_CMD_OTP_LOAD              : std_logic_vector(1 downto 0) := "00";
  constant SPI_CMD_RAMP_MODE             : std_logic_vector(1 downto 0) := "01";
  constant SPI_CMD_DATA_MODE             : std_logic_vector(1 downto 0) := "10";
  --
  type state_type is (st_idle, st_spi_pll, st_rstn, st_otp_wu, st_spi_otp, st_spi_ramp, st_spi_data, st_sync, st_isrunning);
  signal state, next_state               : state_type;
  --
  signal spi_ncs2                        : std_logic                    := '0';
  signal spi_ncs1                        : std_logic                    := '0';
  signal spi_sclk                        : std_logic                    := '0';
  signal spi_mosi                        : std_logic                    := '0';
  signal spi_miso                        : std_logic                    := '0';
  signal spi_ncs1_re                     : std_logic                    := '0';
  signal spi_busy                        : std_logic                    := '0';
  --
  signal timer1_done, timer2_done        : std_logic                    := '0';
  --
  signal timer1_start_a, timer1_start_s  : std_logic                    := '0';
  signal timer2_start_a, timer2_start_s  : std_logic                    := '0';
  signal spi_enable_a, spi_enable_s      : std_logic                    := '0';
  signal send_sync_a, send_sync_s        : std_logic                    := '0';
  signal rstn_a, rstn_s                  : std_logic                    := '0';
  signal spi_cmd_a, spi_cmd_s, spi_cmd_d : std_logic_vector(1 downto 0) := (others => '0');
  signal isrunning_a, isrunning_s        : std_logic                    := '0';
  signal spi_ss_a, spi_ss_s              : std_logic                    := '0';
  --
  signal spi_start, spi_start_re         : std_logic                    := '0';
  --
  signal synctrig                        : std_logic                    := '0';
  signal synco                           : std_logic                    := '0';
  signal send_sync_rs                    : std_logic                    := '0';
  
  attribute MARK_DEBUG 							: string;
  attribute MARK_DEBUG of state					: signal is "true";
  attribute MARK_DEBUG of next_state			: signal is "true";
  
--
begin

  ------------------------------------------------------------------------------------------------------------
  --! clk clock domain:
  ------------------------------------------------------------------------------------------------------------
  SYNC_PROC : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state          <= st_idle;
        rstn_s         <= '0';
        timer1_start_s <= '0';
        timer2_start_s <= '0';
        spi_enable_s   <= '0';
        send_sync_s    <= '0';
        spi_ss_s       <= '0';
        spi_cmd_s      <= SPI_CMD_OTP_LOAD;
        isrunning_s    <= '0';
      else
        state          <= next_state;
        rstn_s         <= rstn_a;
        timer1_start_s <= timer1_start_a;
        timer2_start_s <= timer2_start_a;
        spi_enable_s   <= spi_enable_a;
        send_sync_s    <= send_sync_a;
        spi_ss_s       <= spi_ss_a;
        spi_cmd_s      <= spi_cmd_a;
        isrunning_s    <= isrunning_a;
      end if;
    end if;
  end process;

  --MOORE State-Machine - Outputs based on state only
  OUTPUT_DECODE : process (state)
  begin
    if state = st_idle then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '0';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_OTP_LOAD;
      isrunning_a    <= '0';
      spi_ss_a       <= '1';
    elsif state = st_spi_pll then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '1';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_OTP_LOAD;
      isrunning_a    <= '0';
      spi_ss_a       <= '1';
    elsif state = st_rstn then
      rstn_a         <= '0';
      timer1_start_a <= '1';
      timer2_start_a <= '0';
      spi_enable_a   <= '0';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_OTP_LOAD;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    elsif state = st_otp_wu then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '1';
      spi_enable_a   <= '0';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_OTP_LOAD;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    elsif state = st_spi_otp then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '1';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_OTP_LOAD;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    elsif state = st_spi_ramp then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '1';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_RAMP_MODE;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    elsif state = st_sync then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '0';
      send_sync_a    <= '1';
      spi_cmd_a      <= SPI_CMD_RAMP_MODE;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    elsif state = st_isrunning then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '0';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_RAMP_MODE;
      isrunning_a    <= '1';
      spi_ss_a       <= '0';
    elsif state = st_spi_data then
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '1';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_DATA_MODE;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    else
      rstn_a         <= '1';
      timer1_start_a <= '0';
      timer2_start_a <= '0';
      spi_enable_a   <= '0';
      send_sync_a    <= '0';
      spi_cmd_a      <= SPI_CMD_OTP_LOAD;
      isrunning_a    <= '0';
      spi_ss_a       <= '0';
    end if;
  end process;

  NEXT_STATE_DECODE : process (state, start_stop_event, timer1_done, timer2_done, spi_ncs1_re, change_data_mode, pll_lock, spi_busy, pll_external, otp_en)
  begin

    next_state <= state;

    case state is
      when st_idle =>
        if start_stop_event = '1' then
          if pll_external = '1' then
            next_state <= st_spi_pll;
          else
            next_state <= st_rstn;
          end if;
        else
          next_state <= st_idle;
        end if;

      when st_spi_pll =>
        if spi_busy = '0' and pll_lock = '1' then
          next_state <= st_rstn;
        else
          next_state <= st_spi_pll;
        end if;

      when st_rstn =>
        if timer1_done = '1' then
          next_state <= st_otp_wu;
        else
          next_state <= st_rstn;
        end if;

      when st_otp_wu =>
        if timer2_done = '1' then
          if otp_en = '1' then
            next_state <= st_spi_otp;
          else
            next_state <= st_spi_ramp;
          end if;
        else
          next_state <= st_otp_wu;
        end if;

      when st_spi_otp =>
        if spi_ncs1_re = '1' then
          next_state <= st_spi_ramp;
        else
          next_state <= st_spi_otp;
        end if;

      when st_spi_ramp =>
        if spi_ncs1_re = '1' then
          next_state <= st_sync;
        else
          next_state <= st_spi_ramp;
        end if;

      when st_sync =>
        next_state <= st_isrunning;

      when st_isrunning =>
        if start_stop_event = '1' then
          next_state <= st_idle;
        elsif change_data_mode = '1' then
          next_state <= st_spi_data;
        else
          next_state <= st_isrunning;
        end if;

      when st_spi_data =>
        if spi_ncs1_re = '1' then
          next_state <= st_sync;
        else
          next_state <= st_spi_data;
        end if;

      when others =>
        next_state <= st_idle;

    end case;
  end process;

  timer_1 : entity work.timer
    generic map (
      CLK_FREQUENCY_HZ => (integer(CLK_MHz)*1000000),
      TIME_US          => 1000)
    port map (
      rst         => rst,
      clk         => clk,
      timer_start => timer1_start_s,
      timer_busy  => open,
      timer_done  => timer1_done);

  timer_2 : entity work.timer
    generic map (
      CLK_FREQUENCY_HZ => (integer(CLK_MHz)*1000000),
      TIME_US          => 2000)
    port map (
      rst         => rst,
      clk         => clk,
      timer_start => timer2_start_s,
      timer_busy  => open,
      timer_done  => timer2_done);

  spi_dual_master_1 : entity work.spi_dual_master
    generic map (
      CLK_MHz     => CLK_MHz,
      SPI_CLK_MHz => SPI_CLK_MHz)
    port map (
      clk           => clk,
      rst           => rst,
      spi_ncs1      => spi_ncs1,
      spi_ncs2      => spi_ncs2,
      spi_sclk      => spi_sclk,
      spi_mosi      => spi_mosi,
      spi_miso      => spi_miso,
      spi_ss        => spi_ss_s,
      spi_start     => spi_start_re,
      spi_cmd       => spi_cmd_s,
      spi_busy      => spi_busy,
      prbs_en       => prbs_en,
      data_en       => data_en,
      dc_balance_en => dc_balance_en);

  aq600_rstn     <= rstn_s;
  aq600_spi_ncs  <= spi_ncs1;
  aq600_spi_sclk <= spi_sclk;
  aq600_spi_mosi <= spi_mosi;
  spi_miso       <= aq600_spi_miso;
  pll_spi_ncs    <= spi_ncs2;

  risingedge_1 : entity work.risingedge
    port map (
      rst => rst,
      clk => clk,
      d   => spi_ncs1,
      re  => spi_ncs1_re);

  risingedge_2 : entity work.risingedge
    port map (
      rst => rst,
      clk => clk,
      d   => spi_start,
      re  => spi_start_re);

  p_start_memo : process (clk)
  begin
    if rising_edge(clk) then
      spi_cmd_d <= spi_cmd_s;
      if rst = '1' then
        spi_start <= '0';
      elsif spi_cmd_d /= spi_cmd_s and spi_enable_s = '1' then
        spi_start <= '0';
      else
        spi_start <= spi_enable_s;
      end if;
    end if;
  end process;

  isrunning <= isrunning_s;

  ------------------------------------------------------------------------------------------------------------
  --! rx_clk clock domain:
  ------------------------------------------------------------------------------------------------------------
  ibufds_1 : IBUFDS
    port map (
      I  => aq600_synco_p,
      IB => aq600_synco_n,
      O  => synco
      );

  two_flop_synchronizer_1 : entity work.two_flop_synchronizer
    port map (
      clk       => rx_clk,
      reg_async => send_sync_s,
      reg_sync  => send_sync_rs);

  sync_generator_1 : entity work.sync_generator
    generic map (
      SYNCTRIG_PULSE_WIDTH => SYNCTRIG_PULSE_WIDTH)
    port map (
      clk         => rx_clk,
      rst         => rst,
      send_sync   => send_sync_rs, -- from aq600 interface state machine
      sw_sync     => sync_in,      -- from push button
      synctrig    => synctrig,     -- to ev12aq600 adc (tx) 
      synctrig_re => synctrig_re); -- to rx esistream ip

  obufds_1 : OBUFDS
    port map (
      O  => aq600_synctrig_p,
      OB => aq600_synctrig_n,
      I  => synctrig
      );
  
  synctrig_debug <= synctrig;

end rtl;

