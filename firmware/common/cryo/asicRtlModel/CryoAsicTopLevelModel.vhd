-------------------------------------------------------------------------------
-- File       : CRYO ASIC top level model
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 04/07/2019
-- Last update: 2020-07-08
-------------------------------------------------------------------------------
-- Description: This module emulates the basic functionalities of the 
-- CRYO ASIC vs.0p2
-- 
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;


library unisim;
use unisim.vcomponents.all;

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
      -- level based control
      SRO              : in  sl;
      SampClkEn        : in  sl;
      
      -- data out
      bitClk0          : out sl;
      frameClk0        : out sl;
      sData0           : out sl;
      bitClk1          : out sl;
      frameClk1        : out sl;
      sData1           : out sl
      
   );

end entity CryoAsicTopLevelModel;

architecture rtl of CryoAsicTopLevelModel is

  -- runs on ADC clock (typical 112MHz)
  type asicStateType is (DELAY_ST, RUNNING_ST);

  type CryoAsicRegType is record
    asicState        : asicStateType;
    stateCounter     : slv(15 downto 0);
    --
    sahClk           : sl;
    sahClkPolarity   : sl;
    sahClkDelay      : slv(7 downto 0);
    --
    muxCh0           : sl;
    muxCh1           : sl;
    muxCh2           : sl;
    muxCh3           : sl;
    muxChSel         : slv(1 downto 0);
    --
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

  signal r, rin          : CryoAsicRegType :=  CRYO_ASIC_REG_INIT_C;  
  signal asicRstL        : sl := '0';
  signal SRO_l8MHz       : sl;
  signal SRO_En          : sl;
  signal adcClk_i        : sl;
  signal adcClk          : sl;
  signal rstInt          : sl := '1';
  signal s_enc_valid_i   : sl := '0';
  signal s_mode_i        : slv(2  downto 0) := "001";
  signal data_i          : slv(11 downto 0) := (others => '0');
  signal data_o          : slv(11 downto 0);
  signal serClk          : sl;
  signal serClk_i        : sl;
  signal colCk           : sl;
  signal sampClk_i       : sl;
  signal dummyRst        : slv(2  downto 0);
  signal s_enc_data_o    : slv(13 downto 0);
  signal s_enc_data_i    : slv(11 downto 0);
  signal SampClkEn_i     : slv( 1 downto 0);
  
