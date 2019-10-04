-------------------------------------------------------------------------------
-- File       : EpixHr: PowerControlModule.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 04/07/2017
-- Last update: 2019-07-24
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

library unisim;
use unisim.vcomponents.all;

entity WIBTopLevelModel is
   generic (
      TPD_G                    : time             := 1 ns;
      AXIL_ERR_RESP_G          : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      SYSTEM_ENVIRONMENT       : string           := "DUNE";  -- "PROTODUNE"
      THIS_MODULE_CMD_ADDRESS  : slv(7 downto 0)  := x"00"      
   );
   port (
      DUNEclk          :  in  sl;
      DUNERst          :  in  sl;
      -- DUNE highSpeed bus
      SyncCmd          :  in  slv(15 downto 0);
      CmdAddr          :  in  slv( 7 downto 0);
      SyncCmdStrobe    :  in  sl;
      timeStamp        : out  slv(31 downto 0);
      cycleTime        : out  slv(6  downto 0);
      -- level based control
      SR0              : out  sl;
      SamCLKiEnable    : out  sl;
      asicClk          : out  sl 
   );

end entity WIBTopLevelModel;

architecture rtl of WIBTopLevelModel is

  type WIBModelRegType is record
    timeStamp             : slv(31 downto 0);
    cycleTime             : slv( 6 downto 0);
    SyncCmd               : slv(15 downto 0);
    CmdAddr               : slv( 7 downto 0);
    SyncCmdStrobe         : sl;
    resetTimeStampCmd     : sl;
    resetCycleTimeCmd     : sl;
    SamCLKiReady          : sl;
    SamCLKiReadyCycleTime : slv( 6 downto 0);
    SamCLKiEn             : sl;
    SamCLKiEnCmd          : sl;   
    SamCLKiDisCmd         : sl;
    SR0                   : sl;
    SR0EnCmd              : sl;
    SR0DisCmd             : sl;
  end record WIBModelRegType;

  constant WIB_MODEL_REG_INIT_C : WIBModelRegType := (
    timeStamp             => (others => '0'),
    cycleTime             => (others => '0'),
    SyncCmd               => (others => '0'),
    CmdAddr               => (others => '0'),
    SyncCmdStrobe         => '0',
    resetTimeStampCmd     => '0',
    resetCycleTimeCmd     => '0',
    SamCLKiReady          => '0',
    SamCLKiReadyCycleTime => "0110100",
    SamCLKiEn             => '0',
    SamCLKiEnCmd          => '0',
    SamCLKiDisCmd         => '0',
    SR0                   => '0',
    SR0EnCmd              => '0',
    SR0DisCmd             => '0'
    );

  signal r, rin        : WIBModelRegType :=  WIB_MODEL_REG_INIT_C;  

  signal duneClkInt : sl ;
  signal duneClkx4  : sl ;
  signal cryoClk    : sl ;
  signal duneRstInt : sl ;
  signal duneRstx4  : sl ;
  signal cryoRst    : sl ;
  signal phaseDuneCryo : slv(7 downto 0);

  
