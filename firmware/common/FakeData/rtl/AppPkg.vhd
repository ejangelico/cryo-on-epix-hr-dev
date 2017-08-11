-------------------------------------------------------------------------------
-- File       : AppPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-21
-- Last update: 2017-04-21
-------------------------------------------------------------------------------
-- Description: Application's Package File
-------------------------------------------------------------------------------
-- This file is part of 'EPIX HR Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'EPIX HR Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

package AppPkg is


   constant NUMBER_OF_ASICS_C : natural := 0;   
   
   constant HR_FD_NUM_AXI_MASTER_SLOTS_C : natural := 3;
   constant HR_FD_NUM_AXI_SLAVE_SLOTS_C : natural := 1;
   
   constant PLLREGS_AXI_INDEX_C     : natural := 0;
   constant HR_FD_REG_AXI_INDEX_C   : natural := 1;
   constant TRIG_REG_AXI_INDEX_C    : natural := 2;
   
   constant PLLREGS_AXI_BASE_ADDR_C    : slv(31 downto 0) := X"00000000";
   constant HR_FD_REG_AXI_BASE_ADDR_C  : slv(31 downto 0) := X"01000000";
   constant TRIG_REG_AXI_BASE_ADDR_C   : slv(31 downto 0) := X"02000000";

   
   constant HR_FD_AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(HR_FD_NUM_AXI_MASTER_SLOTS_C-1 downto 0) := (
      PLLREGS_AXI_INDEX_C      => (
         baseAddr             => PLLREGS_AXI_BASE_ADDR_C,
         addrBits             => 24,
         connectivity         => x"FFFF"),
      HR_FD_REG_AXI_INDEX_C      => ( 
         baseAddr             => HR_FD_REG_AXI_BASE_ADDR_C,
         addrBits             => 24,
         connectivity         => x"FFFF"),
      TRIG_REG_AXI_INDEX_C      => ( 
         baseAddr             => TRIG_REG_AXI_BASE_ADDR_C,
         addrBits             => 24,
         connectivity         => x"FFFF")
   );

   
   type HR_FDConfigType is record
      pwrEnableReq         : sl;
      pwrManual            : sl;
      pwrManualDig         : sl;
      pwrManualAna         : sl;
      pwrManualIo          : sl;
      pwrManualFpga        : sl;
      asicMask             : slv(NUMBER_OF_ASICS_C-1 downto 0);
      acqCnt               : slv(31 downto 0);
      ReqTriggerCnt        : slv(31 downto 0);
      syncCounter          : slv(31 downto 0);
      requestStartupCal    : sl;
      startupAck           : sl;
      startupFail          : sl;
      EnAllFrames          : sl;
      EnSingleFrame        : sl;
      hrDbgSel1            : slv(4 downto 0);
      hrDbgSel2            : slv(4 downto 0);
   end record;

   constant HR_FD_CONFIG_INIT_C : HR_FDConfigType := (
      pwrEnableReq         => '0',
      pwrManual            => '0',
      pwrManualDig         => '0',
      pwrManualAna         => '0',
      pwrManualIo          => '0',
      pwrManualFpga        => '0',
      asicMask             => (others => '0'),
      acqCnt               => (others => '0'),
      ReqTriggerCnt        => x"000000FF",
      syncCounter          => (others => '0'),
      requestStartupCal    => '1',
      startupAck           => '0',
      startupFail          => '0',
      EnAllFrames          => '1',
      EnSingleFrame        => '0',
      hrDbgSel1            => (others => '0'),
      hrDbgSel2            => (others => '0')
   );
   

end package AppPkg;

package body AppPkg is

end package body AppPkg;
