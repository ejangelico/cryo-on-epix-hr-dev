#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : cryo DAQ top module (based on ePix HR readout)
#-----------------------------------------------------------------------------
# File       : cryoDAQ.py evolved from evalBoard.py
# Created    : 2018-06-12
# Last update: 2018-06-12
#-----------------------------------------------------------------------------
# Description:
# Rogue interface to cryo ASIC based on ePix HR boards
#-----------------------------------------------------------------------------
# This file is part of the rogue_example software. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the rogue_example software, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import setupLibPaths
import pyrogue as pr
import pyrogue.utilities.prbs
import pyrogue.utilities.fileio
import pyrogue.interfaces.simulation
import pyrogue.gui
import rogue.hardware.pgp
import rogue.protocols
import surf
import surf.axi
import surf.protocols.ssi
from XilinxKcu1500Pgp3.XilinxKcu1500Pgp3 import *

import threading
import signal
import atexit
import yaml
import time
import argparse
import sys
#import testBridge
import ePixViewer as vi
import ePixFpga as fpga


try:
    from PyQt5.QtWidgets import *
    from PyQt5.QtCore    import *
    from PyQt5.QtGui     import *
except ImportError:
    from PyQt4.QtCore    import *
    from PyQt4.QtGui     import *

# Set the argument parser
parser = argparse.ArgumentParser()


# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']


# Add arguments
parser.add_argument(
    "--type", 
    type     = str,
    required = True,
    help     = "define the PCIe card type (either pgp-gen3 or kcu1500)",
)  

parser.add_argument(
    "--start_gui", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "true to show gui",
)  

parser.add_argument(
    "--viewer", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "Start viewer",
)  

parser.add_argument(
    "--verbose", 
    type     = argBool,
    required = False,
    default  = False,
    help     = "true for verbose printout",
)

# Add arguments
parser.add_argument(
    "--initSeq", 
    type     = int,
    required = False,
    default  = 0,
    help     = "specify the inicialization sequence to be performed (0 means no initialization).",
)  

# Get the arguments
args = parser.parse_args()

#############################################
START_VIEWER = args.viewer
print(args.viewer)
#############################################

# Add PGP virtual channels
if ( args.type == 'pgp-gen3' ):
    # Create the PGP interfaces for ePix hr camera
    pgpL0Vc0 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,0) # Data & cmds
    pgpL0Vc1 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,1) # Registers for ePix board
    pgpL0Vc2 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,2) # PseudoScope
    pgpL0Vc3 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,3) # Monitoring (Slow ADC)

    #pgpL1Vc0 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,0) # Data (when using all four lanes it should be swapped back with L0)
    pgpL2Vc0 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',2,0) # Data
    pgpL3Vc0 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',3,0) # Data

    print("")
    print("PGP Card Version: %x" % (pgpL0Vc0.getInfo().version))
    
elif ( args.type == 'kcu1500' ):
    # Create the PGP interfaces for ePix hr camera
    pgpL0Vc0 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',(0*32)+0, True) # Data & cmds
    pgpL0Vc1 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',(0*32)+1, True) # Registers for ePix board
    pgpL0Vc2 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',(0*32)+2, True) # PseudoScope
    pgpL0Vc3 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',(0*32)+3, True) # Monitoring (Slow ADC)

    #pgpL1Vc0 = rogue.hardware.data.DataCard('/dev/datadev_0',(0*32)+0) # Data (when using all four lanes it should be swapped back with L0)
    pgpL2Vc0 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',(2*32)+0, True) # Data
    pgpL3Vc0 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',(3*32)+0, True) # Data
elif ( args.type == 'SIM' ):          
    print('Sim mode')
    rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)
    simPort = 11000
    pgpL0Vc0  = rogue.interfaces.stream.TcpClient('localhost',simPort+(34*0)+2*0) # VC0
    pgpL0Vc1  = rogue.interfaces.stream.TcpClient('localhost',simPort+(34*0)+2*1) # VC1
    pgpL0Vc2  = rogue.interfaces.stream.TcpClient('localhost',simPort+(34*0)+2*2) # VC2
    pgpL0Vc3  = rogue.interfaces.stream.TcpClient('localhost',simPort+(34*0)+2*3) # VC3    
    pgpL2Vc0  = rogue.interfaces.stream.TcpClient('localhost',simPort+(34*2)+2*0) # L2VC0    
    pgpL3Vc0  = rogue.interfaces.stream.TcpClient('localhost',simPort+(34*3)+2*0) # L3VC0