begin

  asicRstL <= not gRst;
  -----------------------------------------------------------------------------
  -- SACI
  -----------------------------------------------------------------------------
  -- saci simulation core
  SaciSlaveWrapper: entity work.SaciSlaveWrapper
      port map (
        asicRstL => asicRstL,
        saciClk  => saciClk,
        saciSelL => saciSelL,
        saciCmd  => saciCmd,
        saciRsp  => saciRsp);

  -----------------------------------------------------------------------------
  -- CLOCKs
  -----------------------------------------------------------------------------
  -- pll simulation using xilinx specific model (MMCM)
  -- clk0 is a 8x of clk in
  U_CRYO_PLL : entity work.ClockManagerUltraScale 
    generic map(
      TPD_G                  => 1 ns,
      TYPE_G                 => "MMCM",  -- or "PLL"
      INPUT_BUFG_G           => true,
      FB_BUFG_G              => true,
      RST_IN_POLARITY_G      => '1',     -- '0' for active low
      NUM_CLOCKS_G           => 1,
      -- MMCM attributes
      BANDWIDTH_G            => "OPTIMIZED",
      CLKIN_PERIOD_G         => 17.8571,    -- Input period in ns );
      DIVCLK_DIVIDE_G        => 1,
      CLKFBOUT_MULT_F_G      => 1.0,
      CLKFBOUT_MULT_G        => 16,
      CLKOUT0_DIVIDE_F_G     => 1.0,
      CLKOUT0_DIVIDE_G       => 2,
      CLKOUT0_PHASE_G        => 0.0,
      CLKOUT0_DUTY_CYCLE_G   => 0.5,
      CLKOUT0_RST_HOLD_G     => 3,
      CLKOUT0_RST_POLARITY_G => '1')
   port map(
      clkIn           => clk,           -- 56
      rstIn           => gRst,
      clkOut(0)       => serClk,        -- 448
      rstOut(0)       => rstInt,
      locked          => open
   );

  -- generates 112MHz
  U_BUFGCE_DIV_112MHz : BUFGCE_DIV
   generic map (
      BUFGCE_DIVIDE => 4,     -- 1-8
      IS_CE_INVERTED => '0',  -- Optional inversion for CE
      IS_CLR_INVERTED => '0', -- Optional inversion for CLR
      IS_I_INVERTED => '0'    -- Optional inversion for I
   )
   port map (
      O => adcClk_i,    -- 1-bit output: Buffer
      CE => '1',        -- 1-bit input: Buffer enable
      CLR => '0',       -- 1-bit input: Asynchronous clear (saci rst??)
      I => serClk_i     -- 1-bit input: Buffer
   );

  -- generates 64MHz
  U_BUFGCE_DIV_64MHz : BUFGCE_DIV
   generic map (
      BUFGCE_DIVIDE => 7,     -- 1-8
      IS_CE_INVERTED => '0',  -- Optional inversion for CE
      IS_CLR_INVERTED => '0', -- Optional inversion for CLR
      IS_I_INVERTED => '0'    -- Optional inversion for I
   )
   port map (
      O => colCk,     -- 1-bit output: Buffer
      CE => '1',        -- 1-bit input: Buffer enable
      CLR => '0',       -- 1-bit input: Asynchronous clear (saci rst??)
      I => serClk_i      -- 1-bit input: Buffer
   );

  -- generates 8MHz
  U_BUFGCE_DIV_8MHz : BUFGCE_DIV
   generic map (
      BUFGCE_DIVIDE => 8,     -- 1-8
      IS_CE_INVERTED => '0',  -- Optional inversion for CE
      IS_CLR_INVERTED => '0', -- Optional inversion for CLR
      IS_I_INVERTED => '0'    -- Optional inversion for I
   )
   port map (
      O => sampClk_i,    -- 1-bit output: Buffer
      CE => '1',        -- 1-bit input: Buffer enable
      CLR => '0',       -- 1-bit input: Asynchronous clear (saci rst??)
      I => colCk      -- 1-bit input: Buffer
   );

  -----------------------------------------------------------------------------
  -- LATCHES
  -----------------------------------------------------------------------------
  -- latche for SR0  
  U_latch_SRO : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => sampClk_i,
      rst     => rstInt,
      dataIn  => SRO,
      dataOut => SRO_l8MHz
   );
  
  U_latch_SRO_EN : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => sampClk_i,
      rst     => rstInt,
      dataIn  => SRO_l8MHz,
      dataOut => SRO_En
   );

  s_enc_valid_i <= SRO_En;

  -- latches for SamClkiEnable_i
  U_latch_SamClkiEnable_i0 : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => clk,
      rst     => gRst,
      dataIn  => SampClkEn,
      dataOut => SampClkEn_i(0)
   );
   U_latch_SamClkiEnable_i1 : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => serClk,
      rst     => rstInt,
      dataIn  => SampClkEn_i(0),
      dataOut => SampClkEn_i(1)
   );

  -----------------------------------------------------------------------------
  -- digital back end
  -----------------------------------------------------------------------------
  --
  u_ssp_enc12b14b_ext : entity work.ssp_enc12b14b_ext
    port map(
      start_ro  => SRO,
      clk_i     => colCk,                -- needs updating
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
        clk_i     => serClk,             
        reset_n_i => asicRstL,
        data_i    => s_enc_data_o,        -- "00"&EncDataIn, --
        data_o    => sData0
    );

  -----------------------------------------------------------------------------
  -- clock enable
  -----------------------------------------------------------------------------
  -- gated clock to simulate adcClk at 112MHz
  serClk_i <= serClk when SampClkEn_i(1) = '1'
           else '0';
  adcClk <= adcClk_i when SRO = '1'
            else '0';


  -----------------------------------------------------------------------------
  -- SubBanck clock (derived from ADC clock)
  -----------------------------------------------------------------------------
  -- sequential process
  seq : process (adcClk, rstInt) is
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
