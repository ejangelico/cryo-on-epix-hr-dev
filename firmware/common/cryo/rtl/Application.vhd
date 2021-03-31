-------------------------------------------------------------------------------
-- File       : Application.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-21
-- Last update: 2021-02-01
-------------------------------------------------------------------------------
-- Description: Application Core's Top Level
-------------------------------------------------------------------------------
-- This file is part of 'EPIX HR Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'EPIX HR Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiPkg.all;
use surf.Pgp2bPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;
use surf.Ad9249Pkg.all;
use surf.Code8b10bPkg.all;

library epix_hr_core;
use epix_hr_core.EpixHrCorePkg.all;

use work.HrAdcPkg.all;
use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Application is
   generic (
      TPD_G            : time            := 1 ns;
      APP_CONFIG_G     : AppConfigType   := APP_CONFIG_INIT_C;
      SIMULATION_G     : boolean         := false;
      DDR_GEN_G        : boolean         := false;
      TEST_SYSTEM_C00_G: boolean         := false;
      BUILD_INFO_G     : BuildInfoType;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C;
      IODELAY_GROUP_G   : string          := "DEFAULT_GROUP");
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- System Clock and Reset
      sysClk           : in    sl;
      sysRst           : in    sl;
      -- AXI-Lite Register Interface (sysClk domain)
      -- Register Address Range = [0x80000000:0xFFFFFFFF]
      sAxilReadMaster  : in    AxiLiteReadMasterType;
      sAxilReadSlave   : out   AxiLiteReadSlaveType;
      sAxilWriteMaster : in    AxiLiteWriteMasterType;
      sAxilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- AXI Stream, one per QSFP lane (sysClk domain)
      mAxisMasters     : out   AxiStreamMasterArray(3 downto 0);
      mAxisSlaves      : in    AxiStreamSlaveArray(3 downto 0);
      -- Auxiliary AXI Stream, (sysClk domain)
      -- 0 is pseudo scope, 1 is slow adc monitoring
      sAuxAxisMasters  : out   AxiStreamMasterArray(1 downto 0);
      sAuxAxisSlaves   : in    AxiStreamSlaveArray(1 downto 0);
      -- DDR's AXI Memory Interface (sysClk domain)
      -- DDR Address Range = [0x00000000:0x3FFFFFFF]
      mAxiReadMaster   : out   AxiReadMasterType;
      mAxiReadSlave    : in    AxiReadSlaveType;
      mAxiWriteMaster  : out   AxiWriteMasterType;
      mAxiWriteSlave   : in    AxiWriteSlaveType;
      -- Microblaze's Interrupt bus (sysClk domain)
      mbIrq            : out   slv(7 downto 0);
      -- ssi commands (Lane and Vc 0)
      ssiCmd           : in    SsiCmdMasterType := SSI_CMD_MASTER_INIT_C;
      -----------------------
      -- Application Ports --
      -----------------------
      -- System Ports
      digPwrEn         : out   sl;
      anaPwrEn         : out   sl;
      syncDigDcDc      : out   sl;
      syncAnaDcDc      : out   sl;
      syncDcDc         : out   slv(6 downto 0);
      led              : out   slv(3 downto 0);
      daqTg            : in    sl;
      connTgOut        : out   sl;
      connMps          : out   sl;
      connRun          : in    sl;
      -- Fast ADC Ports
      adcSpiClk        : out   sl;
      adcSpiData       : inout sl;
      adcSpiCsL        : out   sl;
      adcPdwn          : out   sl;
      adcClkP          : out   sl;
      adcClkM          : out   sl;
      adcDoClkP        : in    sl;
      adcDoClkM        : in    sl;
      adcFrameClkP     : in    sl;
      adcFrameClkM     : in    sl;
      adcMonDoutP      : in    slv(4 downto 0);
      adcMonDoutN      : in    slv(4 downto 0);
      -- Slow ADC
      slowAdcSclk      : out   sl;
      slowAdcDin       : out   sl;
      slowAdcCsL       : out   sl;
      slowAdcRefClk    : out   sl;
      slowAdcDout      : in    sl;
      slowAdcDrdy      : in    sl;
      slowAdcSync      : out   sl;
      -- Slow DACs Port
      sDacCsL          : out   slv(4 downto 0);
      hsDacCsL         : out   sl;
      hsDacLoad        : out   sl;
      dacClrL          : out   sl;
      dacSck           : out   sl;
      dacDin           : out   sl;
      -- ASIC Gbps Ports
      asicDataP        : inout slv(23 downto 0);
      asicDataN        : inout slv(23 downto 0);
      -- ASIC Control Ports
      asicR0           : out   sl;
      asicPpmat        : out   sl;
      asicGlblRst      : out   sl;
      asicSync         : out   sl;
      asicAcq          : out   sl;
      asicRoClkP       : out   slv(3 downto 0);
      asicRoClkN       : out   slv(3 downto 0);
      -- SACI Ports
      asicSaciCmd      : out   sl;
      asicSaciClk      : out   sl;
      asicSaciSel      : out   slv(3 downto 0);
      asicSaciRsp      : in    sl;
      -- Spare Ports
      spareHpP         : inout slv(11 downto 0);
      spareHpN         : inout slv(11 downto 0);
      spareHrP         : inout slv(5 downto 0);
      spareHrN         : inout slv(5 downto 0);
      -- GTH Ports
      gtRxP            : in    sl;
      gtRxN            : in    sl;
      gtTxP            : out   sl;
      gtTxN            : out   sl;
      gtRefP           : in    sl;
      gtRefN           : in    sl;
      smaRxP           : in    sl;
      smaRxN           : in    sl;
      smaTxP           : out   sl;
      smaTxN           : out   sl);

end Application;