elif ( args.type == 'dataFile' ):
    print("Bypassing hardware.")

else:
    raise ValueError("Invalid type (%s)" % (args.type) )

# Add data stream to file as channel 1 File writer
dataWriter = pyrogue.utilities.fileio.StreamWriter(name='dataWriter')
if ( args.type != 'dataFile' ):
    pyrogue.streamConnect(pgpL0Vc0, dataWriter.getChannel(0x1))
    pyrogue.streamConnect(pgpL0Vc2, dataWriter.getChannel(0x2))
    

cmd = rogue.protocols.srp.Cmd()
if ( args.type != 'dataFile' ):
    pyrogue.streamConnect(cmd, pgpL0Vc0)

# Create and Connect SRP to VC1 to send commands
srp = rogue.protocols.srp.SrpV3()
if ( args.type != 'dataFile' ):
    pyrogue.streamConnectBiDir(pgpL0Vc1,srp)

#############################################
# Microblaze console printout
#############################################
class MbDebug(rogue.interfaces.stream.Slave):

    def __init__(self):
        rogue.interfaces.stream.Slave.__init__(self)
        self.enable = False

    def _acceptFrame(self,frame):
        if self.enable:
            p = bytearray(frame.getPayload())
            frame.read(p,0)
            print('-------- Microblaze Console --------')
            print(p.decode('utf-8'))

#######################################
# Custom run control
#######################################
class MyRunControl(pyrogue.RunControl):
    def __init__(self,name):
        pyrogue.RunControl.__init__(self,name, description='Run Controller ePix HR empty',  rates={1:'1 Hz', 2:'2 Hz', 4:'4 Hz', 8:'8 Hz', 10:'10 Hz', 30:'30 Hz', 60:'60 Hz', 120:'120 Hz'})
        self._thread = None

    def _setRunState(self,dev,var,value,changed):
        if changed: 
            if self.runState.get(read=False) == 'Running': 
                self._thread = threading.Thread(target=self._run) 
                self._thread.start() 
            else: 
                self._thread.join() 
                self._thread = None 


    def _run(self):
        self.runCount.set(0) 
        self._last = int(time.time()) 
 
 
        while (self.runState.value() == 'Running'): 
            delay = 1.0 / ({value: key for key,value in self.runRate.enum.items()}[self._runRate]) 
            time.sleep(delay) 
            #self._root.ssiPrbsTx.oneShot() 
  
            self._runCount += 1 
            if self._last != int(time.time()): 
                self._last = int(time.time()) 
                self.runCount._updated() 
                
##############################
# Set base
##############################
class Board(pyrogue.Root):
    def __init__(self, guiTop, cmd, dataWriter, srp, **kwargs):
        super().__init__(name='cryoAsicGen1',description='cryo ASIC', **kwargs)
        self.add(dataWriter)
        self.guiTop = guiTop
        self.cmd = cmd
        self.pollEn = False
        

        @self.command()
        def Trigger():
            self.cmd.sendCmd(0, 0)
            #if (self.EpixHRGen1Cryo.CryoAsic0.test.get() and dataWriter.frameCount.get()):
            #    pulserAmplitude = self.dataWriter.frameCount.get() #self.EpixHRGen1Cryo.CryoAsic0.Pulser.get()
            #    if pulserAmplitude%1024 == 1023:
            #        pulserAmplitude = 0
            #    else:
            #        pulserAmplitude += 1
            #    self.EpixHRGen1Cryo.CryoAsic0.Pulser.set(pulserAmplitude)

        # Add Devices
        if ( args.type == 'kcu1500' ):
            coreMap = rogue.hardware.axi.AxiMemMap('/dev/datadev_0')
            self.add(XilinxKcu1500Pgp3(memBase=coreMap))        
        self.add(fpga.EpixHRGen1Cryo(name='EpixHRGen1Cryo', offset=0, memBase=srp, hidden=False, enabled=True))
        self.add(pyrogue.RunControl(name = 'runControl', description='Run Controller hr', cmd=self.Trigger, rates={1:'1 Hz', 2:'2 Hz', 4:'4 Hz', 8:'8 Hz', 10:'10 Hz', 30:'30 Hz', 60:'60 Hz', 120:'120 Hz'}))



