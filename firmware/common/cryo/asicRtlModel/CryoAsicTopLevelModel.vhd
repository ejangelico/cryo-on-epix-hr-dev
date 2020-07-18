-------------------------------------------------------------------------------
-- File       : CRYO ASIC top level model
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 04/07/2019
-- Last update: 2020-07-17
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
      ROclk            : in  slv(1 downto 0);
      pGR              : in  sl;
      -- simulated data
      analogData       : in slv(11 downto 0) := (others => '0');
      -- saci
      SACIclk          : in  slv(1 downto 0);
      SACIsel          : in  sl;                  -- chipSelect
      SACIcmd          : in  slv(1 downto 0);
      SACIrsp          : out slv(1 downto 0);
      -- level based control
      pPulse           : in  sl := '0';
      pStartRO         : in  slv(1 downto 0);
      SampClkEn        : in  slv(1 downto 0);
      
      -- data out
      D0serClk         : out slv(1 downto 0);
      D0wordClk        : out slv(1 downto 0);
      D0out            : out slv(1 downto 0);
      D1serClk         : out slv(1 downto 0);
      D1wordClk        : out slv(1 downto 0);
      D1out            : out slv(1 downto 0)
      
   );

end entity CryoAsicTopLevelModel;

architecture rtl of CryoAsicTopLevelModel is


  constant ENCODER_C : positive := 2;

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

  type RegType is record
      ack                        : sl;
      cfg_reg_0                  : slv(15 downto 0);
      cfg_reg_1                  : slv(15 downto 0);
      cfg_reg_2                  : slv(15 downto 0);
      cfg_reg_3                  : slv(15 downto 0);
      cfg_reg_4                  : slv(15 downto 0);
      cfg_reg_5                  : slv(15 downto 0);
      cfg_reg_6                  : slv(15 downto 0);
      cfg_reg_7                  : slv(15 downto 0);
      cfg_reg_8                  : slv(15 downto 0);
      cfg_reg_9                  : slv(15 downto 0);
      cfg_reg_10                 : slv(15 downto 0);
      cfg_reg_11                 : slv(15 downto 0);
      cfg_reg_12                 : slv(15 downto 0);
      cfg_reg_13                 : slv(15 downto 0);
      cfg_reg_14                 : slv(15 downto 0);
      cfg_reg_15                 : slv(15 downto 0);
      cfg_reg_16                 : slv(15 downto 0);
      cfg_reg_17                 : slv(15 downto 0);
      cfg_reg_18                 : slv(15 downto 0);
      cfg_reg_19                 : slv(15 downto 0);      
      dout                       : slv(31 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      ack                        => '0',
      cfg_reg_0                  => (others => '0'),
      cfg_reg_1                  => (others => '0'),
      cfg_reg_2                  => (others => '0'),
      cfg_reg_3                  => (others => '0'),
      cfg_reg_4                  => (others => '0'),
      cfg_reg_5                  => x"0C88",
      cfg_reg_6                  => x"B725",
      cfg_reg_7                  => x"0000",
      cfg_reg_8                  => x"4020",
      cfg_reg_9                  => x"0900",
      cfg_reg_10                 => x"7231",
      cfg_reg_11                 => x"6ADF",
      cfg_reg_12                 => x"FCB6",
      cfg_reg_13                 => x"0003",
      cfg_reg_14                 => x"FFFF",
      cfg_reg_15                 => x"17DF",
      cfg_reg_16                 => x"3C1F",
      cfg_reg_17                 => x"8773",
      cfg_reg_18                 => x"596A",
      cfg_reg_19                 => x"043C",
      dout                       => (others => '0')
      );

  signal saciR   : RegType := REG_INIT_C;
  signal saciRin : RegType;

  signal r       : CryoAsicRegType :=  CRYO_ASIC_REG_INIT_C;
  signal rin     : CryoAsicRegType;
  --
  signal clk56MHz        : sl;
  signal asicRst         : sl;
  -- ASIC Gbps Ports
  signal asicDataP   : slv(ENCODER_C-1 downto 0) := (others => '0');
  signal asicDataN   : slv(ENCODER_C-1 downto 0) := (others => '1');
  signal serData     : slv2Array(ENCODER_C-1 downto 0)  := (others => (others => '0'));
  signal serialOut   : slv(ENCODER_C-1 downto 0)        := (others => '0');
  --
  signal asicRstL        : sl;
  signal saciClk_i       : sl;
  signal saciSelL        : sl;
  signal saciCmd_i       : sl;
  signal saciRsp_i       : sl;
  signal localSaciRst       : sl               := '0';
  signal localSaciAddr      : slv(11 downto 0) := (others => '0');
  signal localSaci_wr_en    : sl               := '1';
  signal localSaci_data_in  : slv(31 downto 0) := (others => '0');
  signal localSaci_data_out : slv(31 downto 0) := (others => '0');
  signal localSaci_exec     : sl               := '0';
  signal localSaci_ack      : sl               := '0';
  signal localSaci_cmd      : slv(6 downto 0)  := (others => '0');
  --
  signal SRO             : sl;
  signal SRO_l8MHz       : sl;
  signal SRO_En          : sl;
  signal adcClk_i        : sl;
  signal adcClk          : sl;
  signal rstSerClk       : sl := '1';
  signal s_enc_valid     : sl := '0';
  signal s_mode          : slv(2  downto 0) := "001";
  signal data_i          : slv(11 downto 0) := (others => '0');
  signal data_o          : slv(11 downto 0);
  signal serClk          : sl;
  signal serClk_i        : sl;
  signal colClk          : sl;
  signal sampClk_i       : sl;
  signal dummyRst        : slv(2  downto 0);
  signal enc_din         : slv12Array(ENCODER_C-1 downto 0)  := (others => (others => '0'));
  signal enc_dout        : slv14Array(ENCODER_C-1 downto 0)  := (others => (others => '0'));
  signal s_enc_data_o    : slv(13 downto 0);
  signal s_enc_data_i    : slv(11 downto 0);
  signal SampClkEnSE     : sl;
  signal SampClkEn_i     : slv( 1 downto 0);
  