architecture mapping of Application is


   attribute keep : string;

   -- ASIC signals
   constant STREAMS_PER_ASIC_C : natural := 2;
   constant INTERNAL_DAC_C     : boolean := false;

   constant SACI_CLK_PERIOD_C   : real  := ite(SIMULATION_G, 0.12E-6, 0.25E-6);
   constant CRYO_BASECLK_MULT_C : real  := 51.25;

   --heart beat signal
   signal heartBeat      : sl;
   
   -- prbs signals
   signal prbsBusy       : slv(NUMBER_OF_LANES_C-1 downto 0) := (others => '0');

   -- clock signals
   signal appClk         : sl;
   signal bitClk         : sl;
   signal byteClk        : sl;
   signal deserClk       : sl;
   signal bitClkB        : sl;
   signal byteClkB       : sl;
   signal deserClkB      : sl;
   signal asicRdClk      : sl;
   signal idelayCtrlClk  : sl;
   signal appRst         : sl;
   signal axiRst         : sl;
   signal bitRst         : sl;
   signal byteClkRst     : sl;
   signal asicRdClkRst   : sl;
   signal idelayCtrlRst  : sl;
   signal idelayCtrlRst_i: sl;
   signal clkLocked      : sl;
     

   -- AXI-Lite Signals
   signal sAxiReadMaster  : AxiLiteReadMasterArray(HR_FD_NUM_AXI_SLAVE_SLOTS_C-1 downto 0);
   signal sAxiReadSlave   : AxiLiteReadSlaveArray(HR_FD_NUM_AXI_SLAVE_SLOTS_C-1 downto 0);
   signal sAxiWriteMaster : AxiLiteWriteMasterArray(HR_FD_NUM_AXI_SLAVE_SLOTS_C-1 downto 0);
   signal sAxiWriteSlave  : AxiLiteWriteSlaveArray(HR_FD_NUM_AXI_SLAVE_SLOTS_C-1 downto 0);
   -- AXI-Lite Signals
   signal mAxiWriteMasters : AxiLiteWriteMasterArray(HR_FD_NUM_AXI_MASTER_SLOTS_C-1 downto 0); 
   signal mAxiWriteSlaves  : AxiLiteWriteSlaveArray(HR_FD_NUM_AXI_MASTER_SLOTS_C-1 downto 0); 
   signal mAxiReadMasters  : AxiLiteReadMasterArray(HR_FD_NUM_AXI_MASTER_SLOTS_C-1 downto 0); 
   signal mAxiReadSlaves   : AxiLiteReadSlaveArray(HR_FD_NUM_AXI_MASTER_SLOTS_C-1 downto 0); 

   --constant AXI_STREAM_CONFIG_O_C : AxiStreamConfigType   := ssiAxiStreamConfig(4, TKEEP_COMP_C);
   signal imAxisMasters    : AxiStreamMasterArray(3 downto 0);
   signal mAxisMastersPRBS : AxiStreamMasterArray(3 downto 0);
   signal mAxisSlavesPRBS  : AxiStreamSlaveArray(3 downto 0);
   signal mAxisMastersASIC : AxiStreamMasterArray(3 downto 0);
   signal mAxisSlavesASIC  : AxiStreamSlaveArray(3 downto 0);

   -- Triggers and associated signals
   signal iDaqTrigger        : sl := '0';
   signal iRunTrigger        : sl := '0';
   signal opCode             : slv(7 downto 0);
   signal pgpOpCodeOneShot   : sl;
   signal acqStart           : sl;
   signal dataSend           : sl;
   signal saciPrepReadoutReq : sl;
   signal saciPrepReadoutAck : sl;
   signal pgpRxOut           : Pgp2bRxOutType;

   -- ASIC signals (placeholders)
   signal iAsicEnA             : sl;
   signal iAsicEnB             : sl;
   signal iAsicVid             : sl;
   signal iAsicSR0             : sl;
   signal iAsicSR0Raw          : sl;
   signal iAsicSR0RefClk       : sl;
   signal iAsic01DM1           : sl;
   signal iAsic01DM2           : sl;
   signal iAsicPPbe            : sl;
   signal iAsicPpmat           : sl;
   signal iAsicR0              : sl;
   signal iAsicSync            : sl;
   signal iAsicAcq             : sl;
   signal iAsicGrst            : sl;
   signal iSaciSelL            : slv(3 downto 0);
   signal iSaciClk             : sl;
   signal iSaciCmd             : sl;
   signal iSaciRsp             : sl;
   signal boardConfig          : AppConfigType;
   signal monitoringSig        : slv(1 downto 0);
   
   signal adcClk               : sl;
   signal errInhibit           : sl;


   -- HS DAC
   signal WFDacDin_i    : sl;
   signal WFDacSclk_i   : sl;
   signal WFDacCsL_i    : sl;
   signal WFDacLdacL_i  : sl;
   signal WFDacClrL_i   : sl;
   signal WFDac20bitDin_i     : sl;
   signal WFDac20bitSclk_i    : sl;
   signal WFDac20bitSyncL_i   : sl; 
   signal WFDac20bitLdacL_i   : sl;
   signal WFDac20bitLdacLSync : sl;
   signal WFDac20bitClrL_i    : sl;

   -- ADC signals
   signal adcValid         : slv(3 downto 0);
   signal adcData          : Slv16Array(3 downto 0);
   signal adcStreams       : AxiStreamMasterArray(3 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
   signal adcStreamsEn_n   : slv(STREAMS_PER_ASIC_C-1 downto 0) := (others => '0');
   signal monAdc           : Ad9249SerialGroupType;
   signal adcSpiCsL_i      : slv(1 downto 0);
   signal adcPdwn_i        : slv(0 downto 0);
   signal idelayRdy        : sl;

   -- Power up reset to SERDES block (Monitoring ADC)
   signal adcCardPowerUp     : sl;
   signal adcCardPowerUpEdge : sl;
   signal serdesReset        : sl;

   -- Power signals
   signal digPwrEn_i         : sl;
   signal anaPwrEn_i         : sl;   
   
   -- slow DACs
   signal sDacDin_i    : sl;
   signal sDacSclk_i   : sl;
   signal sDacCsL_i    : slv(4 downto 0);
   signal sDacClrb_i   : sl;


   -- External Signals 
   signal serialIdIo           : slv(1 downto 0) := "00";

   -- DDR signals
   signal startDdrTest_n       : sl;
   signal startDdrTest         : sl;
   -- DDR sconstants
   constant DDR_AXI_CONFIG_C : AxiConfigType := axiConfig(
      ADDR_WIDTH_C => 15,
      DATA_BYTES_C => 32,
      ID_BITS_C    => 4,
      LEN_BITS_C   => 8);

   constant START_ADDR_C : slv(DDR_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   constant STOP_ADDR_C  : slv(DDR_AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');

   -- Equalizer signals
   signal EqualizerLosIn : slv(5 downto 0);
   -- Programmable power supply signals
   signal enableLDOOut        : slv(1 downto 0);
   signal dacSclkProgSupplyOut: sl;
   signal dacDinProgSupplyOut : sl;
   signal dacCsbProgSupplyOut : slv(1 downto 0);
   signal dacClrbProgSupplyOut: sl;
   -- CJC
   --signal cjcRst            : slv(1 downto 0);
   --signal cjcDec            : slv(1 downto 0);
   --signal cjcInc            : slv(1 downto 0);
   --signal cjcFrqtbl         : slv(1 downto 0);
   --signal cjcRate           : slv(3 downto 0);
   --signal cjcBwSel          : slv(3 downto 0);
   --signal cjcFrqSel         : slv(7 downto 0);
   --signal cjcSfout          : slv(3 downto 0);
   --signal cjcLos            : sl;
   --signal cjcLol            : sl;
   signal pllSck              : sl;
   signal pllCsL              : sl;
   signal pllSdo              : sl;
   signal pllSdi              : sl;
   --
   signal adcSerial         : HrAdcSerialGroupArray(NUMBER_OF_ASICS_C-1 downto 0);
   signal asicStreams       : AxiStreamMasterArray(STREAMS_PER_ASIC_C-1 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);

   attribute keep of appClk            : signal is "true";
   attribute keep of asicRdClk         : signal is "true";
   attribute keep of startDdrTest_n    : signal is "true";
   attribute keep of iAsicAcq          : signal is "true";

   attribute keep of adcStreams        : signal is "true";

   attribute keep of iSaciSelL         : signal is "true";
   attribute keep of iSaciClk          : signal is "true";
   attribute keep of iSaciCmd          : signal is "true";
   attribute keep of iSaciRsp          : signal is "true";

   signal dummy : slv(5 downto 0);


begin

  -----------------------------------------------------------------------------
  -- remaps data lines into adapter board control/status lines
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Programmable power supply IOBUF & MAPPING
  -----------------------------------------------------------------------------
  IOBUF_DATAP_19 : IOBUF port map (O => open, I => enableLDOOut(0), IO => asicDataP(19), T => '0');
  --
  IOBUF_DATAN_19 : IOBUF port map (O => open, I => enableLDOOut(1), IO => asicDataN(19), T => '0');
  --
  IOBUF_SPARE_HPP_0 : IOBUF port map (O => open, I => dacDinProgSupplyOut,    IO => spareHpP(0), T => '0');
  IOBUF_SPARE_HPP_1 : IOBUF port map (O => open, I => dacSclkProgSupplyOut,   IO => spareHpP(1), T => '0');
  IOBUF_SPARE_HPP_2 : IOBUF port map (O => open, I => dacClrbProgSupplyOut,   IO => spareHpP(2), T => '0');
  --
  IOBUF_SPARE_HPN_0 : IOBUF port map (O => open, I => dacCsbProgSupplyOut(0), IO => spareHpN(0), T => '0');
  IOBUF_SPARE_HPN_1 : IOBUF port map (O => open, I => dacCsbProgSupplyOut(1), IO => spareHpN(1), T => '0');
  --
  -----------------------------------------------------------------------------
  -- Equalizer IOBUF & MAPPING
  -----------------------------------------------------------------------------
  -- EqualizerLosIn(5 downto 3) <= asicDataN(18 downto 16);
  -- EqualizerLosIn(2 downto 0) <= asicDataP(18 downto 16);
  --
  IOBUF_DATAP_16 : IOBUF port map (O => EqualizerLosIn(0), I => '0', IO => asicDataP(16), T => '1');
  IOBUF_DATAP_17 : IOBUF port map (O => EqualizerLosIn(1), I => '0', IO => asicDataP(17), T => '1');
  IOBUF_DATAP_18 : IOBUF port map (O => EqualizerLosIn(2), I => '0', IO => asicDataP(18), T => '1');
  --
  IOBUF_DATAN_16 : IOBUF port map (O => EqualizerLosIn(3), I => '0', IO => asicDataN(16), T => '1');
  IOBUF_DATAN_17 : IOBUF port map (O => EqualizerLosIn(4), I => '0', IO => asicDataN(17), T => '1');
  IOBUF_DATAN_18 : IOBUF port map (O => EqualizerLosIn(5), I => '0', IO => asicDataN(18), T => '1');

  -----------------------------------------------------------------------------
  -- Clock Jitter Cleaner IOBUF & MAPPING
  -----------------------------------------------------------------------------
  --IOBUF_DATAP_1 : IOBUF port map (O => open,   I => cjcFrqtbl(0), IO => asicDataP(1),  T => cjcFrqtbl(1));
  --IOBUF_DATAP_7 : IOBUF port map (O => open,   I => cjcDec(0),    IO => asicDataP(7),  T => cjcDec(1));
  --IOBUF_DATAP_8 : IOBUF port map (O => open,   I => cjcInc(0),    IO => asicDataP(8),  T => cjcInc(1));
  --IOBUF_DATAP_9 : IOBUF port map (O => open,   I => cjcFrqSel(0), IO => asicDataP(9),  T => cjcFrqSel(4));
  --IOBUF_DATAP_10: IOBUF port map (O => open,   I => cjcFrqSel(1), IO => asicDataP(10), T => cjcFrqSel(5));
  --IOBUF_DATAP_11: IOBUF port map (O => open,   I => cjcFrqSel(2), IO => asicDataP(11), T => cjcFrqSel(6));
  --IOBUF_DATAP_12: IOBUF port map (O => open,   I => cjcFrqSel(3), IO => asicDataP(12), T => cjcFrqSel(7));
  --IOBUF_DATAP_13: IOBUF port map (O => cjcLos, I => '0',          IO => asicDataP(13), T => '1');
  --
  --IOBUF_DATAN_1 : IOBUF port map (O => open,   I => cjcRst(0),    IO => asicDataN(1),  T => cjcRst(1));
  --IOBUF_DATAN_7 : IOBUF port map (O => open,   I => cjcRate(0),   IO => asicDataN(7),  T => cjcRate(2));
  --IOBUF_DATAN_8 : IOBUF port map (O => open,   I => cjcRate(1),   IO => asicDataN(8),  T => cjcRate(3));
  --IOBUF_DATAN_9 : IOBUF port map (O => open,   I => cjcBwSel(0),  IO => asicDataN(9),  T => cjcBwSel(2));
  --IOBUF_DATAN_10: IOBUF port map (O => open,   I => cjcBwSel(1),  IO => asicDataN(10), T => cjcBwSel(3));
  --IOBUF_DATAN_11: IOBUF port map (O => open,   I => cjcSfout(0),  IO => asicDataN(11), T => cjcSfout(2));
  --IOBUF_DATAN_12: IOBUF port map (O => open,   I => cjcSfout(1),  IO => asicDataN(12), T => cjcSfout(3));
  --IOBUF_DATAN_13: IOBUF port map (O => cjcLol, I => '0',          IO => asicDataN(13), T => '1');
  --
  --OBUFDS_CLK    : OBUFDS port map (I  => asicRdClk,    O  => asicRoClkP(0),OB => asicRoClkN(0));      

  -----------------------------------------------------------------------------
  -- PLL IOBUF & MAPPING
  -----------------------------------------------------------------------------
  OBUFDS_PLLREFCLK : OBUFDS port map (I  => asicRdClk,    O  => asicDataP(8),OB => asicDataN(8));
  --
  IOBUF_DATAP_9    : IOBUF port map (O => open,   I => pllSck, IO => asicDataP(9),  T => '0');
  IOBUF_DATAP_10   : IOBUF port map (O => open,   I => pllCsL, IO => asicDataP(10), T => '0');
  --
  IOBUF_DATAN_9    : IOBUF port map (O => open,   I => pllSdi, IO => asicDataN(9),  T => '0');
  IOBUF_DATAN_10   : IOBUF port map (O => pllSdo, I => '0',    IO => asicDataN(10), T => '1');
  
  -----------------------------------------------------------------------------
  -- External 20 bit DAC IOBUF & MAPPING
  -----------------------------------------------------------------------------
  IOBUF_DATAP_20 : IOBUF port map (O => open,   I => WFDac20bitSclk_i,  IO => asicDataP(20),  T => '0');
  IOBUF_DATAP_21 : IOBUF port map (O => open,   I => WFDac20bitLdacLSync, IO => asicDataP(21),  T => '0');
  --IOBUF_DATAP_22 : IOBUF port map (O => WFDac20bitSDO,   I => '0', IO => asicDataP(22),  T => '1');
  IOBUF_DATAP_23 : IOBUF port map (O => open,   I => '1',               IO => asicDataP(23),  T => '0');
  --
  IOBUF_DATAN_20 : IOBUF port map (O => open,   I => WFDac20bitClrL_i,  IO => asicDataN(20),  T => '0');
  IOBUF_DATAN_21 : IOBUF port map (O => open,   I => WFDac20bitClrL_i,  IO => asicDataN(21),  T => '0');
  IOBUF_DATAN_22 : IOBUF port map (O => open,   I => WFDac20bitDin_i,   IO => asicDataN(22),  T => '0');
  IOBUF_DATAN_23 : IOBUF port map (O => open,   I => WFDac20bitSyncL_i, IO => asicDataN(23),  T => '0');
  
   ---------------------
   -- Heart beat LED  --
   ---------------------
   U_Heartbeat : entity surf.Heartbeat
      generic map(
         PERIOD_IN_G => 10.0E-9
      )   
      port map (
         clk => sysClk,
         o   => heartBeat
      );
   
   ----------------------------------------------------------------------------
   -- Signal routing
   ----------------------------------------------------------------------------
   led(0)          <= clkLocked;
   led(1)          <= prbsBusy(0) or prbsBusy(1) or prbsBusy(2) or prbsBusy(3);
   led(2)          <= '0';
   led(3)          <= not heartBeat;
   

   ----------------------------------------------------------------------------
   -- axi stream routing
   ----------------------------------------------------------------------------
   mAxisMasters    <= imAxisMasters;
   --imAxisMasters(0) is connected to the stream mux directly

   ----------------------------------------------------------------------------
   -- power enable routing
   ----------------------------------------------------------------------------
   digPwrEn <= digPwrEn_i;
   anaPwrEn <= anaPwrEn_i;
   
   ----------------------------------------------------------------------------
   -- ADC routing
   ----------------------------------------------------------------------------
   adcSpiCsL       <= adcSpiCsL_i(0);
   adcPdwn         <= adcPdwn_i(0);
   slowAdcSync     <= '0';              -- not used, not connected to the ADC
                                        -- via no load resistor (R67)
   ----------------------------------------------------------------------------
   -- routing DAC signals to external IOs
   ----------------------------------------------------------------------------
   hsDacCsL        <= WFDacCsL_i;       -- DAC8812C chip select
   hsDacLoad       <= WFDacLdacL_i;     -- DAC8812C chip select
   sDacCsL         <= sDacCsL_i;        -- DACs to set static configuration
   -- shared DAC signal
   dacClrL         <= WFDacClrL_i when WFDacCsL_i = '0' else
                      sDacClrb_i;
   dacSck          <= WFDacSclk_i when WFDacCsL_i = '0' else
                      sDacSclk_i;
   dacDin          <= WFDacDin_i when WFDacCsL_i = '0' else
                      sDacDin_i;

   ----------------------------------------------------------------------------
   -- SACI signals
   ----------------------------------------------------------------------------
   asicSaciCmd     <= iSaciCmd;
   asicSaciClk     <= iSaciClk;
   asicSaciSel     <= iSaciSelL;
   iSaciSelL(3 downto 1) <=  (others => '1');
   iSaciRsp        <= asicSaciRsp; -- signal for csp

   ----------------------------------------------------------------------------
   -- Monitoring signals
   ----------------------------------------------------------------------------
   connTgOut <= 
      iAsic01DM1          when boardConfig.epixhrDbgSel1 = "00000" else
      iAsicSync           when boardConfig.epixhrDbgSel1 = "00001" else
      monitoringSig(0)    when boardConfig.epixhrDbgSel1 = "00010" else
      iAsicAcq            when boardConfig.epixhrDbgSel1 = "00011" else
      iAsicSR0RefClk      when boardConfig.epixhrDbgSel1 = "00100" else
      iAsicSR0            when boardConfig.epixhrDbgSel1 = "00101" else
      iSaciClk            when boardConfig.epixhrDbgSel1 = "00110" else
      iSaciCmd            when boardConfig.epixhrDbgSel1 = "00111" else
      asicSaciRsp         when boardConfig.epixhrDbgSel1 = "01000" else
      iSaciSelL(0)        when boardConfig.epixhrDbgSel1 = "01001" else
      iSaciSelL(1)        when boardConfig.epixhrDbgSel1 = "01010" else
      asicRdClk           when boardConfig.epixhrDbgSel1 = "01011" else
      --bitClk            when boardConfig.epixhrDbgSel1 = "01100" else 
      byteClk             when boardConfig.epixhrDbgSel1 = "01101" else
      WFDac20bitDin_i     when boardConfig.epixhrDbgSel1 = "01110" else
      WFDac20bitSclk_i    when boardConfig.epixhrDbgSel1 = "01111" else
      WFDac20bitSyncL_i   when boardConfig.epixhrDbgSel1 = "10000" else
      WFDac20bitLdacLSync when boardConfig.epixhrDbgSel1 = "10001" else
      WFDac20bitClrL_i    when boardConfig.epixhrDbgSel1 = "10010" else
      iAsicGrst           when boardConfig.epixhrDbgSel1 = "10011" else
      '0';   
   
   connMps <=
      iAsic01DM2          when boardConfig.epixhrDbgSel2 = "00000" else
      iAsicSync           when boardConfig.epixhrDbgSel2 = "00001" else
      monitoringSig(1)    when boardConfig.epixhrDbgSel2 = "00010" else
      iAsicAcq            when boardConfig.epixhrDbgSel2 = "00011" else
      iAsicSR0RefClk      when boardConfig.epixhrDbgSel2 = "00100" else
      iAsicSR0            when boardConfig.epixhrDbgSel2 = "00101" else
      iSaciClk            when boardConfig.epixhrDbgSel2 = "00110" else
      iSaciCmd            when boardConfig.epixhrDbgSel2 = "00111" else
      asicSaciRsp         when boardConfig.epixhrDbgSel2 = "01000" else
      iSaciSelL(0)        when boardConfig.epixhrDbgSel2 = "01001" else
      iSaciSelL(1)        when boardConfig.epixhrDbgSel2 = "01010" else
      asicRdClk           when boardConfig.epixhrDbgSel2 = "01011" else
      --bitClk            when boardConfig.epixhrDbgSel2 = "01100" else
      byteClkB            when boardConfig.epixhrDbgSel2 = "01101" else
      WFDac20bitDin_i     when boardConfig.epixhrDbgSel1 = "01110" else
      WFDac20bitSclk_i    when boardConfig.epixhrDbgSel1 = "01111" else
      WFDac20bitSyncL_i   when boardConfig.epixhrDbgSel1 = "10000" else
      WFDac20bitLdacLSync when boardConfig.epixhrDbgSel1 = "10001" else
      WFDac20bitClrL_i    when boardConfig.epixhrDbgSel1 = "10010" else
--      WFdacDin_i        when boardConfig.epixhrDbgSel2 = "01110" else
--      WFdacSclk_i       when boardConfig.epixhrDbgSel2 = "01111" else
--      WFdacCsL_i        when boardConfig.epixhrDbgSel2 = "10000" else
--      WFdacLdacL_i      when boardConfig.epixhrDbgSel2 = "10001" else
--      WFdacClrL_i       when boardConfig.epixhrDbgSel2 = "10010" else
      iAsicGrst           when boardConfig.epixhrDbgSel1 = "10011" else
      '0';

   -----------------------------------------------------------------------------
   -- ASIC signal routing
   -----------------------------------------------------------------------------
   asicPpmat       <= iasicPpmat;
   asicGlblRst     <= iAsicGrst;
   asicSync        <= iasicSync;
   asicAcq         <= iasicAcq;
   asicR0          <= iAsicSR0;
  
   -------------------------------------------------------------------------------
   -- unasigned signals
   ----------------------------------------------------------------------------
   mbIrq           <= (others => '0');  
   asicRoClkN(3 downto 1) <= (others => '0');
   asicRoClkP(3 downto 1) <= (others => '1');  
   gtTxP           <= '0';
   gtTxN           <= '1';
   smaTxP          <= '0';
   smaTxN          <= '1';
   asicDataN(4)    <= '0';
   asicDataN(6)    <= '0';
   asicDataN(15 downto 14)  <= (others => '0');
   --asicDataN(23 downto 20)  <= (others => '0');
   asicDataP(4)    <= '0';
   asicDataP(6)    <= '0';
   asicDataP(15 downto 14)  <= (others => '0');
   --asicDataP(23 downto 20)  <= (others => '0');

   ------------------------------------------
   -- Generate clocks from 156.25 MHz PGP  --
   ------------------------------------------
   -- clkIn     : 156.25 MHz PGP
   -- clkOut(0) : 100.00 MHz app clock
   -- clkOut(1) : 100.00 MHz asic clock
   -- clkOut(2) : 100.00 MHz asic clock
   -- clkOut(3) : 300.00 MHz idelay control clock
   -- clkOut(4) :  50.00 MHz monitoring adc
   U_CoreClockGen : entity surf.ClockManagerUltraScale 
   generic map(
      TPD_G                  => 1 ns,
      TYPE_G                 => "MMCM",  -- or "PLL"
      INPUT_BUFG_G           => true,
      FB_BUFG_G              => true,
      RST_IN_POLARITY_G      => '1',     -- '0' for active low
      NUM_CLOCKS_G           => 3,
      -- MMCM attributes
      BANDWIDTH_G            => "OPTIMIZED",
      CLKIN_PERIOD_G         => 6.4,    -- Input period in ns );
      DIVCLK_DIVIDE_G        => 10,
      CLKFBOUT_MULT_F_G      => 38.4,
      CLKFBOUT_MULT_G        => 5,
      CLKOUT0_DIVIDE_F_G     => 1.0,
      CLKOUT0_DIVIDE_G       => 6,
      CLKOUT1_DIVIDE_G       => 2,
      CLKOUT2_DIVIDE_G       => 12,
      CLKOUT0_PHASE_G        => 0.0,
      CLKOUT1_PHASE_G        => 0.0,
      CLKOUT2_PHASE_G        => 0.0,
      CLKOUT0_DUTY_CYCLE_G   => 0.5,
      CLKOUT1_DUTY_CYCLE_G   => 0.5,
      CLKOUT2_DUTY_CYCLE_G   => 0.5,
      CLKOUT0_RST_HOLD_G     => 3,
      CLKOUT1_RST_HOLD_G     => 3,
      CLKOUT2_RST_HOLD_G     => 3,
      CLKOUT0_RST_POLARITY_G => '1',
      CLKOUT1_RST_POLARITY_G => '1',
      CLKOUT2_RST_POLARITY_G => '1')
   port map(
      clkIn           => sysClk,
      rstIn           => sysRst,
      clkOut(0)       => appClk,
      clkOut(1)       => idelayCtrlClk, 
      clkOut(2)       => adcClk, 
      rstOut(0)       => appRst,
      rstOut(1)       => dummy(0),
      rstOut(2)       => dummy(1),
      locked          => clkLocked,
      -- AXI-Lite Interface 
      axilClk         => appClk,
      axilRst         => appRst,
      axilReadMaster  => mAxiReadMasters(PLLREGS_AXI_INDEX_C),
      axilReadSlave   => mAxiReadSlaves(PLLREGS_AXI_INDEX_C),
      axilWriteMaster => mAxiWriteMasters(PLLREGS_AXI_INDEX_C),
      axilWriteSlave  => mAxiWriteSlaves(PLLREGS_AXI_INDEX_C)
   );      


   U_RdPwrUpRst : entity surf.PwrUpRst
   generic map (
     SIM_SPEEDUP_G  => SIMULATION_G,
     DURATION_G     => 200000000
   )
   port map (
      clk      => byteClk,
      rstOut   => byteClkRst
   );

   idelayCtrlRst_i <= idelayCtrlRst;    --cmt_locked or
   U_IDELAYCTRL_0 : IDELAYCTRL
   generic map (
      SIM_DEVICE => "ULTRASCALE"  -- Must be set to "ULTRASCALE" 
   )
   port map (
      RDY => idelayRdy,        -- 1-bit output: Ready output
      REFCLK => idelayCtrlClk, -- 1-bit input: Reference clock input
      RST => idelayCtrlRst_i   -- 1-bit input: Active high reset input. Asynchronous assert, synchronous deassert to
                               -- REFCLK.
   );

  ----------------------------------------------------------------------------
  -- adc clock for cryo
  -----------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------
  -- Create Clocks
  -------------------------------------------------------------------------------------------------

   ------------------------------------------
   -- Generate clocks from 156.25 MHz PGP  --
   ------------------------------------------
   -- clkIn     : 156.25 MHz PGP
   -- clkOut(0) : 448.00 MHz -- 8x cryo clock (default  56MHz)
   -- clkOut(1) : 112.00 MHz -- 448 clock div 4
   -- clkOut(2) : 64.00 MHz  -- 448 clock div 7
   -- clkOut(3) : 56.00 MHz  -- cryo input clock default is 56MHz
   -- 51.250 =>base clock of 1000MHz or 2.2MSPS (62.5MHz)
   -- 45.875 =>base clock of 896MHz or 2MSPS
   -- 41.000 =>base clock of 800MHz or 1.79MSPS
   -- 37.625 =>base clock of 734MHz or 1.63MSPS
     U_iserdesClockGen : entity surf.ClockManagerUltraScale 
   generic map(
      TPD_G                  => 1 ns,
      TYPE_G                 => "MMCM",  -- or "PLL"
      INPUT_BUFG_G           => true,
      FB_BUFG_G              => true,
      RST_IN_POLARITY_G      => '1',     -- '0' for active low
      NUM_CLOCKS_G           => 4,
      -- MMCM attributes
      BANDWIDTH_G            => "OPTIMIZED",
      CLKIN_PERIOD_G         => 6.4,    -- Input period in ns );
      DIVCLK_DIVIDE_G        => 8,
      CLKFBOUT_MULT_F_G      => CRYO_BASECLK_MULT_C,
      CLKFBOUT_MULT_G        => 5,
      CLKOUT0_DIVIDE_F_G     => 1.0,
      CLKOUT0_DIVIDE_G       => 2,
      CLKOUT0_PHASE_G        => 0.0,
      CLKOUT0_DUTY_CYCLE_G   => 0.5,
      CLKOUT0_RST_HOLD_G     => 3,
      CLKOUT0_RST_POLARITY_G => '1',
      CLKOUT1_DIVIDE_G       => 8,
      CLKOUT1_PHASE_G        => 0.0,
      CLKOUT1_DUTY_CYCLE_G   => 0.5,
      CLKOUT1_RST_HOLD_G     => 3,
      CLKOUT1_RST_POLARITY_G => '1',
      CLKOUT2_DIVIDE_G       => 14,
      CLKOUT2_PHASE_G        => 0.0,
      CLKOUT2_DUTY_CYCLE_G   => 0.5,
      CLKOUT2_RST_HOLD_G     => 3,
      CLKOUT2_RST_POLARITY_G => '1',
      CLKOUT3_DIVIDE_G       => 16,
      CLKOUT3_PHASE_G        => 0.0,
      CLKOUT3_DUTY_CYCLE_G   => 0.5,
      CLKOUT3_RST_HOLD_G     => 3,
      CLKOUT3_RST_POLARITY_G => '1')
   port map(
      clkIn           => sysClk,
      rstIn           => sysRst,
      clkOut(0)       => bitClk,       --bit clk
      clkOut(1)       => deserClk,
      clkOut(2)       => byteClk,
      clkOut(3)       => asicRdClk,
      rstOut(0)       => bitRst,
      rstOut(1)       => dummy(2),
      rstOut(2)       => dummy(3),
      rstOut(3)       => asicRdClkRst,
      locked          => open,
      -- AXI-Lite Interface
      axilClk         => appClk,
      axilRst         => appRst,
      axilReadMaster  => mAxiReadMasters(PLL2REGS_AXI_INDEX_C),
      axilReadSlave   => mAxiReadSlaves(PLL2REGS_AXI_INDEX_C),
      axilWriteMaster => mAxiWriteMasters(PLL2REGS_AXI_INDEX_C),
      axilWriteSlave  => mAxiWriteSlaves(PLL2REGS_AXI_INDEX_C)
      );

     ------------------------------------------
   -- Generate clocks from 156.25 MHz PGP  --
   ------------------------------------------
   -- clkIn     : 448.00 MHz PGP
   -- clkOut(0) : 112.00 MHz -- 448 clock div 4
   -- clkOut(1) : 64.00 MHz  -- 448 clock div 7


   U_iserdesClockGenB : entity surf.ClockManagerUltraScale 
   generic map(
      TPD_G                  => 1 ns,
      TYPE_G                 => "MMCM",  -- or "PLL"
      INPUT_BUFG_G           => true,
      FB_BUFG_G              => true,
      RST_IN_POLARITY_G      => '1',     -- '0' for active low
      NUM_CLOCKS_G           => 2,
      -- MMCM attributes
      BANDWIDTH_G            => "OPTIMIZED",
      CLKIN_PERIOD_G         => 2.23,    -- Input period in ns );
      DIVCLK_DIVIDE_G        => 1,
      CLKFBOUT_MULT_F_G      => 1.0,
      CLKFBOUT_MULT_G        => 2,
      CLKOUT0_DIVIDE_G       => 8,
      CLKOUT0_PHASE_G        => 0.0,
      CLKOUT0_DUTY_CYCLE_G   => 0.5,
      CLKOUT0_RST_HOLD_G     => 3,
      CLKOUT0_RST_POLARITY_G => '1',
      CLKOUT1_DIVIDE_G       => 14,
      CLKOUT1_PHASE_G        => 0.0,
      CLKOUT1_DUTY_CYCLE_G   => 0.5,
      CLKOUT1_RST_HOLD_G     => 3,
      CLKOUT1_RST_POLARITY_G => '1')
   port map(
      clkIn           => bitClkB,
      rstIn           => sysRst,
      clkOut(0)       => deserClkB,
      clkOut(1)       => byteClkB,
      rstOut(0)       => dummy(4),
      rstOut(1)       => dummy(5),
      locked          => open
      );

   IBUFDS_serclk : IBUFDS
    generic map (
      DQS_BIAS => "FALSE" -- (FALSE, TRUE)
      )
    port map (
      O => bitClkB,
      I => adcSerial(0).dClkP, 
      IB => adcSerial(0).dClkN 
      );
   
   ---------------------------------------------
   -- AXI Lite Async - cross clock domain     --
   ---------------------------------------------
   U_AxiLiteAsync : entity surf.AxiLiteAsync 
   generic map(
      TPD_G            => 1 ns,
      AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C,
      COMMON_CLK_G     => false,
      NUM_ADDR_BITS_G  => 32,
      PIPE_STAGES_G    => 0)
   port map(
      -- Slave Port
      sAxiClk         => sysClk,
      sAxiClkRst      => sysRst,
      sAxiReadMaster  => sAxilReadMaster,
      sAxiReadSlave   => sAxilReadSlave,
      sAxiWriteMaster => sAxilWriteMaster,
      sAxiWriteSlave  => sAxilWriteSlave,
      -- Master Port
      mAxiClk         => appClk,
      mAxiClkRst      => appRst,
      mAxiReadMaster  => sAxiReadMaster(0),
      mAxiReadSlave   => sAxiReadSlave(0),
      mAxiWriteMaster => sAxiWriteMaster(0),
      mAxiWriteSlave  => sAxiWriteSlave(0)
    );


   ---------------------------------------------
   -- AXI Lite Crossbar for register control  --
   -- Check AppPkg.vhd for addresses          --
   ---------------------------------------------
   U_AxiLiteCrossbar : entity surf.AxiLiteCrossbar
   generic map (
      NUM_SLAVE_SLOTS_G  => HR_FD_NUM_AXI_SLAVE_SLOTS_C,
      NUM_MASTER_SLOTS_G => HR_FD_NUM_AXI_MASTER_SLOTS_C, 
      MASTERS_CONFIG_G   => HR_FD_AXI_CROSSBAR_MASTERS_CONFIG_C
   )
   port map (                
      sAxiWriteMasters    => sAxiWriteMaster,
      sAxiWriteSlaves     => sAxiWriteSlave,
      sAxiReadMasters     => sAxiReadMaster,
      sAxiReadSlaves      => sAxiReadSlave,
      mAxiWriteMasters    => mAxiWriteMasters,
      mAxiWriteSlaves     => mAxiWriteSlaves,
      mAxiReadMasters     => mAxiReadMasters,
      mAxiReadSlaves      => mAxiReadSlaves,
      axiClk              => appClk,
      axiClkRst           => appRst
   );

  -----------------------------------------------------------------------------
  -- Regiester control
  -----------------------------------------------------------------------------
  U_RegControl : entity work.RegisterControl
   generic map (
      TPD_G            => TPD_G,
      EN_DEVICE_DNA_G  => false,        -- this is causing placement errors,
                                        -- needs fixing.
      BUILD_INFO_G     => BUILD_INFO_G
   )
   port map (
      axiClk         => appClk,
      axiRst         => axiRst,
      sysRst         => appRst,
      -- AXI-Lite Register Interface (axiClk domain)
      axiReadMaster  => mAxiReadMasters(APP_REG_AXI_INDEX_C),
      axiReadSlave   => mAxiReadSlaves(APP_REG_AXI_INDEX_C),
      axiWriteMaster => mAxiWriteMasters(APP_REG_AXI_INDEX_C),
      axiWriteSlave  => mAxiWriteSlaves(APP_REG_AXI_INDEX_C),
      -- Register Inputs/Outputs (axiClk domain)
      boardConfig    => boardConfig,
      -- 1-wire board ID interfaces
      serialIdIo     => serialIdIo,
      -- fast ADC clock
      adcClk         => open,
      -- ASICs acquisition signals
      acqStart       => acqStart,
      saciReadoutReq => saciPrepReadoutReq,
      saciReadoutAck => saciPrepReadoutAck,
      asicPPbe       => iAsicPpbe,
      asicPpmat      => iAsicPpmat,
      asicTpulse     => open,
      asicStart      => open,
      asicSR0        => iAsicSR0Raw,
      asicGlblRst    => iAsicGrst,
      asicSync       => iAsicSync,
      asicAcq        => iAsicAcq,
      asicVid        => open,
      errInhibit     => errInhibit
   );

  U_SR0Synch : entity work.SR0Synchronizer
    generic map (
      TPD_G => TPD_G
      ) 
    port map( 
      -- Master system clock
      sysClk       => bitClk,
      sysClkRst    => bitRst,
      -- DAC Data
      delay        => boardConfig.SR0Delay,
      period       => boardConfig.SR0Period,
      SR0          => iAsicSR0Raw,
      -- DAC Control Signals
      refClk       => iAsicSR0RefClk,
      SR0Out       => iAsicSR0
   );

   -- synchronizers
   U_Sync_WFDac20bitLdacL : entity surf.Synchronizer     
   port map (
      clk     => asicRdClk,
      rst     => asicRdClkRst,
      dataIn  => WFDac20bitLdacL_i,
      dataOut => WFDac20bitLdacLSync
   );

   ---------------------
   -- Trig control    --
   --------------------- 
   U_TrigControl : entity work.TrigControlAxi
   port map (
      -- Trigger outputs
      appClk         => appClk,
      appRst         => appRst,
      acqStart       => acqStart,
      dataSend       => dataSend,
      
      -- External trigger inputs
      runTrigger     => iRunTrigger,
      daqTrigger     => iDaqTrigger,
      
      -- PGP clocks and reset
      sysClk         => sysClk,
      sysRst         => sysRst,
      -- SW trigger in (from VC)
      ssiCmd         => ssiCmd,
      -- PGP RxOutType (to trigger from sideband)
      pgpRxOut       => pgpRxOut,
      -- Opcode associated with this trigger
      opCodeOut      => opCode,
      
      -- AXI lite slave port for register access
      axilClk           => appClk,
      axilRst           => appRst,
      sAxilWriteMaster  => mAxiWriteMasters(TRIG_REG_AXI_INDEX_C),
      sAxilWriteSlave   => mAxiWriteSlaves(TRIG_REG_AXI_INDEX_C),
      sAxilReadMaster   => mAxiReadMasters(TRIG_REG_AXI_INDEX_C),
      sAxilReadSlave    => mAxiReadSlaves(TRIG_REG_AXI_INDEX_C)
   );

   --------------------------------------------
   -- SACI interface controller              --
   -------------------------------------------- 
   U_AxiLiteSaciMaster : entity surf.AxiLiteSaciMaster
   generic map (
      AXIL_CLK_PERIOD_G  => 10.0E-9, -- In units of seconds
      AXIL_TIMEOUT_G     => 1.0E-3,  -- In units of seconds
      SACI_CLK_PERIOD_G  => SACI_CLK_PERIOD_C, -- In units of seconds
      SACI_CLK_FREERUN_G => false,
      SACI_RSP_BUSSED_G  => true,
      SACI_NUM_CHIPS_G   => NUMBER_OF_ASICS_C)
   port map (
      -- SACI interface
      saciClk           => iSaciClk,
      saciCmd           => iSaciCmd,
      saciSelL          => iSaciSelL(0 downto 0),
      saciRsp(0)        => asicSaciRsp,
      -- AXI-Lite Register Interface
      axilClk           => appClk,
      axilRst           => appRst,
      axilReadMaster    => mAxiReadMasters(SACIREGS_AXI_INDEX_C),
      axilReadSlave     => mAxiReadSlaves(SACIREGS_AXI_INDEX_C),
      axilWriteMaster   => mAxiWriteMasters(SACIREGS_AXI_INDEX_C),
      axilWriteSlave    => mAxiWriteSlaves(SACIREGS_AXI_INDEX_C)
   );

   --------------------------------------------
   -- Virtual oscilloscope                   --
   --------------------------------------------
   U_PseudoScope : entity work.PseudoScopeAxi
   generic map (
     TPD_G                      => TPD_G,
     MASTER_AXI_STREAM_CONFIG_G => ssiAxiStreamConfig(4, TKEEP_COMP_C)      
   )
   port map ( 
      
      sysClk         => sysClk,
      sysClkRst      => sysRst,
      adcData        => adcData,
      adcValid       => adcValid,
      arm            => acqStart,
      triggerIn(0)   => acqStart,
      triggerIn(1)   => iAsicAcq,
      triggerIn(2)   => iAsicSR0,
      triggerIn(3)   => iAsicPpmat,
      triggerIn(4)   => iAsicPpbe,
      triggerIn(5)   => iAsicSync,
      triggerIn(6)   => iAsicGrst,
      triggerIn(7)   => asicRdClk,
      triggerIn(11 downto 8)  => iSaciSelL,
      mAxisMaster    => sAuxAxisMasters(0),
      mAxisSlave     => sAuxAxisSlaves(0),
      -- AXI lite slave port for register access
      axilClk           => appClk,
      axilRst           => appRst,
      sAxilWriteMaster  => mAxiWriteMasters(SCOPE_REG_AXI_INDEX_C),
      sAxilWriteSlave   => mAxiWriteSlaves(SCOPE_REG_AXI_INDEX_C),
      sAxilReadMaster   => mAxiReadMasters(SCOPE_REG_AXI_INDEX_C),
      sAxilReadSlave    => mAxiReadSlaves(SCOPE_REG_AXI_INDEX_C)

   );

   --------------------------------------------
   -- Fast ADC for Virtual oscilloscope      --
   --------------------------------------------
   -- ADC Clock outputs
   U_AdcClk2 : OBUFDS port map ( I => adcClk, O => adcClkP, OB => adcClkM );
   
   GenAdcStr : for i in 0 to 3 generate 
      adcData(i)  <= adcStreams(i).tData(15 downto 0);
      adcValid(i) <= adcStreams(i).tValid;
   end generate;

   monAdc.fClkP <= adcFrameClkP;
   monAdc.fClkN <= adcFrameClkM;
   monAdc.dClkP <= adcDoClkP;
   monAdc.dClkN <= adcDoClkM;
   monAdc.chP(3 downto 0)   <= adcMonDoutP(3 downto 0);
   monAdc.chN(3 downto 0)   <= adcMonDoutN(3 downto 0);
      
   U_MonAdcReadout : entity surf.Ad9249ReadoutGroup
   generic map (
      TPD_G             => TPD_G,
      NUM_CHANNELS_G    => 4,
      IODELAY_GROUP_G   => IODELAY_GROUP_G,
      IDELAYCTRL_FREQ_G => 200.0,
      DEFAULT_DELAY_G   => (others => '0'),
      ADC_INVERT_CH_G   => "00000010"
   )
   port map (
      -- Master system clock, 100Mhz
      axilClk           => appClk,
      axilRst           => appRst,
      
      -- Axi Interface
      axilReadMaster    => mAxiReadMasters(ADC_RD_AXI_INDEX_C),
      axilReadSlave     => mAxiReadSlaves(ADC_RD_AXI_INDEX_C),
      axilWriteMaster   => mAxiWriteMasters(ADC_RD_AXI_INDEX_C),
      axilWriteSlave    => mAxiWriteSlaves(ADC_RD_AXI_INDEX_C),

      -- Reset for adc deserializer
      adcClkRst         => serdesReset,

      -- Serial Data from ADC
      adcSerial         => monAdc,

      -- Deserialized ADC Data
      adcStreamClk      => sysClk,
      adcStreams        => adcStreams
   );

   -- Give a special reset to the SERDES blocks when power
   -- is turned on to ADC card.
   adcCardPowerUp <= anaPwrEn_i and digPwrEn_i;
   U_AdcCardPowerUpRisingEdge : entity surf.SynchronizerEdge
   generic map (
      TPD_G       => TPD_G)
   port map (
      clk         => appClk,
      dataIn      => adcCardPowerUp,
      risingEdge  => adcCardPowerUpEdge
   );
   U_AdcCardPowerUpReset : entity surf.RstSync
   generic map (
      TPD_G           => TPD_G,
      RELEASE_DELAY_G => 50
   )
   port map (
      clk      => appClk,
      asyncRst => adcCardPowerUpEdge,
      syncRst  => serdesReset
   );

   U_IdelayCtrlReset : entity surf.RstSync
   generic map (
      TPD_G           => TPD_G,
      RELEASE_DELAY_G => 250
   )
   port map (
      clk      => idelayCtrlClk,
      asyncRst => serdesReset,
      syncRst  => idelayCtrlRst
   );
   
   --------------------------------------------
   --     Fast ADC Config                    --
   --------------------------------------------
   U_AdcConf : entity surf.Ad9249Config
   generic map (
      TPD_G             => TPD_G,
      AXIL_CLK_PERIOD_G => 10.0e-9,
      NUM_CHIPS_G       => 1
   )
   port map (
      axilClk           => appClk,
      axilRst           => appRst,
      
      axilReadMaster    => mAxiReadMasters(ADC_CFG_AXI_INDEX_C),
      axilReadSlave     => mAxiReadSlaves(ADC_CFG_AXI_INDEX_C),
      axilWriteMaster   => mAxiWriteMasters(ADC_CFG_AXI_INDEX_C),
      axilWriteSlave    => mAxiWriteSlaves(ADC_CFG_AXI_INDEX_C),

      adcPdwn           => adcPdwn_i,
      adcSclk           => adcSpiClk,
      adcSdio           => adcSpiData,
      adcCsb            => adcSpiCsL_i

      );
   
   --------------------------------------------
   --  Slow ADC Readout  (env. variables)    --
   -------------------------------------------- 
   U_AdcCntrl: entity work.SlowAdcCntrlAxi
   generic map (
      SYS_CLK_PERIOD_G  => 6.4E-9,	-- 100MHz
      ADC_CLK_PERIOD_G  => 200.0E-9,	-- 5MHz
      SPI_SCLK_PERIOD_G => 2.0E-6  	-- 500kHz
   )
   port map ( 
      -- Master system clock
      sysClk            => sysClk,
      sysClkRst         => sysRst,
      
      -- Trigger Control
      adcStart          => acqStart,
      
      -- AXI lite slave port for register access
      axilClk           => appClk,
      axilRst           => appRst,
      sAxilWriteMaster  => mAxiWriteMasters(MONADC_REG_AXI_INDEX_C),
      sAxilWriteSlave   => mAxiWriteSlaves(MONADC_REG_AXI_INDEX_C),
      sAxilReadMaster   => mAxiReadMasters(MONADC_REG_AXI_INDEX_C),
      sAxilReadSlave    => mAxiReadSlaves(MONADC_REG_AXI_INDEX_C),
      
      -- AXI stream output
      axisClk           => sysClk,
      axisRst           => sysRst,
      mAxisMaster       => sAuxAxisMasters(1),
      mAxisSlave        => sAuxAxisSlaves(1),

      -- ADC Control Signals
      adcRefClk         => slowAdcRefClk,
      adcDrdy           => slowAdcDrdy,
      adcSclk           => slowAdcSclk,
      adcDout           => slowAdcDout,
      adcCsL            => slowAdcCsL,
      adcDin            => slowAdcDin
   );
   

   ----------------------------------------------------------------------------
   -- Power control module instance
   ----------------------------------------------------------------------------
   U_PowerControlModule : entity work.PowerControlModule 
      generic map (
      TPD_G              => TPD_G
   )
   port map (
      -- Trigger outputs
      sysClk         => appClk,
      sysRst         => appRst,
      -- power control
      digPwrEn         => digPwrEn,
      anaPwrEn         => anaPwrEn,
      syncDigDcDc      => syncDigDcDc,
      syncAnaDcDc      => syncAnaDcDc,
      syncDcDc         => syncDcDc,
      
      -- AXI lite slave port for register access
      axilClk         => appClk,  
      axilRst         => appRst,   
      sAxilWriteMaster=> mAxiWriteMasters(POWER_MODULE_INDEX_C),
      sAxilWriteSlave => mAxiWriteSlaves(POWER_MODULE_INDEX_C),
      sAxilReadMaster => mAxiReadMasters(POWER_MODULE_INDEX_C),
      sAxilReadSlave  => mAxiReadSlaves(POWER_MODULE_INDEX_C)
   );


  --------------------------------------------
  -- High speed DAC (DAC8812)               --
  --------------------------------------------
  U_INTDAC : if (INTERNAL_DAC_C) generate 
    U_HSDAC: entity work.DacWaveformGenAxi
      generic map (
        TPD_G => TPD_G,
        NUM_SLAVE_SLOTS_G  => HR_FD_NUM_AXI_SLAVE_SLOTS_C,
        NUM_MASTER_SLOTS_G => HR_FD_NUM_AXI_MASTER_SLOTS_C,
        MASTERS_CONFIG_G   => ssiAxiStreamConfig(4, TKEEP_COMP_C)
        )
      port map (
        sysClk            => appClk,
        sysClkRst         => appRst,
        dacDin            => WFDacDin_i,
        dacSclk           => WFDacSclk_i,
        dacCsL            => WFDacCsL_i,
        dacLdacL          => WFDacLdacL_i,
        dacClrL           => WFDacClrL_i,
        externalTrigger   => acqStart,
        axilClk           => appClk,
        axilRst           => appRst,
        sAxilWriteMaster  => mAxiWriteMasters(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C),
        sAxilWriteSlave   => mAxiWriteSlaves(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C),
        sAxilReadMaster   => mAxiReadMasters(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C),
        sAxilReadSlave    => mAxiReadSlaves(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C));

        WFDac20bitDin_i   <= '0';
        WFDac20bitSclk_i  <= '0';
        WFDac20bitSyncL_i <= '0';
        WFDac20bitLdacL_i <= '0';
        WFDac20bitClrL_i  <= '0';
  end generate;

  U_EXTDAC : if (not INTERNAL_DAC_C) generate 
    U_HSDAC: entity work.Dac20bitWaveformGenAxi
      generic map (
        TPD_G => TPD_G,
        NUM_SLAVE_SLOTS_G  => HR_FD_NUM_AXI_SLAVE_SLOTS_C,
        NUM_MASTER_SLOTS_G => HR_FD_NUM_AXI_MASTER_SLOTS_C,
        MASTERS_CONFIG_G   => ssiAxiStreamConfig(4, TKEEP_COMP_C)
        )
      port map (
        sysClk            => appClk,
        sysClkRst         => appRst,
        dacDin            => WFDac20bitDin_i,
        dacSclk           => WFDac20bitSclk_i,
        dacSyncL          => WFDac20bitSyncL_i,
        dacLdacL          => WFDac20bitLdacL_i,
        dacClrL           => WFDac20bitClrL_i,
        externalTrigger   => acqStart,
        axilClk           => appClk,
        axilRst           => appRst,
        sAxilWriteMaster  => mAxiWriteMasters(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C),
        sAxilWriteSlave   => mAxiWriteSlaves(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C),
        sAxilReadMaster   => mAxiReadMasters(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C),
        sAxilReadSlave    => mAxiReadSlaves(DACWFMEM_REG_AXI_INDEX_C downto DAC8812_REG_AXI_INDEX_C));

        WFDacDin_i   <= '0';
        WFDacSclk_i  <= '0';
        WFDacCsL_i   <= '0';
        WFDacLdacL_i <= '0';
        WFDacClrL_i  <= '0';
  end generate;

  --------------------------------------------
  -- ePix HR analog board SPI DACs          --
  --------------------------------------------
  U_DACs : entity work.slowDacs 
   generic map (
      TPD_G             => TPD_G,
      CLK_PERIOD_G      => 10.0E-9
   )
   port map (
      -- Global Signals
      axiClk => appClk,
      axiRst => appRst,
      -- AXI-Lite Register Interface (axiClk domain)
      axiReadMaster  => mAxiReadMasters(DAC_MODULE_INDEX_C), 
      axiReadSlave   => mAxiReadSlaves(DAC_MODULE_INDEX_C),
      axiWriteMaster => mAxiWriteMasters(DAC_MODULE_INDEX_C),
      axiWriteSlave  => mAxiWriteSlaves(DAC_MODULE_INDEX_C),
      -- Guard ring DAC interfaces
      dacSclk        => sDacSclk_i,
      dacDin         => sDacDin_i,      
      dacCsb         => sDacCsL_i,
      dacClrb        => sDacClrb_i
   );


   --------------------------------------------
   --     PRBS LOOP                          --
   --------------------------------------------   
   G_PRBS : for i in 0 to NUMBER_OF_LANES_C-1 generate 
      -------------------------------------------------------
      -- ASIC AXI stream framers
      -------------------------------------------------------
      U_AXI_PRBS : entity surf.SsiPrbsTx 
      generic map(         
         TPD_G                      => TPD_G,
         MASTER_AXI_PIPE_STAGES_G   => 1,
         PRBS_SEED_SIZE_G           => 128,
         MASTER_AXI_STREAM_CONFIG_G => COMM_AXIS_CONFIG_C)
      port map(
         -- Master Port (mAxisClk)
         mAxisClk        => sysClk,
         mAxisRst        => sysRst,
         mAxisMaster     => mAxisMastersPRBS(i),
         mAxisSlave      => mAxisSlavesPRBS(i),
         -- Trigger Signal (locClk domain)
         locClk          => appClk,
         locRst          => appRst,
         trig            => acqStart,
         packetLength    => X"FFFFFFFF",
         forceEofe       => '0',
         busy            => prbsBusy(i),
         tDest           => X"00",
         tId             => X"00",
         -- Optional: Axi-Lite Register Interface (locClk domain)
         axilReadMaster  => mAxiReadMasters(PRBS0_AXI_INDEX_C+i),
         axilReadSlave   => mAxiReadSlaves(PRBS0_AXI_INDEX_C+i),
         axilWriteMaster => mAxiWriteMasters(PRBS0_AXI_INDEX_C+i),
         axilWriteSlave  => mAxiWriteSlaves(PRBS0_AXI_INDEX_C+i));
      
      U_STREAM_MUX : entity surf.AxiStreamMux 
        generic map(
          TPD_G                => TPD_G,
          NUM_SLAVES_G         => 2,
          PIPE_STAGES_G        => 0,
          TDEST_LOW_G          => 0,      -- LSB of updated tdest for INDEX
          ILEAVE_EN_G          => false,  -- Set to true if interleaving dests, arbitrate on gaps
          ILEAVE_ON_NOTVALID_G => false,  -- Rearbitrate when tValid drops on selected channel
          ILEAVE_REARB_G       => 0)  -- Max number of transactions between arbitrations, 0 = unlimited
        port map(
          -- Clock and reset
          axisClk      => sysClk,
          axisRst      => sysRst,
          -- Slaves
          sAxisMasters(0) => mAxisMastersPRBS(i),
          sAxisMasters(1) => mAxisMastersASIC(i),
          sAxisSlaves(0)  => mAxisSlavesPRBS(i),          
          sAxisSlaves(1)  => mAxisSlavesASIC(i),
          -- Master
          mAxisMaster  => imAxisMasters(i),
          mAxisSlave   => mAxisSlaves(i));
   end generate;


   adcSerial(0).fClkP  <= asicDataP(2);
   adcSerial(0).fClkN  <= asicDataN(2);
   adcSerial(0).dClkP  <= asicDataP(1);
   adcSerial(0).dClkN  <= asicDataN(1);
   adcSerial(0).chP(0) <= asicDataP(0);
   adcSerial(0).chN(0) <= asicDataN(0);
   adcSerial(0).chP(1) <= asicDataP(3);
   adcSerial(0).chN(1) <= asicDataN(3);
   --
   --adcSerial(1).fClkP  <= asicDataP(4);
   --adcSerial(1).fClkN  <= asicDataN(4);
   --adcSerial(1).dClkP  <= asicDataP(6);
   --adcSerial(1).dClkN  <= asicDataN(6);
   --adcSerial(1).chP(0) <= asicDataP(3);
   --adcSerial(1).chN(0) <= asicDataN(3);
   
   --------------------------------------------
   --     ASICS LOOP                         --
   --------------------------------------------   
   G_ASICS : for i in 0 to NUMBER_OF_ASICS_C-1 generate 
     -------------------------------------------------------
     -- ASIC AXI stream framers
     -------------------------------------------------------
     U_AXI_ASIC : entity work.HrAdcReadoutGroup
      generic map (
        TPD_G             => TPD_G,
        NUM_CHANNELS_G    => STREAMS_PER_ASIC_C,
        SIMULATION_G      => SIMULATION_G,
        IODELAY_GROUP_G   => "DEFAULT_GROUP",
        XIL_DEVICE_G      => "ULTRASCALE",
        DEFAULT_DELAY_G   => (others => '0'),
        ADC_INVERT_CH_G   => "00000000")
      port map (
        -- Master system clock, 125Mhz
        axilClk         => appClk,
        axilRst         => appRst,          
        axilWriteMaster => mAxiWriteMasters(CRYO_ASIC0_READOUT_AXI_INDEX_C+i),
        axilWriteSlave  => mAxiWriteSlaves(CRYO_ASIC0_READOUT_AXI_INDEX_C+i),
        axilReadMaster  => mAxiReadMasters(CRYO_ASIC0_READOUT_AXI_INDEX_C+i),
        axilReadSlave   => mAxiReadSlaves(CRYO_ASIC0_READOUT_AXI_INDEX_C+i),
        bitClk          => bitClk,  -- bitClkB,--change to clock if using serClk from ASIC to decode data
        byteClk         => byteClk, -- byteClkB,--change to clock if using serClk from ASIC to decode data
        deserClk        => deserClk,-- deserClkB,--change to clock if using serClk from ASIC to decode data
        adcClkRst       => sysRst,
        adcSerial       => adcSerial(i),
        adcStreamClk    => byteClk,--fClkP,--sysClk,
        adcStreams      => asicStreams,
        adcStreamsEn_n  => adcStreamsEn_n,
        monitoringSig   => monitoringSig
        );

     -------------------------------------------------------------------------------
     -- generate stream frames
     -------------------------------------------------------------------------------
     U_Framers : entity work.DigitalAsicStreamAxi 
       generic map(
         TPD_G               => TPD_G,
         VC_NO_G             => "0000",
         LANE_NO_G           => toSlv(i, 4),
         ASIC_NO_G           => toSlv(i, 3),
         STREAMS_PER_ASIC_G  => STREAMS_PER_ASIC_C,
         ASIC_DATA_G         => (64*16),
         ASIC_WIDTH_G        => 64,
         AXIL_ERR_RESP_G     => AXI_RESP_DECERR_C
         )
       port map( 
         -- Deserialized data port
         rxClk             => byteClk, --asicRdClk, --fClkP,    --use frame clock
         rxRst             => byteClkRst,--asicRdClkRst,
         adcStreams        => asicStreams(STREAMS_PER_ASIC_C-1 downto 0),
         adcStreamsEn_n    => adcStreamsEn_n,
      
         -- AXI lite slave port for register access
         axilClk           => appClk,
         axilRst           => appRst,
         sAxilWriteMaster  => mAxiWriteMasters(DIG_ASIC0_STREAM_AXI_INDEX_C+i),
         sAxilWriteSlave   => mAxiWriteSlaves(DIG_ASIC0_STREAM_AXI_INDEX_C+i),
         sAxilReadMaster   => mAxiReadMasters(DIG_ASIC0_STREAM_AXI_INDEX_C+i),
         sAxilReadSlave    => mAxiReadSlaves(DIG_ASIC0_STREAM_AXI_INDEX_C+i),
      
         -- AXI data stream output
         axisClk           => sysClk,
         axisRst           => sysRst,
         mAxisMaster       => mAxisMastersASIC(i),
         mAxisSlave        => mAxisSlavesASIC(i),
      
         -- acquisition number input to the header
         acqNo             => boardConfig.acqCnt,
      
         -- optional readout trigger for test mode
         testTrig          => acqStart,
         errInhibit        => errInhibit
         );       
   end generate;


   -------------------------------------------------------
   -- AXI stream monitoring                             --
   -------------------------------------------------------
   U_AxiSMonitor : entity surf.AxiStreamMonAxiL 
   generic map(
      TPD_G           => 1 ns,
      COMMON_CLK_G    => false,  -- true if axisClk = statusClk
      AXIS_CLK_FREQ_G => 156.25E+6,  -- units of Hz
      AXIS_NUM_SLOTS_G=> 4,
      AXIS_CONFIG_G   => COMM_AXIS_CONFIG_C)
   port map(
      -- AXIS Stream Interface
      axisClk         => sysClk,
      axisRst         => sysRst,
      axisMasters     => imAxisMasters,
      axisSlaves      => mAxisSlaves,
      -- AXI lite slave port for register access
      axilClk         => appClk,  
      axilRst         => appRst,   
      sAxilWriteMaster=> mAxiWriteMasters(AXI_STREAM_MON_INDEX_C),
      sAxilWriteSlave => mAxiWriteSlaves(AXI_STREAM_MON_INDEX_C),
      sAxilReadMaster => mAxiReadMasters(AXI_STREAM_MON_INDEX_C),
      sAxilReadSlave  => mAxiReadSlaves(AXI_STREAM_MON_INDEX_C)
   );


   --------------------------------------------
   -- DDR memory tester                      --
   --------------------------------------------
   -- in order to desable the mem tester, the followint two signasl need to be wired
   --   mAxiReadMaster  <= AXI_READ_MASTER_INIT_C;
   --   mAxiWriteMaster <= AXI_WRITE_MASTER_INIT_C;
  DDR_NOT_GEN : if (not DDR_GEN_G) generate
     -- in order to desable the mem tester, the followint two signasl need to be wired
     mAxiReadMaster  <= AXI_READ_MASTER_INIT_C;
     mAxiWriteMaster <= AXI_WRITE_MASTER_INIT_C;
     -- init unused axiLite
     mAxiWriteSlaves(DDR_MEM_INDEX_C) <= axiLiteWriteSlaveEmptyInit(AXI_RESP_OK_C);
     mAxiReadSlaves(DDR_MEM_INDEX_C)  <= axiLiteReadSlaveEmptyInit(AXI_RESP_OK_C);
   end generate;

   DDR_GEN : if (DDR_GEN_G) generate
     U_AxiMemTester : entity surf.AxiMemTester
       generic map (
         TPD_G        => TPD_G,
         START_ADDR_G => START_ADDR_C,
         STOP_ADDR_G  => STOP_ADDR_C,
         AXI_CONFIG_G => DDR_AXI_CONFIG_C)
       port map (
         -- AXI-Lite Interface
         axilClk         => appClk,
         axilRst         => appRst,
         axilReadMaster  => mAxiReadMasters(DDR_MEM_INDEX_C),
         axilReadSlave   => mAxiReadSlaves(DDR_MEM_INDEX_C),
         axilWriteMaster => mAxiWriteMasters(DDR_MEM_INDEX_C),
         axilWriteSlave  => mAxiWriteSlaves(DDR_MEM_INDEX_C),
         memReady        => open,  -- status bits
         memError        => open, -- status bits
         -- DDR Memory Interface
         axiClk          => sysClk,
         axiRst          => sysRst,
         start           => startDdrTest, -- input signal that starts the test 
         axiWriteMaster  => mAxiWriteMaster,
         axiWriteSlave   => mAxiWriteSlave,
         axiReadMaster   => mAxiReadMaster,
         axiReadSlave    => mAxiReadSlave
         );

     U_StartDdrTest : entity surf.PwrUpRst
       generic map (
         DURATION_G => 10000000
         )
       port map (
         clk      => appClk,
         rstOut   => startDdrTest_n
         );
   end generate;
   --------------------------------------------
   -- Equalizer monitoring                   --
   --------------------------------------------
   U_EqualizerStatus : entity work.EqualizerModules
     generic map(
      TPD_G               => TPD_G,
      NUN_OF_EQUALIZER_IC => 6)
   port map(
      sysClk            => appClk,
      sysRst            => appRst,
      -- IO signals
      EqualizerLOS      => EqualizerLosIn,
      EqualizerLOSSynced=> open,
      -- AXI lite slave port for register access
      axilClk           => appClk,
      axilRst           => appRst,
      sAxilWriteMaster  => mAxiWriteMasters(EQUALIZER_REG_AXI_INDEX_C),
      sAxilWriteSlave   => mAxiWriteSlaves(EQUALIZER_REG_AXI_INDEX_C),
      sAxilReadMaster   => mAxiReadMasters(EQUALIZER_REG_AXI_INDEX_C),
      sAxilReadSlave    => mAxiReadSlaves(EQUALIZER_REG_AXI_INDEX_C)
   );

   --------------------------------------------
   -- Programmable power supply              --
   --------------------------------------------
   U_ProgPowerSup : entity work.ProgrammablePowerSupply 
     generic map(
       TPD_G         => TPD_G
       )
   port map(
      axiClk         => appClk,
      axiRst         => appRst,
      -- AXI-Lite Register Interface (axiClk domain)    
      axiReadMaster  => mAxiReadMasters(PROG_SUPPLY_REG_AXI_INDEX_C),
      axiReadSlave   => mAxiReadSlaves(PROG_SUPPLY_REG_AXI_INDEX_C),
      axiWriteMaster => mAxiWriteMasters(PROG_SUPPLY_REG_AXI_INDEX_C),
      axiWriteSlave  => mAxiWriteSlaves(PROG_SUPPLY_REG_AXI_INDEX_C),
      -- Static control IO interface
      enableLDO      => enableLDOOut, 
      -- DAC interfaces
      dacSclk        => dacSclkProgSupplyOut,
      dacDin         => dacDinProgSupplyOut,
      dacCsb         => dacCsbProgSupplyOut,
      dacClrb        => dacClrbProgSupplyOut
   );

    PLL_GEN : if (TEST_SYSTEM_C00_G = false) generate
      U_PLL : entity surf.Si5345 
        generic map(
          TPD_G              => TPD_G,
          MEMORY_INIT_FILE_G => "Si5345-RevD-Regmap-56MHz.mem",  -- Used to initialization boot ROM
          CLK_PERIOD_G       => (1.0/100.0E+6),
          SPI_SCLK_PERIOD_G  => (1.0/1.0E+6))
        port map(
          -- Clock and Reset
          axiClk         => appClk,
          axiRst         => appRst,
          -- AXI-Lite Interface
          axiReadMaster  =>  mAxiReadMasters(CLK_JIT_CLR_REG_AXI_INDEX_C),
          axiReadSlave   => mAxiReadSlaves(CLK_JIT_CLR_REG_AXI_INDEX_C),
          axiWriteMaster => mAxiWriteMasters(CLK_JIT_CLR_REG_AXI_INDEX_C),
          axiWriteSlave  => mAxiWriteSlaves(CLK_JIT_CLR_REG_AXI_INDEX_C),
          -- SPI Interface
          coreSclk       => pllSck,
          coreSDin       => pllSdo,
          coreSDout      => pllSdi,
          coreCsb        => pllCsL
          );
      end generate;
  
end mapping;
