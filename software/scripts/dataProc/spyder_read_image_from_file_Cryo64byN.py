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
import pyrogue as pr
import ePixViewer.Cameras as cameras
import ePixViewer.imgProcessing as imgPr
# 
import matplotlib   
#matplotlib.use('QT4Agg')
import matplotlib.pyplot as plt
import h5py

#matplotlib.pyplot.ion()
NUMBER_OF_PACKETS_PER_FRAME = 2
#MAX_NUMBER_OF_FRAMES_PER_BATCH  = 1500*NUMBER_OF_PACKETS_PER_FRAME
MAX_NUMBER_OF_FRAMES_PER_BATCH  = -1

PAYLOAD_SERIAL_FRAME = 4112 #2064
PAYLOAD_TS           = 7360

##################################################
# Global variables
##################################################
cameraType            = 'cryo64xN'
bitMask               = 0xffff
PLOT_IMAGE            = True
PLOT_ADC9_VS_N        = True
PLOT_IMAGE_DARKSUB    = False
PLOT_IMAGE_DARK       = False
PLOT_IMAGE_HEATMAP    = False
PLOT_SET_HISTOGRAM    = False
PLOT_ADC_VS_N         = False
SAVEHDF5              = False

##################################################
# Dark images
##################################################

filename = '/u1/ddoering/data/cryo0p2/roomTemp/NoiseAndPeakingTime/06262020/cryo_fullChainData_allChannels_pulse_channelConfig_0x02a9_analogMon_ch6.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp0u6s_bl380_ADUs_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp0u6s_bl380_ADUs_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp1u2s_bl380_ADUs_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp1u2s_bl380_ADUs_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp2u4s_bl380_ADUs_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp2u4s_bl380_ADUs_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp3u6s_bl380_ADUs_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T3_Baseline_CTS_448MHz_4CHs/CH0-CH3_CH32-CH35/CH0_CH3_CH32-CH35_tp3u6s_bl380_ADUs_81920.dat'
#
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp0u6s_bl250_ADUs_24C_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp0u6s_bl250_ADUs_24C_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp1u2s_bl250_ADUs_24C_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp1u2s_bl250_ADUs_24C_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp2u4s_bl250_ADUs_24C_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp2u4s_bl250_ADUs_24C_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp3u6s_bl250_ADUs_24C_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T5_Baseline_CTS_448MHz_8CHs/CH0_CH3_CH32-CH35_g3x0_tp3u6s_bl250_ADUs_24C_81920.dat'
#
filename = '/u1/ddoering/data/cryo0p2/roomTemp/pulsingChannels/cryo_data_allChannelsButOneAtATime_pulse_channel_config_0x0329.dat'
filename = '/u1/ddoering/data/cryo0p2/roomTemp/pulsingChannels/cryo_data_allChannelsButOneAtATime_pulse_channel_config_0x0029.dat'

filename = '/u1/ddoering/data/cryo-c01/Board_SN2/Full_Chain/Baseline/Room/T4_Baseline_CTS_224MHz_All_CHs/All_CHs_0x02a1_tp0u6s_bl300_ADUs_81920.dat'

filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x0391_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp0u6s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x0391_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp0u6s_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x0395_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp1u2s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x0395_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp1u2s_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x0399_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp2u4s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x0399_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp2u4s_81920.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x039d_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp3u6s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T3_Baseline_448MHz_Cdet_VDD/CHs_OK_Top_0x039d_bl400ADUs_blcor0x6_bltrim7_g1x5_Tp3u6s_81920.dat'

filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_0x0391_bltrimm7_7Bot_0x0191_bltrim3_blcoars0x06_g1x5_Tp0u6s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_0x0395_bltrimm7_7Bot_0x0195_bltrim3_blcoars0x06_g1x5_Tp1u2s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_0x0399_bltrimm7_7Bot_0x0199_bltrim3_blcoars0x06_g1x5_Tp2u4s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_0x039d_bltrimm7_7Bot_0x019d_bltrim3_blcoars0x06_g1x5_Tp3u6s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_7Bot_0x0391_blcor0x5_bltrim7_g1x5_Tp0u6s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_7Bot_0x0395_blcor0x5_bltrim7_g1x5_Tp1u2s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_7Bot_0x0399_blcor0x5_bltrim7_g1x5_Tp2u4s_8192.dat'
filename = '/u1/ddoering/data/cryo-c01/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T4_Baseline_448MHz_Cdet_VDD_Top_Bot_Bank/CHs_OK_2Top_7Bot_0x039d_blcor0x5_bltrim7_g1x5_Tp3u6s_8192.dat'