begin

  -----------------------------------------------------------------------------
  -- IOs
  -----------------------------------------------------------------------------  
  U_clk56MHz : IBUFDS
      port map (
         I  => ROclk(0),  
         IB => ROclk(1),  
         O  => clk56MHz);

  asicRstL <= pGR;
  asicRst  <= not asicRstL;   

  U_SACIclk : IBUFDS
      port map (
         I  => SACIclk(0),  
         IB => SACIclk(1),  
         O  => saciClk_i);

  saciSelL <= SACIsel;

  U_SACIcmd : IBUFDS
      port map (
         I  => SACIcmd(0),  
         IB => SACIcmd(1),  
         O  => saciCmd_i);
  
  U_SACIrsp : OBUFDS
      port map (
         O  => SACIrsp(0),  
         OB => SACIrsp(1),  
         I  => saciRsp_i);
  
  U_pStartRO : IBUFDS
      port map (
         I  => pStartRO(0),  
         IB => pStartRO(1),  
         O  => SRO);
  U_SampClkEn : IBUFDS
      port map (
         I  => SampClkEn(0),  
         IB => SampClkEn(1),  
         O  => SampClkEnSE);  

  -----------------------------------------------------------------------------
  -- CLOCKs
  -----------------------------------------------------------------------------
  -- pll simulation using xilinx specific model (MMCM)
  -- clk0 is a 8x of clk in
  U_CRYO_PLL : entity surf.ClockManagerUltraScale 
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
      clkIn           => clk56MHz,      -- 56MHz
      rstIn           => asicRst,
      clkOut(0)       => serClk,        -- 448MHz
      rstOut(0)       => rstSerClk,
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
      O => colClk,     -- 1-bit output: Buffer
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
      I => colClk      -- 1-bit input: Buffer
   );

  -----------------------------------------------------------------------------
  -- LATCHES
  -----------------------------------------------------------------------------
  -- latche for SRO  
  U_latch_SRO : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => sampClk_i,
      rst     => rstSerClk,
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
      rst     => rstSerClk,
      dataIn  => SRO_l8MHz,
      dataOut => SRO_En
   );

  s_enc_valid <= SRO_En;

  -- latches for SamClkiEnable_i
  U_latch_SamClkiEnable_i0 : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => clk56MHz,
      rst     => asicRst,
      dataIn  => SampClkEnSE,
      dataOut => SampClkEn_i(0)
   );
   U_latch_SamClkiEnable_i1 : entity work.AsicLatch
   generic map (
      TPD_G          => TPD_G,
      STAGES_G       => 1
     )
      port map (
      clk     => serClk,
      rst     => rstSerClk,
      dataIn  => SampClkEn_i(0),
      dataOut => SampClkEn_i(1)
      );

  -----------------------------------------------------------------------------
  -- SACI
  -----------------------------------------------------------------------------

  -----------------------
  -- SACI Register Module
  -----------------------

   U_SaciSlv : entity surf.SaciSlave
      generic map(
         TPD_G => TPD_G)
      port map(
         rstL     => asicRstL,
         saciClk  => saciClk_i,
         saciSelL => saciSelL,
         saciCmd  => saciCmd_i,
         saciRsp  => saciRsp_i,
         -- Silly reset hack to get saciSelL | rst onto dedicated reset bar
         rstOutL  => localSaciRst,
         rstInL   => asicRstL,
         -- Detector (Parallel) Interface
         exec     => localSaci_exec,
         ack      => localSaci_ack,
         readL    => localSaci_wr_en,
         cmd      => localSaci_cmd,
         addr     => localSaciAddr,
         wrData   => localSaci_data_in,
         rdData   => localSaci_data_out);

   ---------------------------------------------------
   -- SACI Register Mapping
   ---------------------------------------------------

   comb : process (localSaciAddr, localSaci_data_in, localSaci_exec,
                   localSaci_wr_en, saciR, asicRstL) is
      variable v    : RegType;
      variable addr : natural;
   begin
      -- Latch the current value
      v := saciR;

      -- Ack the response
      v.ack := localSaci_exec;

      if (localSaci_exec = '1') then

         -- Default value
         v.dout := (others => '0');

         -- Convert from SLV to int
         addr := conv_integer(localSaciAddr);

         -- Write Access
         if (localSaci_wr_en = '1') then
           case (addr) is
             when 0      => v.cfg_reg_0       := localSaci_data_in(15 downto 0);
             when 1      => v.cfg_reg_1       := localSaci_data_in(15 downto 0);
             when 2      => v.cfg_reg_2       := localSaci_data_in(15 downto 0);
             when 3      => v.cfg_reg_3       := localSaci_data_in(15 downto 0);
             when 4      => v.cfg_reg_4       := localSaci_data_in(15 downto 0);
             when 5      => v.cfg_reg_5       := localSaci_data_in(15 downto 0);
             when 6      => v.cfg_reg_6       := localSaci_data_in(15 downto 0);
             when 7      => v.cfg_reg_7       := localSaci_data_in(15 downto 0);
             when 8      => v.cfg_reg_8       := localSaci_data_in(15 downto 0);
             when 9      => v.cfg_reg_9       := localSaci_data_in(15 downto 0);
             when 10     => v.cfg_reg_10      := localSaci_data_in(15 downto 0);
             when 11     => v.cfg_reg_11      := localSaci_data_in(15 downto 0);
             when 12     => v.cfg_reg_12      := localSaci_data_in(15 downto 0);
             when 13     => v.cfg_reg_13      := localSaci_data_in(15 downto 0);
             when 14     => v.cfg_reg_14      := localSaci_data_in(15 downto 0);
             when 15     => v.cfg_reg_15      := localSaci_data_in(15 downto 0);
             when 16     => v.cfg_reg_16      := localSaci_data_in(15 downto 0);
             when 17     => v.cfg_reg_17      := localSaci_data_in(15 downto 0);
             when 18     => v.cfg_reg_18      := localSaci_data_in(15 downto 0);
             when 19     => v.cfg_reg_19      := localSaci_data_in(15 downto 0);                            
             when others => v.dout            := (others => '0');
           end case;
         else
           
           -- Read Access
           case (addr) is
             when 0      =>  v.dout(15 downto 0)  := v.cfg_reg_0;
             when 1      =>  v.dout(15 downto 0)  := v.cfg_reg_1;
             when 2      =>  v.dout(15 downto 0)  := v.cfg_reg_2;
             when 3      =>  v.dout(15 downto 0)  := v.cfg_reg_3;
             when 4      =>  v.dout(15 downto 0)  := v.cfg_reg_4;
             when 5      =>  v.dout(15 downto 0)  := v.cfg_reg_5;
             when 6      =>  v.dout(15 downto 0)  := v.cfg_reg_6;
             when 7      =>  v.dout(15 downto 0)  := v.cfg_reg_7;
             when 8      =>  v.dout(15 downto 0)  := v.cfg_reg_8;
             when 9      =>  v.dout(15 downto 0)  := v.cfg_reg_9;
             when 10     =>  v.dout(15 downto 0)  := v.cfg_reg_10;
             when 11     =>  v.dout(15 downto 0)  := v.cfg_reg_11;
             when 12     =>  v.dout(15 downto 0)  := v.cfg_reg_12;
             when 13     =>  v.dout(15 downto 0)  := v.cfg_reg_13;
             when 14     =>  v.dout(15 downto 0)  := v.cfg_reg_14;
             when 15     =>  v.dout(15 downto 0)  := v.cfg_reg_15;
             when 16     =>  v.dout(15 downto 0)  := v.cfg_reg_16;
             when 17     =>  v.dout(15 downto 0)  := v.cfg_reg_17;
             when 18     =>  v.dout(15 downto 0)  := v.cfg_reg_18;
             when 19     =>  v.dout(15 downto 0)  := v.cfg_reg_19;
                             
             when others =>  v.dout := (others => '0');
           end case;
         end if;
      end if;     


      -- Outputs
      localSaci_ack      <= saciR.ack and localSaci_exec;
      localSaci_data_out <= saciR.dout;

      -- Reset
      if asicRstL = '0' then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      saciRin <= v;

   end process comb;

   seq : process (saciClk_i, asicRstL) is
   begin
     if asicRstL = '0' then
       saciR <= REG_INIT_C;
     else
       if rising_edge(saciClk_i) then
         saciR <= saciRin after TPD_G;
       end if;
     end if;
   end process seq;



  -----------------------------------------------------------------------------
  -- digital back end
  -----------------------------------------------------------------------------
  --
  enc_din(0) <= x"F00";
  enc_din(1) <= x"F11";
  s_mode     <= saciR.cfg_reg_16(7 downto 5);
  
  GEN_DIGITAL_BACKEND_ENCODERS :
  for i in ENCODER_C-1 downto 0 generate                                                              
    u_ssp_enc12b14b_ext : entity work.ssp_enc12b14b_ext_sim
      port map(
        start_ro  => SRO,
        clk_i     => colClk,            
        rst_n_i   => asicRstL,
        valid_i   => s_enc_valid,       
        mode_i    => s_mode,            
        data_i    => enc_din(i),
        data_o    => enc_dout(i)
        );
    
    U_Serializer : entity surf.AsyncGearbox
      generic map (
        TPD_G          => TPD_G,
        SLAVE_WIDTH_G  => 14,
        MASTER_WIDTH_G => 2)
      port map (
        -- Slave Interface
        slaveClk   => colClk,  -- serClkDiv7
        slaveRst   => '0',
        slaveValid => '1',
        slaveData  => enc_dout(i),
        -- Master Interface
        masterClk  => serClk,
        masterRst  => rstSerClk,
        masterData => serData(i));
  
    U_ODDR : ODDRE1
      port map (
        C  => serClk,
        SR => rstSerClk,
        D1 => serData(i)(0),
        D2 => serData(i)(1),
        Q  => serialOut(i));
  
    U_OBUFDS : OBUFDS
      port map (
        I  => serialOut(i),
        O  => asicDataP(i),  -- ASIC carrier pinout not finalized yet (01JUNE2020)
        OB => asicDataN(i));  -- ASIC carrier pinout not finalized yet (01JUNE2020)

  end generate GEN_DIGITAL_BACKEND_ENCODERS;

  -----------------------------------------------------------------------------
  -- clock enable
  -----------------------------------------------------------------------------
  -- gated clock to simulate adcClk at 112MHz
  serClk_i <= serClk when SampClkEn_i(1) = '1'
            else '0';
  adcClk <= adcClk_i when SRO = '1'
            else '0';


  U_OBUFDS_D0wordClk : OBUFDS
    port map (
      I  => colClk,
      O  => D0wordClk(0),  
      OB => D0wordClk(1)); 

  U_OBUFDS_D1wordClk : OBUFDS
    port map (
      I  => colClk,
      O  => D1wordClk(0),  
      OB => D1wordClk(1)); 
  
  U_OBUFDS_D0serClk : OBUFDS
    port map (
      I  => serClk_i,
      O  => D0serClk(0),  
      OB => D0serClk(1)); 

  U_OBUFDS_D1serClk : OBUFDS
    port map (
      I  => serClk_i,
      O  => D1serClk(0),  
      OB => D1serClk(1)); 

  -------------------------------------------
  --mapping output ports
  -------------------------------------------
  D0out(0) <= asicDataP(0);
  D0out(1) <= asicDataN(0);

  D1out(0) <= asicDataP(1);
  D1out(1) <= asicDataN(1);

  
