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
import pyrogue.protocols
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
    "--ip", 
    type     = str,
    required = False,
    default  = '192.168.2.10',
    help     = "IP address",
) 

parser.add_argument(

    "--packVer", 
    type     = int,
    required = False,
    default  = 2,
    help     = "RSSI's Packetizer Version",
) 


parser.add_argument(
    "--enPrbs", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable PRBS testing",
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
    default  = [0,0,0],
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


##########
#added ethernet type below
##########

# RUDP Ethernet
elif ( args.type == 'eth' ):

    # Create the ETH interface @ IP Address = args.dev
    rudp = pr.protocols.UdpRssiPack(
        host    = args.ip,
        port    = 8192,
        packVer = args.packVer,
        jumbo   = True,
        expand  = False,
        )    
    # self.add(self.rudp) 
                
    # Map the AxiStream.TDEST
    pgpL0Vc1 = rudp.application(0); # AxiStream.tDest = 0x0
    pgpL0Vc0 = rudp.application(1);
    # pgpL0Vc2 = 

    # vc1Prbs = rudp.application(1); # AxiStream.tDest = 0x1
    # self.vc1Prbs.setZeroCopyEn(False)
#############
#############          

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

'''
##########
#added connect vco to srp? use the eth arguements
##########

# Connect VC0 to SRPv3
srp = rogue.protocols.srp.SrpV3()
pr.streamConnectBiDir(vc0Srp,srp)          

if args.enPrbs:        

    # Connect VC1 to FW TX PRBS
    prbsRx = pyrogue.utilities.prbs.PrbsRx(name='PrbsRx',width=128,expand=False)
    pyrogue.streamConnect(vc1Prbs,prbsRx)
    #self.add(prbsRx)  
        
    # Connect VC1 to FW RX PRBS
    prbTx = pyrogue.utilities.prbs.PrbsTx(name="PrbsTx",width=128,expand=False)
    pyrogue.streamConnect(prbTx, vc1Prbs)
    #self.add(prbTx)  
    
else:
    pyrogue.streamConnect(vc1Prbs,vc1Prbs) 


# Add registers
self.add(devBoard.Fpga(
    memBase  = srp,
    commType = args.type,
    fpgaType = args.fpgaType,
))        
  
#########
#########
'''


# Add data stream to file as channel 1 File writer
dataWriter = pyrogue.utilities.fileio.StreamWriter(name='dataWriter')
if ( args.type != 'dataFile' ):
    pyrogue.streamConnect(pgpL0Vc0, dataWriter.getChannel(0x1))
   # pyrogue.streamConnect(pgpL0Vc2, dataWriter.getChannel(0x2))
   # pyrogue.streamConnect(vc0Srp, dataWriter.getChannel(0x1))
   # pyrogue.streamConnect(vc1Prbs, dataWriter.getChannel(0x2))
   

cmd = rogue.protocols.srp.Cmd()
if ( args.type != 'dataFile' ):
    pyrogue.streamConnect(cmd, pgpL0Vc0)
   # pyrogue.streamConnect(cmd, vc0Srp)

# Create and Connect SRP to VC1 to send commands
srp = rogue.protocols.srp.SrpV3()
if ( args.type != 'dataFile' ):
    pyrogue.streamConnectBiDir(pgpL0Vc1,srp)
   # pyrogue.streamConnectBiDir(vc1Prbs,srp)



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

        @self.command()
        def Trigger():
            self.cmd.sendCmd(0, 0)
        @self.command()
        def DisplayViewer0():
            self.onlineViewer0.show()
        @self.command()
        def DisplayViewer1():
            self.onlineViewer1.show()
            
        # Add Devices
        if ( args.type == 'kcu1500' ):
            coreMap = rogue.hardware.axi.AxiMemMap('/dev/datadev_0')
            self.add(XilinxKcu1500Pgp3(memBase=coreMap))        
        self.add(fpga.KCU105FEMBCryo(name='KCU105FEMBCryo', offset=0, memBase=srp, hidden=False, enabled=True))
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
cryoAsicBoard.onlineViewer0 = vi.Window(cameraType='cryo64xN')
cryoAsicBoard.onlineViewer0.eventReader.frameIndex = 0
cryoAsicBoard.onlineViewer0.dilplayFramesFromAsics = 1
cryoAsicBoard.onlineViewer0.setReadDelay(0)
cryoAsicBoard.onlineViewer0.setWindowTitle("ASIC 0")
pyrogue.streamTap(pgpL0Vc0, cryoAsicBoard.onlineViewer0.eventReader)

cryoAsicBoard.onlineViewer1 = vi.Window(cameraType='cryo64xN')
cryoAsicBoard.onlineViewer1.eventReader.frameIndex = 0
cryoAsicBoard.onlineViewer1.dilplayFramesFromAsics = 0
cryoAsicBoard.onlineViewer1.setReadDelay(0)
cryoAsicBoard.onlineViewer1.setWindowTitle("ASIC 1")
pyrogue.streamTap(pgpL0Vc0, cryoAsicBoard.onlineViewer1.eventReader)

# executes the requested initialization
cryoAsicBoard.KCU105FEMBCryo.InitCryo(args.initSeq)

if (args.viewer == 'False'):
    cryoAsicBoard.onlineViewer0.hide()
    cryoAsicBoard.onlineViewer1.hide()

# Create GUI
if (args.start_gui):
    appTop.exec_()

# Close window and stop polling
cryoAsicBoard.stop()
exit()