#atPC95109
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T11_Bln_CTS_448MHz_CHs_DirectPath_Cdet_CH0_CH1_NoWirebond_Ext_LDOs/SN2_448MHz_Cdet_150pF_CH0_CTS_3u6s_Cdet_VDD_AnaMon_Ext_LDOs_LDO3_1v17.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T11_Bln_CTS_448MHz_CHs_DirectPath_Cdet_CH0_CH1_NoWirebond_Ext_LDOs/SN2_448MHz_Cdet_150pF_CH1_CTS_3u6s_Cdet_VDD_AnaMon_Ext_LDOs_LDO3_1v17.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Room/T11_Bln_CTS_448MHz_CHs_DirectPath_Cdet_CH0_CH1_NoWirebond_Ext_LDOs/SN2_448MHz_Cdet_150pF_CH3_CTS_3u6s_Cdet_VDD_AnaMon_Ext_LDOs_LDO3_1v17.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T11_Bln_CTS_448MHz_CHs_DirectPath_Cdet_CH0_CH1_NoWirebond_Ext_LDOs/SN2_448MHz_Cdet_150pF_CH0_CTS_3u6s_Cdet_VDD_AnaMon_Ext_LDOs_LDO3_Below1V.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T11_Bln_CTS_448MHz_CHs_DirectPath_Cdet_CH0_CH1_NoWirebond_Ext_LDOs/SN2_448MHz_Cdet_150pF_CH1_CTS_3u6s_Cdet_VDD_AnaMon_Ext_LDOs_LDO3_Below1V.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN2/Full_Chain/Baseline/Cold/T11_Bln_CTS_448MHz_CHs_DirectPath_Cdet_CH0_CH1_NoWirebond_Ext_LDOs/SN2_448MHz_Cdet_150pF_CH3_CTS_3u6s_Cdet_VDD_AnaMon_Ext_LDOs_LDO3_Below1V.dat'
#
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/Full_Chain/Baseline/Cold/T2_448MHz_All_CHs_Pulsed_WireBond_TopBank_Collect_Induct_Cold/SN5_448MHz_CH0toCH3_CH10toCH13_0x0391_Wirebond_TopBank_Tp0u6s_Collect_81920.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/Full_Chain/Baseline/Cold/T2_448MHz_All_CHs_Pulsed_WireBond_TopBank_Collect_Induct_Cold/SN5_448MHz_CH0toCH3_CH10toCH13_0x0395_Wirebond_TopBank_Tp1u2s_Collect_81920.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/Full_Chain/Baseline/Cold/T2_448MHz_All_CHs_Pulsed_WireBond_TopBank_Collect_Induct_Cold/SN5_448MHz_CH0toCH3_CH10toCH13_0x0399_Wirebond_TopBank_Tp2u4s_Collect_81920.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/Full_Chain/Baseline/Cold/T2_448MHz_All_CHs_Pulsed_WireBond_TopBank_Collect_Induct_Cold/SN5_448MHz_CH0toCH3_CH10toCH13_0x039d_Wirebond_TopBank_Tp3u6s_Collect_81920.dat'
#
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN4/ADC/Room/RampTest/T0_RampTest_Room/T0_RampTest_20bitDAC_Room_448MHz_CH0toCH3_CH60to63_0.dat'
filename = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest/T0_RampTest_20bitDAC_448MHz_Cold/T0_RampTest_20bitDAC_Cold_448MHz_CH0toCH1_ADC1_0.dat'

f = open(filename, mode = 'rb')