--  u_ssp_enc12b14b_ext : entity work.ssp_enc12b14b_ext
--    port map(
--      start_ro  => SRO,
--      clk_i     => colClk,                -- needs updating
--      rst_n_i   => asicRstL,
--      valid_i   => s_enc_valid_i,       -- needs updating
--      mode_i    => s_mode,            
--      data_i    => s_enc_data_i,
--      data_o    => s_enc_data_o
--    );

--  U_serializer :  entity work.serializerSim 
--    generic map(
--        g_dwidth => 14 
--    )
--    port map(
--        clk_i     => serClk,             
--        reset_n_i => asicRstL,
--        data_i    => s_enc_data_o,        -- "00"&EncDataIn, --
--        data_o    => sData0
--    );


  -- -----------------------------------------------------------------------------
  -- -- SubBanck clock (derived from ADC clock)
  -- -----------------------------------------------------------------------------
  -- -- sequential process
  -- seq : process (adcClk, rstSerClk) is
  -- begin
  --   if (rising_edge(adcClk)) then
  --     r <= rin after TPD_G;
  --   end if;
  -- end process seq;

  -- -- core, combinatorial, process
  -- comb : process (r ) is
  --   variable v : CryoAsicRegType;
  -- begin
  --   v := r;

  --   case r.asicState is
  --     when DELAY_ST =>
  --       --
  --       v.stateCounter := r.stateCounter + 1;
  --       -- update signals at the end of the delay phase
  --       if r.stateCounter = r.sahClkDelay then
  --         v.stateCounter   := (others => '0');
  --         v.asicState      := RUNNING_ST;
  --       end if;
  --     when RUNNING_ST =>
  --       --
  --       -- signals based on adcSampCounter
  --       --
  --       v.adcSampCounter := r.adcSampCounter + 1;
  --       --
  --       if r.adcSampCounter = r.adcSampDelay then
  --         v.adcSamp := '1';
  --       end if;
  --       if r.adcSampCounter = (r.adcSampDelay + r.adcSampPeriod) then
  --         v.adcSampCounter := (others => '0');
  --         v.adcSamp := '0';
  --       end if;
  --       if r.adcSampCounter = (r.adcSampDelay + r.adcSampPeriod - 1) then
  --         v.muxChSel := r.muxChSel + 1;
  --       end if;
  --       --
  --       case r.muxChSel is
  --         when "00" =>
  --           v.muxCh0 := '1';
  --           v.muxCh3 := '0';
  --           v.sahClk := '1';
  --         when "01" =>
  --           v.muxCh1 := '1';
  --           v.muxCh0 := '0';
  --         when "10" =>
  --           v.muxCh2 := '1';
  --           v.muxCh1 := '0';
  --           v.sahClk := '0';
  --         when "11" =>
  --           v.muxCh3 := '1';
  --           v.muxCh2 := '0';
  --         when others =>
  --           v.muxCh0 := '0';
  --           v.muxCh1 := '0';
  --           v.muxCh2 := '0';
  --           v.muxCh3 := '0';
  --           v.sahClk := '0';
  --       end case;
  --     when others =>
  --   end case;

  --   -- Synchronous Reset
  --   if (gRst = '1' or SRO = '0') then
  --     v := CRYO_ASIC_REG_INIT_C;
  --   end if;

  --   -- Register the variable for next clock cycle
  --   rin <= v;

  --   -- Assign outputs from registers
  --   --exec    <= r.exec;


  -- end process comb;

end rtl;
