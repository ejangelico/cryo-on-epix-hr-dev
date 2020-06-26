#-----------------------------------------------------------------------------
# Title      : read images from file script
#-----------------------------------------------------------------------------
# File       : read_image_from_file.py
# Created    : 2017-06-19
# Last update: 2017-06-21
#-----------------------------------------------------------------------------
# Description:
# Simple image viewer that enble a local feedback from data collected using
# ePix cameras. The initial intent is to use it with stand alone systems
#
#-----------------------------------------------------------------------------
# This file is part of the ePix rogue. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the ePix rogue, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import os, sys, time
import numpy as np
#import ePixViewer.Cameras as cameras
#import ePixViewer.imgProcessing as imgPr
# 
import matplotlib   
#matplotlib.use('QT4Agg')
import matplotlib.pyplot as plt
import h5py

#matplotlib.pyplot.ion()
NUMBER_OF_PACKETS_PER_FRAME = 1
#MAX_NUMBER_OF_FRAMES_PER_BATCH  = 1500*NUMBER_OF_PACKETS_PER_FRAME
MAX_NUMBER_OF_FRAMES_PER_BATCH  = -1


##################################################
# Global variables
##################################################
PLOT_SET_HISTOGRAM    = False
PLOT_ADC_VS_N         = True
SAVE_CSV_FILE         = False

