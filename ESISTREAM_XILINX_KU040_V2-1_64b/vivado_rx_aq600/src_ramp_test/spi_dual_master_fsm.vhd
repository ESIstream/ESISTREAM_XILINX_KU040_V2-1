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

entity spi_dual_master_fsm is
  port (
    -- clock and reset
    clk           : in  std_logic := 'X';
    refclk        : in  std_logic;
    refclk_re     : in  std_logic;
    refclk_fe     : in  std_logic;
    rst           : in  std_logic := 'X';
    -- spi interface
    spi_ncs2      : out std_logic;
    spi_ncs1      : out std_logic;
    spi_sclk      : out std_logic;
    spi_mosi      : out std_logic;
    spi_miso      : in  std_logic;
    -- spi control
    spi_ss        : in  std_logic;  -- spi slave select spi_ncs1 when '0' else spi_ncs2.
    spi_start     : in  std_logic;
    spi_cmd       : in  std_logic_vector(1 downto 0);
    spi_busy      : out std_logic;
    -- registers signal:
    prbs_en       : in  std_logic := '1';
    data_en       : in  std_logic := '1';
    dc_balance_en : in  std_logic := '1'
    );
end spi_dual_master_fsm;

architecture rtl of spi_dual_master_fsm is
  --constant SPI_CMD_OTP_LOAD  : std_logic_vector(1 downto 0) := "00"; 
  --constant SPI_CMD_RAMP_MODE : std_logic_vector(1 downto 0) := "01";  
  --constant SPI_CMD_DATA_MODE : std_logic_vector(1 downto 0) := "10"; 
  --constant SPI_CMD_OTP_LOAD  : std_logic_vector(1 downto 0) := "11";
  constant SLAVE_AQ600        : std_logic := '0';
  constant SLAVE_LMX2592      : std_logic := '1';
  constant DATA_AQ600_WIDTH   : integer   := 16;
  constant DATA_LMX2592_WIDTH : integer   := 24;
  constant DATA_WIDTH         : integer   := 24;   -- max(16 for aq600, 24 for LMX2592)
  constant data_id_init1      : integer   := 1;    -- 2 registers
  constant data_id_init2      : integer   := 43;   -- 44 registers

  type slv_array_n is array (natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
  constant OTP_LOAD  : slv_array_n(1 downto 0)                 := (x"008001", x"000001");
  constant RAMP_MODE : slv_array_n(1 downto 0)                 := (x"008B0A", x"000001");
  signal DATA_MODE   : slv_array_n(1 downto 0)                 := (x"008B07", x"000007");
  signal data_reg    : slv_array_n(1 downto 0)                 := (x"008B07", x"000007");
  signal data_load   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  --------------------------------------------------------------------------------------------------------------------------------
  -- Use the external PLL LMX2592 to generate the EV12AQ600 CLK input:
  -- This mode is not available without modification of the file spi_dual_master_fsm.vhd.
  -- To use this mode or for more information contact: GRE-HOTLINE-BDC@Teledyne.com
  --------------------------------------------------------------------------------------------------------------------------------
  constant LMX2592_REGISTERS_5GHz : slv_array_n(43 downto 0) := ( x"000000",
                                                                  x"400000",
                                                                  x"3E0000",
                                                                  x"3D0000",
                                                                  x"3B0000",
                                                                  x"300000",
                                                                  x"2F0000",
                                                                  x"2E0000",
                                                                  x"2D0000",
                                                                  x"2C0000",
                                                                  x"2B0000",
                                                                  x"2A0000",
                                                                  x"290000",
                                                                  x"280000",
                                                                  x"270000",
                                                                  x"260000",
                                                                  x"250000",
                                                                  x"240000",
                                                                  x"230000",
                                                                  x"220000",
                                                                  x"210000",
                                                                  x"200000",
                                                                  x"1F0000",
                                                                  x"1E0000",
                                                                  x"1D0000",
                                                                  x"1C0000",
                                                                  x"190000",
                                                                  x"180000",
                                                                  x"170000",
                                                                  x"160000",
                                                                  x"140000",
                                                                  x"130000",
                                                                  x"0E0000",
                                                                  x"0D0000",
                                                                  x"0C0000",
                                                                  x"0B0000",
                                                                  x"0A0000",
                                                                  x"090000",
                                                                  x"080000",
                                                                  x"070000",
                                                                  x"040000",
                                                                  x"020000",
                                                                  x"010000",
                                                                  x"000000"); 
  --
  type state_type is (st_idle, st_spi_ncs_low, st_spi_ncs_high, st_spi_wr, st_spi_pause);
  signal state, next_state        : state_type;
  --
  signal spi_busy_a, spi_busy_s   : std_logic                        := '0';
  signal spi_wr_a, spi_wr_s       : std_logic                        := '0';
  signal spi_pause_a, spi_pause_s : std_logic                        := '0';
  signal spi_ncs_a, spi_ncs_s     : std_logic                        := '0';
  signal spi_mosi_a, spi_mosi_s   : std_logic                        := '0';
  --
  constant dcntr_width            : integer                          := 8;
  signal dcntr                    : unsigned(dcntr_width-1 downto 0) := (others => '0');
  constant dcntr_init1            : unsigned(dcntr_width-1 downto 0) := to_unsigned(DATA_AQ600_WIDTH-1, dcntr'length);
  constant dcntr_init2            : unsigned(dcntr_width-1 downto 0) := to_unsigned(DATA_LMX2592_WIDTH-1, dcntr'length);
  constant pcntr_width            : integer                          := 4;
  signal dcntr_done               : std_logic                        := '0';
  signal pcntr                    : unsigned(pcntr_width-1 downto 0) := to_unsigned(2**pcntr_width-1, pcntr_width);
  constant pcntr_init             : unsigned(pcntr_width-1 downto 0) := to_unsigned(2**pcntr_width-1, pcntr'length);
  signal pcntr_done               : std_logic                        := '0';
  signal spi_last_wr              : std_logic                        := '0';
  signal data_id                  : integer                          := 1;
  signal spi_start_m              : std_logic                        := '0';
  signal spi_ss_d                 : std_logic := '0';

begin

  p_start_memo : process (clk)
  begin
    if rising_edge(clk) then
      if refclk_fe = '1' then
        spi_start_m <= '0';
      elsif spi_start = '1' and spi_busy_s = '0' then
        spi_start_m <= '1';
      else
        spi_start_m <= spi_start_m;
      end if;
    end if;
  end process;

  DATA_MODE(0)(0) <= prbs_en;
  DATA_MODE(0)(1) <= data_en;
  DATA_MODE(0)(2) <= dc_balance_en;

  SYNC_PROC : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state       <= st_idle;
        spi_busy_s  <= '0';
        spi_ncs_s   <= '1';
        spi_wr_s    <= '0';
        spi_pause_s <= '1';
        spi_mosi_s  <= '0';
      else
        state       <= next_state;
        spi_busy_s  <= spi_busy_a;
        spi_ncs_s   <= spi_ncs_a;
        spi_wr_s    <= spi_wr_a;
        spi_pause_s <= spi_pause_a;
        spi_mosi_s  <= spi_mosi_a;
      end if;
    end if;
  end process;

  --MOORE State-Machine - Outputs based on state only
  OUTPUT_DECODE : process (state, data_load, dcntr, spi_ss)
  begin
    if state = st_idle then
      spi_busy_a  <= '0';
      spi_ncs_a   <= '1';
      spi_wr_a    <= '0';
      spi_pause_a <= '0';
      spi_mosi_a  <= '0';
    elsif state = st_spi_ncs_low then
      spi_busy_a  <= '1';
      spi_ncs_a   <= '0';
      spi_wr_a    <= '0';
      spi_pause_a <= '0';
      spi_mosi_a  <= data_load(to_integer(dcntr));
    elsif state = st_spi_wr then
      spi_busy_a  <= '1';
      spi_ncs_a   <= '0';
      spi_wr_a    <= '1';
      spi_pause_a <= '0';
      spi_mosi_a  <= data_load(to_integer(dcntr));
    elsif state = st_spi_ncs_high then
      spi_busy_a  <= '1';
      spi_ncs_a   <= '0';
      spi_wr_a    <= '0';
      spi_pause_a <= '0';
      spi_mosi_a  <= data_load(to_integer(dcntr));
    elsif state = st_spi_pause then
      spi_busy_a  <= '1';
      spi_ncs_a   <= spi_ss;
      spi_wr_a    <= '0';
      spi_pause_a <= '1';
      spi_mosi_a  <= data_load(to_integer(dcntr));
    else
      spi_busy_a  <= '1';
      spi_ncs_a   <= '1';
      spi_wr_a    <= '0';
      spi_pause_a <= '0';
      spi_mosi_a  <= '0';
    end if;
  end process;

  NEXT_STATE_DECODE : process (state, refclk_re, refclk_fe, spi_start_m, dcntr_done, pcntr_done, spi_last_wr)
  begin
    next_state <= state;

    case state is
      when st_idle =>
        if (refclk_fe = '1') and (spi_start_m = '1') then
          next_state <= st_spi_ncs_low;
        else
          next_state <= st_idle;
        end if;

      when st_spi_ncs_low =>
        next_state <= st_spi_wr;

      when st_spi_wr =>
        if (refclk_fe = '1') and (dcntr_done = '1') then
          next_state <= st_spi_ncs_high;
        else
          next_state <= st_spi_wr;
        end if;
 
      when st_spi_ncs_high =>
        if refclk_re = '1' and spi_last_wr = '1' then
          next_state <= st_idle;
        elsif refclk_re = '1' then
          next_state <= st_spi_pause;
        end if;
        
      when st_spi_pause =>
        if refclk_fe = '1' and pcntr_done = '1' and spi_last_wr = '0' then
          next_state <= st_spi_ncs_low;
        else
          next_state <= st_spi_pause;
        end if;

      when others =>
        next_state <= st_idle;
        
    end case;
  end process;

  --! spi port outputs
  p_spi_sclk : process (clk)
  begin
    if rising_edge(clk) then
      if spi_wr_s = '1' then
        spi_sclk <= refclk;
      else
        spi_sclk <= '0';
      end if;
    end if;
  end process;
  spi_mosi <= spi_mosi_s;
  spi_ncs1 <= spi_ncs_s when spi_ss = SLAVE_AQ600   else '1';
  spi_ncs2 <= spi_ncs_s when spi_ss = SLAVE_LMX2592 else '1';
  spi_busy <= spi_busy_s;
  p_pcntr : process (clk)
  begin
    if rising_edge(clk) then
      if refclk_fe = '1' then
        if spi_pause_s = '1' then
          if pcntr = 0 then
            pcntr <= to_unsigned(0, pcntr'length);
          else
            pcntr <= pcntr - 1;
          end if;
        else
          pcntr <= pcntr_init;
        end if;
      else
        pcntr <= pcntr;
      end if;
    end if;
  end process;

  p_pcntr_done : process (clk)
  begin
    if rising_edge(clk) then
      if pcntr = 0 then
        pcntr_done <= '1';
      else
        pcntr_done <= '0';
      end if;
    end if;
  end process;

  p_dcntr : process (clk)
  begin
    if rising_edge(clk) then
      if refclk_fe = '1' then
        if spi_wr_s = '1' then
          if dcntr = 0 then
            dcntr <= to_unsigned(0, dcntr'length);
          else
            dcntr <= dcntr - 1;
          end if;
        elsif spi_ss = SLAVE_AQ600 then
          dcntr <= dcntr_init1;
        else
          dcntr <= dcntr_init2;
        end if;
      else
        dcntr <= dcntr;
      end if;
    end if;
  end process;

  p_dcntr_done : process (clk)
  begin
    if rising_edge(clk) then
      if dcntr = 0 then
        if refclk_re = '1' then
          dcntr_done <= '1';
        end if;
      else
        dcntr_done <= '0';
      end if;
    end if;
  end process;

  p_data_id : process (clk)
  begin
    if rising_edge(clk) then
      if spi_busy_s = '0' then
        if spi_ss = SLAVE_AQ600 then
          data_id <= data_id_init1;
        else
          data_id <= data_id_init2;
        end if;
      elsif refclk_re = '1' then
        if pcntr = 7 then
          if data_id = 0 then
            data_id <= data_id;
          else
            data_id <= data_id - 1;
          end if;
        else
          data_id <= data_id;
        end if;
      else
        data_id <= data_id;
      end if;
    end if;
  end process;

  p_last_wr : process (clk)
  begin
    if rising_edge(clk) then
      if refclk_fe = '1' then
        if spi_busy_s = '0' then
          spi_last_wr <= '0';
        elsif pcntr = 0 and data_id = 0 and spi_wr_s = '1' then
          spi_last_wr <= '1';
        end if;
      else
        spi_last_wr <= spi_last_wr;
      end if;
    end if;
  end process;

  p_cmd_multiplexer : process (clk)
  begin
    if rising_edge(clk) then
      spi_ss_d <= spi_ss;
      if spi_ss_d = SLAVE_AQ600 then
        data_load <= data_reg(data_id);
      else
        data_load <= LMX2592_REGISTERS_5GHz(data_id);
      end if;
      case spi_cmd is
        when "00"   => data_reg <= OTP_LOAD;
        when "01"   => data_reg <= RAMP_MODE;
        when "10"   => data_reg <= DATA_MODE;
        when "11"   => data_reg <= OTP_LOAD;
        when others => data_reg <= OTP_LOAD;
      end case;
    end if;
  end process;

end rtl;
