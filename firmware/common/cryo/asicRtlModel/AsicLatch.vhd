-------------------------------------------------------------------------------
-- File       : Synchronizer.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: A simple Flip FLop  USED FOR SIMULATION ONLY.
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

library surf;
use surf.StdRtlPkg.all;

entity AsicLatch is
   generic (
      TPD_G          : time     := 1 ns;
      RST_POLARITY_G : sl       := '1';    -- '1' for active HIGH reset, '0' for active LOW reset
      OUT_POLARITY_G : sl       := '1';    -- 0 for active LOW, 1 for active HIGH
      RST_ASYNC_G    : boolean  := false;  -- Reset is asynchronous
      STAGES_G       : positive := 2;
      BYPASS_SYNC_G  : boolean  := false;  -- Bypass Synchronizer module for synchronous data configuration      
      INIT_G         : slv      := "0");
   port (
      clk     : in  sl;                 -- clock to be SYNC'd to
      rst     : in  sl := not RST_POLARITY_G;  -- Optional reset
      dataIn  : in  sl;                 -- Data to be 'synced'
      dataOut : out sl);                -- synced data
end AsicLatch;

architecture rtl of AsicLatch is

   constant INIT_C : slv(STAGES_G-1 downto 0) := ite(INIT_G = "0", slvZero(STAGES_G), INIT_G);

   signal crossDomainSyncReg : slv(STAGES_G-1 downto 0) := INIT_C;
   signal rin                : slv(STAGES_G-1 downto 0);

   
begin

   GEN : if (BYPASS_SYNC_G = false) generate

      comb : process (crossDomainSyncReg, dataIn, rst) is
      begin
         rin <= crossDomainSyncReg(STAGES_G-2 downto 0) & dataIn;

         if (OUT_POLARITY_G = '1') then
            dataOut <= crossDomainSyncReg(STAGES_G-1);
         else
            dataOut <= not(crossDomainSyncReg(STAGES_G-1));
         end if;
         
      end process comb;

      ASYNC_RST : if (RST_ASYNC_G) generate
         seq : process (clk, rst) is
         begin
            if (falling_edge(clk)) then
               crossDomainSyncReg <= rin after TPD_G;
            end if;
            if (rst = RST_POLARITY_G) then
               crossDomainSyncReg <= INIT_C after TPD_G;
            end if;
         end process seq;
      end generate ASYNC_RST;

      SYNC_RST : if (not RST_ASYNC_G) generate
         seq : process (clk) is
         begin
            if (falling_edge(clk)) then
               if (rst = RST_POLARITY_G) then
                  crossDomainSyncReg <= INIT_C after TPD_G;
               else
                  crossDomainSyncReg <= rin after TPD_G;
               end if;
            end if;
         end process seq;
      end generate SYNC_RST;

   end generate;

   BYPASS : if (BYPASS_SYNC_G = true) generate

      dataOut <= dataIn when(OUT_POLARITY_G = '1') else not(dataIn);
      
   end generate;

end architecture rtl;