file_header = [0]
numberOfFrames = 0
previousSize = 0
while ((len(file_header)>0) and ((numberOfFrames<MAX_NUMBER_OF_FRAMES_PER_BATCH) or (MAX_NUMBER_OF_FRAMES_PER_BATCH==-1))):
    try:
        # reads file header [the number of bytes to read, EVIO]
        file_header = np.fromfile(f, dtype='uint32', count=2)
        print("header 0: ", file_header[0])
        print("header 1: ", (file_header[1]&0xff000000)>>24)
        payloadSize = int(file_header[0]/4)-1 #-1 is need because size info includes the second word from the header

        newPayload = np.fromfile(f, dtype='uint32', count=payloadSize) #(frame size splited by four to read 32 bit 
        print ("Payload" , numberOfFrames, ":",  (newPayload[0:5]))
        #save only serial data frames
        if ((file_header[1]&0xff000000)>>24)==1: #image packet only, 2 mean scope data
            if (numberOfFrames == 0):
                allFrames = [newPayload.copy()]
            else:
                newFrame  = [newPayload.copy()]
                allFrames = np.append(allFrames, newFrame, axis = 0)
            numberOfFrames = numberOfFrames + 1 
            print ("Payload" , numberOfFrames, ":",  (newPayload[0:5]))
            previousSize = file_header

        if (numberOfFrames%1000==0):
            print("Read %d frames" % numberOfFrames)

    except Exception: 
        e = sys.exc_info()[0]
        #print ("Message\n", e)
        print ('size', file_header, 'previous size', previousSize)
        print("numberOfFrames read: " ,numberOfFrames)


##################################################
# image descrambling
##################################################
currentCam = cameras.Camera(cameraType = cameraType)
currentCam.bitMask = bitMask
#numberOfFrames = allFrames.shape[0]
print("numberOfFrames in the 3D array: " ,numberOfFrames)
print("Starting descrambling images")
currentRawData = []
imgDesc = []
if(numberOfFrames==1):
    [frameComplete, readyForDisplay, rawImgFrame] = currentCam.buildImageFrame(currentRawData = [], newRawData = allFrames[0])
    imgDesc = np.array([currentCam.descrambleImage(bytearray(rawImgFrame.tobytes()))])
else:
    for i in range(0, numberOfFrames):
        #get an specific frame
        [frameComplete, readyForDisplay, rawImgFrame] = currentCam.buildImageFrame(currentRawData, newRawData = allFrames[i,:])
        currentRawData = rawImgFrame

        #get descrambled image from camera
        if (len(imgDesc)==0 and (readyForDisplay)):
            imgDesc = np.array([currentCam.descrambleImage(rawImgFrame)],dtype=np.float)
            currentRawData = []
        else:
            if readyForDisplay:
                currentRawData = []
                newImage = currentCam.descrambleImage(rawImgFrame)
                newImage = newImage.astype(np.float, copy=False)
                #if (np.sum(np.sum(newImage))==0):
                #    newImage[np.where(newImage==0)]=np.nan
                imgDesc = np.concatenate((imgDesc, np.array([newImage])),0)
if(SAVEHDF5):
    print("Saving Hdf5")
    h5_filename = os.path.splitext(filename)[0]+".hdf5"
    f = h5py.File(h5_filename, "w")
    f['adcData'] = imgDesc.astype('uint16')
    f.close()
    
    for runNum in range(imgDesc.shape[0]):
        np.savetxt(os.path.splitext(filename)[0] + "_runNum" + str(runNum) + "_traces" + ".csv", imgDesc[runNum,:,:], fmt='%d', delimiter=',', newline='\n')


#%% baseline statistics
datasetIndex = 0
adcData = imgDesc
baselineAvg = np.mean(adcData[datasetIndex],axis=1)
baselineStd = np.std(adcData[datasetIndex],axis=1)
print(baselineAvg.shape)
np.savetxt(os.path.splitext(filename)[0] +  "_baselineStats" + ".csv", np.transpose([baselineAvg, baselineStd]), fmt='%3.3f', delimiter=',', newline='\n')

plt.figure(0)
plt.plot(baselineAvg)
plt.xlabel('Channel number')
plt.ylabel('Channel average')
plt.show()

plt.figure(1)
print(baselineAvg.shape)
plt.plot(baselineStd)
plt.xlabel('Channel number')
plt.ylabel('Channel standard deviation')
plt.show()


#%%
##################################################
#from here on we have a set of images to work with
##################################################
if PLOT_ADC9_VS_N :
    # All averages
    i=0
    plt.plot(imgDesc[i,10,:])
    plt.title('ADC value')
    plt.show()

    # All averages and stds
    plt.figure(1)
    plt.subplot(211)
    plt.title('Average ADC value')
    plt.plot(np.transpose(imgDesc[i,0:31,:]))

    plt.subplot(212)
    plt.plot(np.transpose(imgDesc[i,32:63,:]))
    plt.title('Standard deviation of the ADC value')
    plt.show()


