-------------------------------------------------------------------------------
-- File       : EpixHr: PowerControlModule.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 04/07/2017
-- Last update: 2019-07-05
-------------------------------------------------------------------------------
-- Description: This module enable the voltage regulators on the epix boards
-- based on saci register values. If needed syncronization modules should be
-- inserted in this module as well.
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity CryoAsicTopLevelModel is
   generic (
      TPD_G              : time             := 1 ns;
      AXIL_ERR_RESP_G    : slv(1 downto 0)  := AXI_RESP_DECERR_C
   );
   port (
      clk              : in  sl;
      gRst             : in  sl;
      -- simulated data
      analogData       : in slv(11 downto 0);
      -- saci
      saciClk          : in  sl;
      saciSelL         : in  sl;                  -- chipSelect
      saciCmd          : in  sl;
      saciRsp          : out sl;
      -- static control
      SRO              : in   sl;
      
      -- data out
      bitClk0         : out sl;
      frameClk0       : out sl;
      sData0          : out sl;
      bitClk1         : out sl;
      frameClk1       : out sl;
      sData1          : out sl
      
   );

end entity CryoAsicTopLevelModel;

architecture rtl of CryoAsicTopLevelModel is

  type asicStateType is (DELAY_ST, RUNNING_ST);

  type CryoAsicRegType is record
    asicState        : asicStateType;
    stateCounter     : slv(15 downto 0);
    sahClk           : sl;
    sahClkPolarity   : sl;
    sahClkDelay      : slv(7 downto 0);
    muxCh0           : sl;
    muxCh1           : sl;
    muxCh2           : sl;
    muxCh3           : sl;
    muxChSel         : slv(1 downto 0);
    adcSamp          : sl;
    adcSampDelay     : slv(7 downto 0);
    adcSampPeriod    : slv(7 downto 0);
    adcSampCounter   : slv(7 downto 0);
  end record CryoAsicRegType;

  constant CRYO_ASIC_REG_INIT_C : CryoAsicRegType := (
    asicState        => DELAY_ST,
    stateCounter     => (others => '0'),
    sahClk           => '0',
    sahClkPolarity   => '0',
    sahClkDelay      => x"0d",
    muxCh0           => '0',
    muxCh1           => '0',
    muxCh2           => '0',
    muxCh3           => '0',
    muxChSel         => "00",
    adcSamp          => '0',
    adcSampDelay     => x"0b",
    adcSampPeriod    => x"02",
    adcSampCounter   => x"00"
    );

  signal r, rin        : CryoAsicRegType :=  CRYO_ASIC_REG_INIT_C;  
  signal asicRstL      : sl := '0';
  signal clk2x         : sl;
  signal adcClk        : sl;
  signal rstInt        : sl := '1';
  signal s_enc_valid_i : sl := '0';
  signal s_mode_i      : slv(2  downto 0) := "001";
  signal data_i        : slv(11 downto 0) := (others => '0');
  signal data_o        : slv(11 downto 0);
  signal dClk          : sl;
  signal fClk          : sl;
  signal samClk        : sl;
  signal dummyRst      : slv(2  downto 0);
  signal s_enc_data_o  : slv(13 downto 0);
  signal s_enc_data_i  : slv(11 downto 0);
   