begin


  -- MMCM
  -- input clock is considered 62.5MHz
  -- Generates input clock *4
  -- Generates CRYO clock 56MHz
  U_DUNE_PLL: if SYSTEM_ENVIRONMENT = "DUNE" generate
    ------------------------------------------
    -- Generate clocks                      --
    ------------------------------------------
    -- clkIn     :  62.50 MHz DUNE base clock
    -- clkOut(0) :  62.50 MHz -- Internal copy of the clock
    -- clkOut(1) : 250.00 MHz -- DUNE clock times 4 used for the deserializer
    -- clkOut(2) :  56.00 MHz -- CRYO clock
    U_DUNE_ClockGen : entity work.ClockManagerUltraScale 
      generic map(
        TPD_G                  => 1 ns,
        TYPE_G                 => "MMCM",  -- or "PLL"
        INPUT_BUFG_G           => true,
        FB_BUFG_G              => true,
        RST_IN_POLARITY_G      => '1',     -- '0' for active low
        NUM_CLOCKS_G           => 3,
        -- MMCM attributes
        BANDWIDTH_G            => "OPTIMIZED",
        CLKIN_PERIOD_G         => 16.0,    -- Input period in ns );
        DIVCLK_DIVIDE_G        => 1,
        CLKFBOUT_MULT_F_G      => 1.0,
        CLKFBOUT_MULT_G        => 16,
        CLKOUT0_DIVIDE_F_G     => 1.0,
        CLKOUT0_DIVIDE_G       => 16,
        CLKOUT0_PHASE_G        => 0.0,
        CLKOUT0_DUTY_CYCLE_G   => 0.5,
        CLKOUT0_RST_HOLD_G     => 3,
        CLKOUT0_RST_POLARITY_G => '1',
        CLKOUT1_DIVIDE_G       => 4,
        CLKOUT1_PHASE_G        => 0.0,
        CLKOUT1_DUTY_CYCLE_G   => 0.5,
        CLKOUT1_RST_HOLD_G     => 3,
        CLKOUT1_RST_POLARITY_G => '1',
        CLKOUT2_DIVIDE_G       => 18,
        CLKOUT2_PHASE_G        => 0.0,
        CLKOUT2_DUTY_CYCLE_G   => 0.5,
        CLKOUT2_RST_HOLD_G     => 3,
        CLKOUT2_RST_POLARITY_G => '1')
      port map(
        clkIn           => DUNEclk,
        rstIn           => DUNERst,
        clkOut(0)       => duneClkInt,       
        clkOut(1)       => duneClkx4,
        clkOut(2)       => cryoClk,
        rstOut(0)       => duneRstInt,
        rstOut(1)       => duneRstx4,
        rstOut(2)       => cryoRst,
        locked          => open
      );
  end generate U_DUNE_PLL;

  U_PROTODUNE_PLL: if SYSTEM_ENVIRONMENT = "PROTODUNE" generate   
    ------------------------------------------
    -- Generate clocks                      --
    ------------------------------------------
    -- clkIn     :  50.00 MHz -- DUNE base clock
    -- clkOut(0) :  50.00 MHz -- Internal copy of the clock
    -- clkOut(1) : 200.00 MHz -- DUNE clock times 4 used for the deserializer
    -- clkOut(2) :  56.00 MHz -- CRYO clock
    U_PROTODUNE_ClockGen : entity work.ClockManagerUltraScale 
      generic map(
        TPD_G                  => 1 ns,
        TYPE_G                 => "MMCM",  -- or "PLL"
        INPUT_BUFG_G           => true,
        FB_BUFG_G              => true,
        RST_IN_POLARITY_G      => '1',     -- '0' for active low
        NUM_CLOCKS_G           => 3,
        -- MMCM attributes
        BANDWIDTH_G            => "OPTIMIZED",
        CLKIN_PERIOD_G         => 20.0,    -- Input period in ns );
        DIVCLK_DIVIDE_G        => 1,
        CLKFBOUT_MULT_F_G      => 1.0,
        CLKFBOUT_MULT_G        => 20,
        CLKOUT0_DIVIDE_F_G     => 1.0,
        CLKOUT0_DIVIDE_G       => 20,
        CLKOUT0_PHASE_G        => 0.0,
        CLKOUT0_DUTY_CYCLE_G   => 0.5,
        CLKOUT0_RST_HOLD_G     => 3,
        CLKOUT0_RST_POLARITY_G => '1',
        CLKOUT1_DIVIDE_G       => 5,
        CLKOUT1_PHASE_G        => 0.0,
        CLKOUT1_DUTY_CYCLE_G   => 0.5,
        CLKOUT1_RST_HOLD_G     => 3,
        CLKOUT1_RST_POLARITY_G => '1',
        CLKOUT2_DIVIDE_G       => 18,
        CLKOUT2_PHASE_G        => 0.0,
        CLKOUT2_DUTY_CYCLE_G   => 0.5,
        CLKOUT2_RST_HOLD_G     => 3,
        CLKOUT2_RST_POLARITY_G => '1')
      port map(
        clkIn           => duneClk,
        rstIn           => duneRst,
        clkOut(0)       => duneClkInt,       
        clkOut(1)       => duneClkx4,
        clkOut(2)       => cryoClk,
        rstOut(0)       => duneRstInt,
        rstOut(1)       => duneRstx4,
        rstOut(2)       => cryoRst,
        locked          => open
     );    
  end generate U_PROTODUNE_PLL;


  U_ISERDESE3_ClkInto56MHz : ISERDESE3
    generic map (
      DATA_WIDTH => 8,            -- Parallel data width (4,8)
      FIFO_ENABLE => "FALSE",     -- Enables the use of the FIFO
      FIFO_SYNC_MODE => "FALSE",  -- Enables the use of internal 2-stage synchronizers on the FIFO
      IS_CLK_B_INVERTED => '1',   -- Optional inversion for CLK_B
      IS_CLK_INVERTED => '0',     -- Optional inversion for CLK
      IS_RST_INVERTED => '0',     -- Optional inversion for RST
      SIM_DEVICE => "ULTRASCALE"  -- Set the device version (ULTRASCALE, ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1,
                                  -- ULTRASCALE_PLUS_ES2)
      )
    port map (
      FIFO_EMPTY => OPEN,         -- 1-bit output: FIFO empty flag
      INTERNAL_DIVCLK => open,    -- 1-bit output: Internally divided down clock used when FIFO is
                                  -- disabled (do not connect)

      Q => phaseDuneCryo,            -- bit registered output
      CLK => duneClkx4,            -- 1-bit input: High-speed clock
      CLKDIV => duneClkInt,         -- 1-bit input: Divided Clock
      CLK_B => duneClkx4,        -- 1-bit input: Inversion of High-speed clock CLK
      D => cryoClk,               -- 1-bit input: Serial Data Input
      FIFO_RD_CLK => '1',         -- 1-bit input: FIFO read clock
      FIFO_RD_EN => '1',          -- 1-bit input: Enables reading the FIFO when asserted
      RST => duneRstInt              -- 1-bit input: Asynchronous Reset
      );
  

   -- cryo clock synchronizers
   U_Sync_SR0 : entity work.Synchronizer     
   port map (
      clk     => cryoClk,
      rst     => cryoRst,
      dataIn  => r.SR0,
      dataOut => SR0
   );

   -- cryo clock synchronizers
   U_Sync_SamCLKiEn : entity work.Synchronizer     
   port map (
      clk     => cryoClk,
      rst     => cryoRst,
      dataIn  => r.SamCLKiEn,
      dataOut => SamCLKiEnable
   );

  -- sequential process
  seq : process (duneClkInt) is
  begin
    if (rising_edge(duneClkInt)) then
      r <= rin after TPD_G;
    end if;
  end process seq;

  -- core, combinatorial, process
  comb : process (r, duneRstInt) is
    variable v : WIBModelRegType;
  begin
    v := r;

    -- register external signals
    v.CmdAddr       := CmdAddr;
    v.SyncCmdStrobe := SyncCmdStrobe;
    v.SyncCmd       := SyncCmd;

    -- local copy of global time stamp
    v.timeStamp := r.timeStamp + '1';      
    if r.resetTimeStampCmd = '1' then
      v.timeStamp := (others => '0');
    end if;

    -- localCycletime
    if r.cycleTime = "111110" then         --62 decimal
      v.cycleTime := (others => '0');
    else
      v.cycleTime := r.cycleTime + '1';            
    end if;
    if r.resetCycleTimeCmd = '1' then
      v.cycleTime := (others => '0');
    end if;

    -- SR0 signals
    if r.SR0EnCmd = '1' then
      v.SR0 := '1';
    end if;
    if r.SR0DisCmd = '1' then
      v.SR0 := '0';
    end if;

    -- SamCLKiEn
    if r.SamCLKiEnCmd = '1' then
      v.SamCLKiReady := '1';
    end if;

    if ((r.SamCLKiReady = '1') and (r.SamCLKiReadyCycleTime = r.cycleTime)) then
      v.SamCLKiEn := '1';
    end if;
    if r.SamCLKiDisCmd = '1' then
      v.SamCLKiEn := '0';
      v.SamCLKiReady := '0';
    end if;

    --reset all commands
    v.resetTimeStampCmd := '0';
    v.resetCycleTimeCmd := '0';
    v.SamCLKiEnCmd      := '0';
    v.SR0EnCmd          := '0';
    v.SamCLKiDisCmd     := '0';
    v.SR0DisCmd         := '0';
    -- decodes commands
    if r.CmdAddr = THIS_MODULE_CMD_ADDRESS then
      if r.SyncCmdStrobe = '1' then
        case r.SyncCmd is
          when x"0000" =>
            v.resetTimeStampCmd := '1';
          when x"0001" =>
            v.resetCycleTimeCmd := '1';
          when x"0002" =>
            v.SamCLKiEnCmd := '1';
          when x"0003" =>
            v.SR0EnCmd := '1';
          when x"0004" =>
            v.SamCLKiDisCmd := '1';
          when x"0005" =>
            v.SR0DisCmd := '1';         
          when others =>
        end case;  
      end if;     
    end if;

    -- Synchronous Reset
    if (duneRstInt = '1' ) then
      v := WIB_MODEL_REG_INIT_C;
    end if;

    -- Register the variable for next clock cycle
    rin <= v;

    timeStamp <= r.timeStamp;
    cycleTime <= r.cycleTime;


  end process comb;

end rtl;