#%%
##################################################
#from here on we have a set of images to work with
##################################################
if PLOT_ADC9_VS_N :
    i=0
    # All averages and stds
    plt.figure(1)
    plt.subplot(211)
    plt.title('Channels without AC coupling capacitor')
    ch=0
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    ch=6
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    ch=12
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    ch=18
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    plt.legend()

    plt.subplot(212)
    ch=0+2
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    ch=6+2
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    ch=12+2
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    ch=18+2
    plt.plot(np.transpose(imgDesc[i,ch,0:100]),label=("Channel %d" % ch))
    plt.title('Channels with AC coupling (Cdet of 150pF)')
    plt.legend()
    plt.show()


#%% baseline statistics
datasetIndex = 0
adcData = imgDesc

configFileName = "CRYO_ASIC_SN00_Room_Gain_3x_pt_1p2us_"
baselineGoal = 300
globalSettings = 0x0025
bltrimStep = 65
baselineInitSettings = 0

globalSettingsVector = np.ones((64,)) * globalSettings
baselineSetting      = np.zeros((64,))
baselineGoalVector   = np.ones((64,)) * baselineGoal

baselineAvg = np.mean(adcData[datasetIndex],axis=1)

baselineSetting = baselineInitSettings + np.round((baselineAvg - baselineGoalVector)/bltrimStep)

compositeSettings = globalSettingsVector + (baselineSetting*128)

np.savetxt(configFileName +  ".csv", compositeSettings, fmt='%d', delimiter=',', newline='\n')






#%%
channel = 0
localDataSet = adcData[datasetIndex,channel]
print(localDataSet.shape)
mu = np.mean(localDataSet)
sigma = np.std(localDataSet)
print("Array mean =  %f, std = %f" % (mu, sigma))

num_bins = 32
fig, ax = plt.subplots()
n, bins, patches = ax.hist(localDataSet, num_bins, density=2)
y = ((1 / (np.sqrt(2 * np.pi) * sigma)) * np.exp(-0.5 * (1 / sigma * (bins - mu))**2))
ax.plot(bins, y, '--')
ax.set_xlabel('ADC value [ADU]')
ax.set_ylabel('Probability density')
ax.set_title(r'Histogram of channel #%d: $\mu=%3.2f$, $\sigma=%3.2f$' %(channel, mu, sigma))

# Tweak spacing to prevent clipping of ylabel

plt.show()

#%%
#show first image
if PLOT_IMAGE :
    for i in range(0, 50):
        plt.imshow(imgDesc[i,:,:], vmin=100, vmax=4000, interpolation='nearest')
        plt.gray()
        #plt.colorbar()
        plt.title('First image of :'+filename)
        plt.show()
        plt.pause(0.1)
#%%
    plt.plot(imgDesc[:,0,15])
    plt.plot(imgDesc[:,0,5])
    plt.title('Pixel time series (15,15) and (15,45) :'+filename)
    plt.show()

darkImg = np.mean(imgDesc, axis=0)
print(darkImg.shape)

#%%
if PLOT_IMAGE_DARK :
    plt.imshow(darkImg, interpolation='nearest')
    plt.gray()
    plt.colorbar()
    plt.title('Dark image map of :'+filename)
    plt.show()
#%%
heatMap = np.std(imgDesc, axis=0)
if PLOT_IMAGE_HEATMAP :
    plt.imshow(heatMap, interpolation='nearest', vmin=0, vmax=200)
    plt.gray()
    plt.colorbar()
    plt.title('Heat map of :'+filename)
    plt.show()
#%%
darkSub = imgDesc - darkImg
if PLOT_IMAGE_DARKSUB :
    for i in range(0, 1):
        #plt.imshow(darkSub[i,:,0:31], interpolation='nearest')
        plt.imshow(darkSub[i,:,:], interpolation='nearest')
        plt.gray()
        plt.colorbar()
        plt.title('First image of :'+filename)
        plt.show()


#%%
# the histogram of the data
centralValue = 0
if PLOT_SET_HISTOGRAM :
    nbins = 100
    EnergyTh = -50
    n = np.zeros(nbins)
    for i in range(0, imgDesc.shape[0]):
    #    n, bins, patches = plt.hist(darkSub[5,:,:], bins=256, range=(0.0, 256.0), fc='k', ec='k')
    #    [x,y] = np.where(darkSub[i,:,32:63]>EnergyTh)
    #   h, b = np.histogram(darkSub[i,x,y], np.arange(-nbins/2,nbins/2+1))
    #    h, b = np.histogram(np.average(darkSub[i,:,5]), np.arange(-nbins/2,nbins/2+1))
        dataSet = darkSub[i,:,5]
        h, b = np.histogram(np.average(dataSet), np.arange(centralValue-nbins/2,centralValue+nbins/2+1))
        n = n + h

    plt.bar(b[1:nbins+1],n, width = 0.55)
    plt.title('Histogram')
    plt.show()