##################################################
# Dark images
##################################################
def readScopeData(filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch0_config_0x11D1.dat'):

    f = open(filename, mode = 'rb')
    
    file_header = [0]
    numberOfFrames = 0
    previousSize = 0
    while ((len(file_header)>0) and ((numberOfFrames<MAX_NUMBER_OF_FRAMES_PER_BATCH) or (MAX_NUMBER_OF_FRAMES_PER_BATCH==-1))):
        try:
            # reads file header [the number of bytes to read, EVIO]
            file_header = np.fromfile(f, dtype='uint32', count=2)
            payloadSize = int(file_header[0]/4)-1 #-1 is need because size info includes the second word from the header
            print ('packet size',  file_header)
            
    
            #save only serial data frames
            newPayload = np.fromfile(f, dtype='uint16', count=payloadSize*2) #(frame size splited by four to read 32 bit 
            if ((file_header[1]&0xff000000)>>24)==2: #image packet only, 2 mean scope data
                if (numberOfFrames == 0):
                    allFrames = [newPayload.copy()]
                else:
                    newFrame  = [newPayload.copy()]
                    allFrames = np.append(allFrames, newFrame, axis = 0)
                numberOfFrames = numberOfFrames + 1 
                previousSize = file_header
            
            if (numberOfFrames%1000==0):
                print("Read %d frames" % numberOfFrames)
    
        except Exception: 
            e = sys.exc_info()[0]
            #print ("Message\n", e)
            print("End of file.")
            print ('size', file_header, 'previous size', previousSize)
            print("numberOfFrames read: " ,numberOfFrames)
                
    return allFrames


def analogMonitorADUtoV (aduArray):
    voltArray = ((2*aduArray/16384)*(-1.04))+(2-0.053)
    return voltArray
#%%
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch4_config_0x11A1.dat'
#allFramesA1 = readScopeData(filename)
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch4_config_0x11A5.dat'
#allFramesA5 = readScopeData(filename)
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch4_config_0x11A9.dat'
#allFramesA9 = readScopeData(filename)
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch4_config_0x11AD.dat'
#allFramesAD = readScopeData(filename)

#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch0_config_0x1125.dat'
#allFramesA1 = readScopeData(filename)
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch1_config_0x1125.dat'
#allFramesA5 = readScopeData(filename)
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch2_config_0x1125.dat'
#allFramesA9 = readScopeData(filename)
#filename = '/u1/ddoering/data/cryo0p2/roomTemp/AnalogMonitor/cryo_data_AnalogMonitor_ch3_config_0x1125.dat'
#allFramesAD = readScopeData(filename)

filename = '/u1/ddoering/data/cryo0p2/roomTemp/NoiseAndPeakingTime/06032020/cryo_data_AnalogMonitorAndData_peak_ch0x25_config_0x1321.dat'
allFramesA1 = readScopeData(filename)
filename = '/u1/ddoering/data/cryo0p2/roomTemp/NoiseAndPeakingTime/06032020/cryo_data_AnalogMonitorAndData_peak_ch0x25_config_0x1325.dat'
allFramesA5 = readScopeData(filename)
filename = '/u1/ddoering/data/cryo0p2/roomTemp/NoiseAndPeakingTime/06032020/cryo_data_AnalogMonitorAndData_peak_ch0x25_config_0x1329.dat'
allFramesA9 = readScopeData(filename)
filename = '/u1/ddoering/data/cryo0p2/roomTemp/NoiseAndPeakingTime/06032020/cryo_data_AnalogMonitorAndData_peak_ch0x25_config_0x132D.dat'
allFramesAD = readScopeData(filename)

allFrames = allFramesAD
##################################################
#from here on we have a set of traces to work with
##################################################
if SAVE_CSV_FILE:
    np.savetxt(os.path.splitext(filename)[0] + "_scope_traces" + ".csv", allFrames, fmt='%d', delimiter=',', newline='\n')

#%%
if PLOT_ADC_VS_N :
    
    # All single and all traces
    plt.figure(1)
    plt.subplot(211)
    plt.title('ADC value - single trace')
    plt.plot(allFrames[1,20:-20])

    plt.subplot(212)
    plt.plot(np.transpose(allFrames[:, 20:-20]))
    plt.title('ADC value - all traces')
    plt.show()

    plt.show()

#%%
testSignal = allFrames[1]
print(testSignal[20:30])
vhex = np.vectorize(hex)
print(vhex(testSignal[20:30]))
LSBArray = np.bitwise_and(testSignal,255)
MSBArray = np.bitwise_and(testSignal,65280)
#print(vhex(LSBArray[20:30]))
#print(vhex(MSBArray[20:30]))
newSignal = MSBArray[0:-1] + LSBArray[1:]
newSignal2 = MSBArray[1:] + LSBArray[0:-1]
difSignal = testSignal[:-1] - newSignal
print(vhex(newSignal[20:30]))
startPlot = 100
endPlot = np.int(newSignal.shape[0]/2)
endPlot = startPlot + 1500
if PLOT_ADC_VS_N :
    testSignal = analogMonitorADUtoV(allFramesA1[1])
    plt.figure(1)
    plt.subplot(221)
    plt.title('ADC config 0x11A1')
    plt.plot(testSignal[startPlot:endPlot-20])

    plt.subplot(222)
    testSignal = analogMonitorADUtoV(allFramesA5[3])
    plt.plot(testSignal[startPlot:endPlot-20])
    plt.title('ADC config 0x11A5')

    plt.subplot(223)
    testSignal = analogMonitorADUtoV(allFramesA9[1])
    plt.plot(testSignal[startPlot:endPlot-20])
    plt.title('ADC config 0x11A9')
    
    plt.subplot(224)
    testSignal = analogMonitorADUtoV(allFramesAD[1])
    plt.plot(testSignal[startPlot:endPlot-20])
    plt.title('ADC config 0x11AD')
   
    plt.show()


#%%
testSignal = allFrames[1]
print(testSignal[20:30])
vhex = np.vectorize(hex)
print(vhex(testSignal[20:30]))
LSBArray = np.bitwise_and(testSignal,255)
MSBArray = np.bitwise_and(testSignal,65280)
#print(vhex(LSBArray[20:30]))
#print(vhex(MSBArray[20:30]))
newSignal = MSBArray[0:-1] + LSBArray[1:]
newSignal2 = MSBArray[1:] + LSBArray[0:-1]
difSignal = testSignal[:-1] - newSignal
print(vhex(newSignal[20:30]))
startPlot = 100
endPlot = np.int(newSignal.shape[0]/2)
endPlot = startPlot + 1500
if PLOT_ADC_VS_N :
    testSignal = analogMonitorADUtoV(allFramesA1[1])
    plt.figure(1)
    plt.title('Single frame pulse for different peaking time')
    plt.plot(testSignal[startPlot:endPlot-20]/np.max(testSignal[startPlot:endPlot-20]))
    testSignal = analogMonitorADUtoV(allFramesA5[3])
    plt.plot(testSignal[startPlot:endPlot-20]/np.max(testSignal[startPlot:endPlot-20])) 
    testSignal = analogMonitorADUtoV(allFramesA9[1])
    plt.plot(testSignal[startPlot:endPlot-20]/np.max(testSignal[startPlot:endPlot-20]))  
    testSignal = analogMonitorADUtoV(allFramesAD[1])
    plt.plot(testSignal[startPlot:endPlot-20]/np.max(testSignal[startPlot:endPlot-20]))

   
    plt.show()


#%%
for nFrames in range(0,100,1):
    testSignal = allFramesA1[nFrames]    
    startPlot = 100
    endPlot = np.int(testSignal.shape[0]/2)
    endPlot = startPlot + 1500
    ymin = 0.4
    ymax = 2.0
    if PLOT_ADC_VS_N :
        plt.figure(1)
        #plt.title('Single frame pulse for different peaking time')
        #
        testSignal = analogMonitorADUtoV(allFramesA1[nFrames])    
        plt.subplot(221)
        plt.ylim(ymin, ymax)
        plt.title('Channel 4 config 0x11A1')
        plt.plot(testSignal[startPlot:endPlot-20])
        #
        testSignal = analogMonitorADUtoV(allFramesA5[nFrames])
        plt.subplot(222)
        plt.ylim(ymin, ymax)
        plt.title('Channel 4 config 0x11A5')
        plt.plot(testSignal[startPlot:endPlot-20]) 
        #
        testSignal = analogMonitorADUtoV(allFramesA9[nFrames])
        plt.subplot(223)
        plt.ylim(ymin, ymax)
        plt.title('Channel 4 config 0x11A9')
        plt.plot(testSignal[startPlot:endPlot-20])  
        #
        testSignal = analogMonitorADUtoV(allFramesAD[nFrames])
        plt.subplot(224)
        plt.ylim(ymin, ymax)
        plt.title('Channel 4 config 0x11AD')
        plt.plot(testSignal[startPlot:endPlot-20])

   
    plt.show()



#%%
for nFrames in range(0,100,1):
    testSignal = allFramesA1[nFrames]    
    startPlot = 100
    endPlot = np.int(testSignal.shape[0]/2)
    endPlot = startPlot + 1500
    ymin = 0.4
    ymax = 1.2
    if PLOT_ADC_VS_N :
        plt.figure(1)
        #plt.title('Single frame pulse for different peaking time')
        #
        testSignal = analogMonitorADUtoV(allFramesA1[nFrames])    
        plt.subplot(221)
        plt.ylim(ymin, ymax)
        plt.title('Channel 0 config 0x1125')
        plt.plot(testSignal[startPlot:endPlot-20])
        #
        testSignal = analogMonitorADUtoV(allFramesA5[nFrames])
        plt.subplot(222)
        plt.ylim(ymin, ymax)
        plt.title('Channel 1 config 0x1125')
        plt.plot(testSignal[startPlot:endPlot-20]) 
        #
        testSignal = analogMonitorADUtoV(allFramesA9[nFrames])
        plt.subplot(223)
        plt.ylim(ymin, ymax)
        plt.title('Channel 2 config 0x1125')
        plt.plot(testSignal[startPlot:endPlot-20])  
        #
        testSignal = analogMonitorADUtoV(allFramesAD[nFrames])
        plt.subplot(224)
        plt.ylim(ymin, ymax)
        plt.title('Channel 3 config 0x1125')
        plt.plot(testSignal[startPlot:endPlot-20])

   
    plt.show()