begin

  asicRstL <= not gRst;

  -- saci simulation core
  SaciSlaveWrapper: entity work.SaciSlaveWrapper
      port map (
        asicRstL => asicRstL,
        saciClk  => saciClk,
        saciSelL => saciSelL,
        saciCmd  => saciCmd,
        saciRsp  => saciRsp);

  -- pll simulation using xilinx specific model (MMCM)
  -- clk0 is a 2x of clk in
  U_CRYO_PLL : entity work.ClockManagerUltraScale 
    generic map(
      TPD_G                  => 1 ns,
      TYPE_G                 => "MMCM",  -- or "PLL"
      INPUT_BUFG_G           => true,
      FB_BUFG_G              => true,
      RST_IN_POLARITY_G      => '1',     -- '0' for active low
      NUM_CLOCKS_G           => 4,
      -- MMCM attributes
      BANDWIDTH_G            => "OPTIMIZED",
      CLKIN_PERIOD_G         => 17.8571,    -- Input period in ns );
      DIVCLK_DIVIDE_G        => 1,
      CLKFBOUT_MULT_F_G      => 1.0,
      CLKFBOUT_MULT_G        => 16,
      CLKOUT0_DIVIDE_F_G     => 1.0,
      CLKOUT0_DIVIDE_G       => 8,
      CLKOUT0_PHASE_G        => 0.0,
      CLKOUT0_DUTY_CYCLE_G   => 0.5,
      CLKOUT0_RST_HOLD_G     => 3,
      CLKOUT0_RST_POLARITY_G => '1',
      CLKOUT1_DIVIDE_G       => 2,
      CLKOUT1_PHASE_G        => 0.0,
      CLKOUT1_DUTY_CYCLE_G   => 0.5,
      CLKOUT1_RST_HOLD_G     => 3,
      CLKOUT1_RST_POLARITY_G => '1',
      CLKOUT2_DIVIDE_G       => 14,
      CLKOUT2_PHASE_G        => 0.0,
      CLKOUT2_DUTY_CYCLE_G   => 0.5,
      CLKOUT2_RST_HOLD_G     => 4,
      CLKOUT2_RST_POLARITY_G => '1',
      CLKOUT3_DIVIDE_G       => 112,
      CLKOUT3_PHASE_G        => 0.0,
      CLKOUT3_DUTY_CYCLE_G   => 0.5,
      CLKOUT3_RST_HOLD_G     => 4,
      CLKOUT3_RST_POLARITY_G => '1')
   port map(
      clkIn           => clk,           -- 56
      rstIn           => gRst,
      clkOut(0)       => clk2x,         -- 112
      clkOut(1)       => dClk,          -- 448
      clkOut(2)       => fClk,          -- 64MHz
      clkOut(3)       => samClk,        -- 8
      rstOut(0)       => rstInt,
      rstOut(1)       => dummyRst(0),
      rstOut(2)       => dummyRst(1),
      rstOut(3)       => dummyRst(2),
      locked          => open
   );

  U_synchronizer_s_enc_valid_i : entity work.Synchronizer
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 2
     )
      port map (
      clk     => samClk,
      rst     => rstInt,
      dataIn  => SRO,
      dataOut => s_enc_valid_i
   ); 

  u_ssp_enc12b14b_ext : entity work.ssp_enc12b14b_ext
    port map(
      start_ro  => SRO,
      clk_i     => fClk,                -- needs updating
      rst_n_i   => asicRstL,
      valid_i   => s_enc_valid_i,       -- needs updating
      mode_i    => s_mode_i,            
      data_i    => s_enc_data_i,
      data_o    => s_enc_data_o
    );

  U_serializer :  entity work.serializerSim 
    generic map(
        g_dwidth => 14 
    )
    port map(
        clk_i     => dClk,             
        reset_n_i => asicRstL,
        data_i    => s_enc_data_o,        -- "00"&EncDataIn, --
        data_o    => sData0
    );

  -- gated clock to simulate adcClk at 112MHz
  adcClk <= clk2x when SRO = '1'
            else '0';

  -- sequential process
  seq : process (clk2x, rstInt) is
  begin
    if (rising_edge(adcClk)) then
      r <= rin after TPD_G;
    end if;
  end process seq;

  -- core, combinatorial, process
  comb : process (r ) is
    variable v : CryoAsicRegType;
  begin
    v := r;

    case r.asicState is
      when DELAY_ST =>
        --
        v.stateCounter := r.stateCounter + 1;
        -- update signals at the end of the delay phase
        if r.stateCounter = r.sahClkDelay then
          v.stateCounter   := (others => '0');
          v.asicState      := RUNNING_ST;
        end if;
      when RUNNING_ST =>
        --
        -- signals based on adcSampCounter
        --
        v.adcSampCounter := r.adcSampCounter + 1;
        --
        if r.adcSampCounter = r.adcSampDelay then
          v.adcSamp := '1';
        end if;
        if r.adcSampCounter = (r.adcSampDelay + r.adcSampPeriod) then
          v.adcSampCounter := (others => '0');
          v.adcSamp := '0';
        end if;
        if r.adcSampCounter = (r.adcSampDelay + r.adcSampPeriod - 1) then
          v.muxChSel := r.muxChSel + 1;
        end if;
        --
        case r.muxChSel is
          when "00" =>
            v.muxCh0 := '1';
            v.muxCh3 := '0';
            v.sahClk := '1';
          when "01" =>
            v.muxCh1 := '1';
            v.muxCh0 := '0';
          when "10" =>
            v.muxCh2 := '1';
            v.muxCh1 := '0';
            v.sahClk := '0';
          when "11" =>
            v.muxCh3 := '1';
            v.muxCh2 := '0';
          when others =>
            v.muxCh0 := '0';
            v.muxCh1 := '0';
            v.muxCh2 := '0';
            v.muxCh3 := '0';
            v.sahClk := '0';
        end case;
      when others =>
    end case;

    -- Synchronous Reset
    if (gRst = '1' or SRO = '0') then
      v := CRYO_ASIC_REG_INIT_C;
    end if;

    -- Register the variable for next clock cycle
    rin <= v;

    -- Assign outputs from registers
    --exec    <= r.exec;


  end process comb;

end rtl;