standAloneADCPlot = 5
centralValue_even = np.average(imgDesc[0,np.arange(0,32,2),standAloneADCPlot])
centralValue_odd  = np.average(imgDesc[0,np.arange(1,32,2),standAloneADCPlot])
# the histogram of the data
if PLOT_SET_HISTOGRAM :
    nbins = 100
    EnergyTh = -50
    n_even = np.zeros(nbins)
    n_odd  = np.zeros(nbins)
    for i in range(0, imgDesc.shape[0]):
    #    n, bins, patches = plt.hist(darkSub[5,:,:], bins=256, range=(0.0, 256.0), fc='k', ec='k')
    #    [x,y] = np.where(darkSub[i,:,32:63]>EnergyTh)
    #   h, b = np.histogram(darkSub[i,x,y], np.arange(-nbins/2,nbins/2+1))
    #    h, b = np.histogram(np.average(darkSub[i,:,5]), np.arange(-nbins/2,nbins/2+1))
        h, b = np.histogram(np.average(imgDesc[i,np.arange(0,32,2),standAloneADCPlot]), np.arange(centralValue_even-nbins/2,centralValue_even+nbins/2+1))
        n_even = n_even + h
        h, b = np.histogram(np.average(imgDesc[i,np.arange(1,32,2),standAloneADCPlot]), np.arange(centralValue_odd-nbins/2,centralValue_odd+nbins/2+1))
        n_odd = n_odd + h

    np.savez("adc_" + str(standAloneADCPlot), imgDesc[:,:,standAloneADCPlot])

    plt.bar(b[1:nbins+1],n_even, width = 0.55)
    plt.bar(b[1:nbins+1],n_odd,  width = 0.55,color='red')
    plt.title('Histogram')
    plt.show()

#%%
numColumns = 64
averages = np.zeros([imgDesc.shape[0],numColumns])
noises   = np.zeros([imgDesc.shape[0],numColumns])
if PLOT_ADC_VS_N :
    for i in range(0, imgDesc.shape[0]):
        averages[i] = np.mean(imgDesc[i], axis=0)
        noises[i]   = np.std(imgDesc[i], axis=0)

    #rolls matrix to enable dnl[n] = averages[n+1] - averages[n]
    dnls = np.roll(averages,-1, axis=0) - averages

    # All averages
    plt.plot(averages)
    plt.title('Average ADC value')
    plt.show()
    # All stds
    plt.plot(noises)
    plt.title('Standard deviation of the ADC value')
    plt.show()
    #dnl
    plt.plot(dnls)
    plt.title('DNL of the ADC value')
    plt.show()

    # All averages and stds
    plt.figure(1)
    plt.subplot(211)
    plt.title('Average ADC value')
    plt.plot(averages)

    plt.subplot(212)
    plt.plot(noises)
    plt.title('Standard deviation of the ADC value')
    plt.show()

    # selected ADC
    plt.figure(1)
    plt.subplot(211)
    plt.title('Average ADC value')
    customLabel = "ADC_"+str(standAloneADCPlot)
    line, = plt.plot(averages[:,standAloneADCPlot], label=customLabel)
    plt.legend(handles = [line])

    plt.subplot(212)
    plt.plot(noises[:, standAloneADCPlot], label="ADC_"+str(standAloneADCPlot))
    plt.title('Standard deviation of the ADC value')
    plt.show()

print (np.max(averages,axis=0) -  np.min(averages,axis=0))

#%%
imgAvg=np.zeros((imgDesc.shape[0],64)) 
for i in range(imgDesc.shape[0]):
    imgAvg[i,:]= np.average(imgDesc[i,:,20:40],1)-np.average(imgDesc[i,:,:],1) 
  
frameSequence = np.where(imgAvg>100)
for i in frameSequence[0]:
        plt.imshow(imgDesc[i,:,:], vmin=100, vmax=4000, interpolation='nearest')
        plt.gray()
        #plt.colorbar()
        plt.title('First image of :'+filename)
        plt.draw()
        plt.pause(0.1)

#%%
   