if (args.verbose): dbgData = rogue.interfaces.stream.Slave()
if (args.verbose): dbgData.setDebug(60, "DATA Verbose 0[{}]".format(0))
if (args.verbose): pyrogue.streamTap(pgpL0Vc0, dbgData)

if (args.verbose): dbgData = rogue.interfaces.stream.Slave()
if (args.verbose): dbgData.setDebug(60, "DATA Verbose 1[{}]".format(0))
# if (args.verbose): pyrogue.streamTap(pgpL1Vc0, dbgData)

if (args.verbose): dbgData = rogue.interfaces.stream.Slave()
if (args.verbose): dbgData.setDebug(60, "DATA Verbose 2[{}]".format(0))
if (args.verbose): pyrogue.streamTap(pgpL2Vc0, dbgData)

if (args.verbose): dbgData = rogue.interfaces.stream.Slave()
if (args.verbose): dbgData.setDebug(60, "DATA Verbose 3[{}]".format(0))
if (args.verbose): pyrogue.streamTap(pgpL3Vc0, dbgData)


if (args.type == 'SIM'):
    # Set the timeout
    timeout_time = 100000000 # firmware simulation slow and timeout base on real time (not simulation time)
else:
    # Set the timeout
    timeout_time = 5000000 # 5.0 seconds default
    
# Create GUI
appTop = pyrogue.gui.application(sys.argv)
guiTop = pyrogue.gui.GuiTop(group='cryoAsicGui')
cryoAsicBoard = Board(guiTop, cmd, dataWriter, srp)
if ( args.type == 'dataFile' or args.type == 'SIM'):
    cryoAsicBoard.start()
else:
    cryoAsicBoard.start()
guiTop.addTree(cryoAsicBoard)
guiTop.resize(800,800)

# Viewer gui
if START_VIEWER:
    onlineViewer = vi.Window(cameraType='cryo64xN')
    onlineViewer.eventReader.frameIndex = 0
    onlineViewer.setReadDelay(0)
    pyrogue.streamTap(pgpL0Vc0, onlineViewer.eventReader)
    if ( args.type != 'dataFile' ):
        pyrogue.streamTap(pgpL0Vc2, onlineViewer.eventReaderScope)# PseudoScope
#pyrogue.streamTap(pgpL0Vc3, onlineViewer.eventReaderMonitoring) # Slow Monitoring

if ( args.type == 'dataFile' or args.type == 'SIM'):
    print("Simulation mode does not initialize asic")
else:
    #configure internal ADC
    cryoAsicBoard.EpixHRGen1Cryo.FastADCsDebug.enable.set(True)
    cryoAsicBoard.readBlocks()
    cryoAsicBoard.EpixHRGen1Cryo.FastADCsDebug.DelayAdc0.set(15)
    cryoAsicBoard.EpixHRGen1Cryo.FastADCsDebug.enable.set(False)

    cryoAsicBoard.EpixHRGen1Cryo.Ad9249Config_Adc_0.enable.set(True)
    cryoAsicBoard.readBlocks()
    cryoAsicBoard.EpixHRGen1Cryo.Ad9249Config_Adc_0.InternalPdwnMode.set(3)
    cryoAsicBoard.EpixHRGen1Cryo.Ad9249Config_Adc_0.InternalPdwnMode.set(0)
    cryoAsicBoard.EpixHRGen1Cryo.Ad9249Config_Adc_0.OutputFormat.set(0)
    cryoAsicBoard.readBlocks()
    cryoAsicBoard.EpixHRGen1Cryo.Ad9249Config_Adc_0.enable.set(False)
    cryoAsicBoard.readBlocks()

    # executes the requested initialization
    cryoAsicBoard.EpixHRGen1Cryo.InitCryo(args.initSeq)

    
# Create GUI
if (args.start_gui):
    appTop.exec_()

# Close window and stop polling
cryoAsicBoard.stop()
exit()

