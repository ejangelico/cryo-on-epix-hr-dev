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
import setupLibPaths
import os, sys, time

sys.path.append(r'/home/t-1000/Desktop/dune/git_femb_new/cryo-on-epix-hr-dev/software/python')

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
PLOT_IMAGE            = False
PLOT_ADC9_VS_N        = False
PLOT_IMAGE_DARKSUB    = False
PLOT_IMAGE_DARK       = False
PLOT_IMAGE_HEATMAP    = False
PLOT_SET_HISTOGRAM    = False
PLOT_ADC_VS_N         = False
SAVE_HDF5             = True
SAVE_CSV              = False
CORRECT_COLUMN_JUMPS  = False #CHANNEL zero must be disabled

##################################################
# Dark images
##################################################
#
filename = '/u1/ddoering/data/FEMB_KCU105/offsiteLab/room/FEMB_KCU105_asic0_asic1_all_channels_internal_pulse_no_shield.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x0390_tp_0u6s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x0391_tp_0u6s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x0394_tp_1u2s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x0395_tp_1u2s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x0398_tp_2u4s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x0399_tp_2u4s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x039c_tp_3u6s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T1_448MHz_bench_tests/FEMB_SN01_448MHz_All_CHs_0x039d_tp_3u6s_bench_tests.dat'

filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x0390_CH0and32_disabled_tp_0u6s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x0391_CH0and32_disabled_tp_0u6s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x0394_CH0and32_disabled_tp_1u2s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x0395_CH0and32_disabled_tp_1u2s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x0398_CH0and32_disabled_tp_2u4s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x0399_CH0and32_disabled_tp_2u4s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x039c_CH0and32_disabled_tp_3u6s_bench_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T2_448MHz_bench_in_metalic_box_tests/FEMB_SN01_448MHz_All_CHs_0x039d_CH0and32_disabled_tp_3u6s_bench_tests.dat'

filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T3_448MHz_CTS/FEMB_SN01_448MHz_All_CHs_0x0399_CH0and32_disabled_tp_3u6s_CTS_tests.dat'

filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T4_224MHz_CTS/FEMB_SN01_224MHz_All_CHs_0x0390_tp_0u6s_CTS_tests.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Room/T4_224MHz_CTS/FEMB_SN01_224MHz_All_CHs_0x0398_tp_3u6s_CTS_tests.dat'

filename = '/u1/cryo/data/FEMB_SN01/ADC/T0_224MHz_ASIC0_ASIC1_ADC_Section/T0_224MHz_ASIC0_ASIC1_ADC_Section.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T0_224MHz_ASIC0_BotBank_Default/T0_224MHz_ASIC0_BotBank_Default.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T0_224MHz_ASIC0_BotBank_Default/T0_224MHz_ASIC0_BotBank_Default_AcquisitionLength0xc000.dat'

filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T1_224MHz_ASIC0_ASIC1_1CH/T1_224MHz_ASIC0_ASIC1_1CH_tp3u6s.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T1_224MHz_ASIC0_ASIC1_1CH/T2_224MHz_ASIC0_ASIC1_1CH_tp3u6s.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T1_224MHz_ASIC0_ASIC1_1CH/T3_224MHz_ASIC0_ASIC1_ALLCHs_tp3u6s.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T1_224MHz_ASIC0_ASIC1_1CH/T4_224MHz_ASIC0_ASIC1_ALLCHs_tp3u6s.dat'

filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T2_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard/FEMB01_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard_Tp0u6us.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T2_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard/FEMB01_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard_Tp1u2us.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T2_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard/FEMB01_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard_Tp2u4us.dat'
filename = '/u1/cryo/data/FEMB_SN01/Baseline/Cold/T2_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard/FEMB01_224MHz_ASIC0_ASIC1_ExtSupply_AdaptBoard_Tp3u6us.dat'

filename = '/home/t-1000/Desktop/dune/Data/Mar29_2021/FEMB_ASIC_BOTH_224MHz_AllCHs_0x0390_32768_Test.dat'

if (len(sys.argv[1])>0):
    filename = sys.argv[1]
else:
    filename = ''

f = open(filename, mode = 'rb')

file_header = [0]
numberOfFrames = [0 , 0]
previousSize = 0
asicID = 0
while ((len(file_header)>0) and ((numberOfFrames[0]<MAX_NUMBER_OF_FRAMES_PER_BATCH) or (numberOfFrames[1]<MAX_NUMBER_OF_FRAMES_PER_BATCH) or (MAX_NUMBER_OF_FRAMES_PER_BATCH==-1))):
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
            asicID = (newPayload[0]&0x00000010)>>4
            if asicID == 0:
                if (numberOfFrames[asicID] == 0):
                    allFrames_0 = [newPayload.copy()]
                else:
                    newFrame  = [newPayload.copy()]
                    allFrames_0 = np.append(allFrames_0, newFrame, axis = 0)
                numberOfFrames[asicID] = numberOfFrames[asicID] + 1 
                print ("Payload 0" , numberOfFrames, ":",  (newPayload[0:5]))
                previousSize = file_header
            if asicID == 1:
                if (numberOfFrames[asicID] == 0):
                    allFrames_1 = [newPayload.copy()]
                else:
                    newFrame  = [newPayload.copy()]
                    allFrames_1 = np.append(allFrames_1, newFrame, axis = 0)
                numberOfFrames[asicID] = numberOfFrames[asicID] + 1 
                print ("Payload 1 " , numberOfFrames, ":",  (newPayload[0:5]))
                previousSize = file_header

        if (numberOfFrames[asicID]%1000==0):
            print("Read %d frames" % numberOfFrames)

    except Exception: 
        e = sys.exc_info()[0]
        #print ("Message\n", e)
        print ('size', file_header, 'previous size', previousSize)
        print("numberOfFrames read: " ,numberOfFrames)

#%%
##################################################
# image descrambling
##################################################
currentCam = cameras.Camera(cameraType = cameraType)
currentCam.bitMask = bitMask
#numberOfFrames = allFrames.shape[0]
print("numberOfFrames in the 3D array: " ,numberOfFrames)
print("Starting descrambling images")
currentRawData = []
asicID = 0
imgDesc_0 = []
if(numberOfFrames[asicID]==1):
    [frameComplete, readyForDisplay, rawImgFrame] = currentCam.buildImageFrame(currentRawData = [], newRawData = allFrames_0[0])
    imgDesc_0 = np.array([currentCam.descrambleImage(bytearray(rawImgFrame.tobytes()))])
else:
    for i in range(0, numberOfFrames[asicID]):
        #get an specific frame
        [frameComplete, readyForDisplay, rawImgFrame] = currentCam.buildImageFrame(currentRawData, newRawData = allFrames_0[i,:])
        currentRawData = rawImgFrame

        #get descrambled image from camera
        if (len(imgDesc_0)==0 and (readyForDisplay)):
            imgDesc_0 = np.array([currentCam.descrambleImage(rawImgFrame)],dtype=np.float)
            currentRawData = []
        else:
            if readyForDisplay:
                currentRawData = []
                newImage = currentCam.descrambleImage(rawImgFrame)
                newImage = newImage.astype(np.float, copy=False)
                #if (np.sum(np.sum(newImage))==0):
                #    newImage[np.where(newImage==0)]=np.nan
                imgDesc_0 = np.concatenate((imgDesc_0, np.array([newImage])),0)
#############################
currentRawData = []
asicID = 1
imgDesc_1 = []
if(numberOfFrames[asicID]==1):
    [frameComplete, readyForDisplay, rawImgFrame] = currentCam.buildImageFrame(currentRawData = [], newRawData = allFrames_1[0])
    imgDesc_1 = np.array([currentCam.descrambleImage(bytearray(rawImgFrame.tobytes()))])
else:
    for i in range(0, numberOfFrames[asicID]):
        #get an specific frame
        [frameComplete, readyForDisplay, rawImgFrame] = currentCam.buildImageFrame(currentRawData, newRawData = allFrames_1[i,:])
        currentRawData = rawImgFrame

        #get descrambled image from camera
        if (len(imgDesc_1)==0 and (readyForDisplay)):
            imgDesc_1 = np.array([currentCam.descrambleImage(rawImgFrame)],dtype=np.float)
            currentRawData = []
        else:
            if readyForDisplay:
                currentRawData = []
                newImage = currentCam.descrambleImage(rawImgFrame)
                newImage = newImage.astype(np.float, copy=False)
                #if (np.sum(np.sum(newImage))==0):
                #    newImage[np.where(newImage==0)]=np.nan
                imgDesc_1 = np.concatenate((imgDesc_1, np.array([newImage])),0)
if(SAVE_HDF5):
    print("Saving Hdf5")
    h5_filename = os.path.splitext(filename)[0]+".hdf5"
    f = h5py.File(h5_filename, "w")
    f['adcData_0'] = imgDesc_0.astype('uint16')
    f['adcData_1'] = imgDesc_1.astype('uint16')
    f.close()

if(SAVE_CSV):
    for runNum in range(imgDesc_0.shape[0]):
        np.savetxt(os.path.splitext(filename)[0] + "_asic0_runNum" + str(runNum) + "_traces" + ".csv", imgDesc_0[runNum,:,:], fmt='%d', delimiter=',', newline='\n')
    for runNum in range(imgDesc_1.shape[0]):
        np.savetxt(os.path.splitext(filename)[0] + "_asic1_runNum" + str(runNum) + "_traces" + ".csv", imgDesc_1[runNum,:,:], fmt='%d', delimiter=',', newline='\n')

#%%
##################################################
#from here on we have a set of images to work with
##################################################
if PLOT_ADC9_VS_N :
    i=108
    # All averages and stds
    plt.figure(2,figsize=[8,12])
    plt.subplot(311)
    plt.title('Sample offset vs acquisition number')
    plt.plot(imgDesc_0[:,1,10],label="ASIC0")
    plt.plot(imgDesc_1[:,1,10],label="ASIC1")
    
    plt.subplot(312)
    plt.plot(np.transpose(imgDesc_0[i,0:63,:]))
    plt.title('Traces ASIC 0')
    
    plt.subplot(313)
    plt.plot(np.transpose(imgDesc_1[i,0:63,:]))
    plt.title('Traces ASIC 1')
    plt.legend()
    plt.show()
    
    
#%%    
if PLOT_ADC9_VS_N :
    i=108
    # All averages and stds
    plt.figure(2,figsize=[8,12])
    
    plt.subplot(211)
    plt.plot(np.transpose(imgDesc_0[i,1:63,:]))
    plt.title('Traces ASIC 0')
    
    plt.subplot(212)
    plt.plot(np.transpose(imgDesc_1[i,1:63,:]))
    plt.title('Traces ASIC 1')
    plt.legend()
    plt.show()

#%%
#show first image
if PLOT_IMAGE :
    for i in range(98, 109):
        plt.imshow(imgDesc_0[i,:,:], vmin=100, vmax=4000, interpolation='nearest')
        plt.gray()
        #plt.colorbar()
        plt.title('Sample image of ASIC 0:'+filename)
        plt.show()
        plt.pause(0.1)

#%%
if PLOT_IMAGE :
    for i in range(98, 109):
        plt.imshow(imgDesc_1[i,:,:], vmin=100, vmax=4000, interpolation='nearest')
        plt.gray()
        #plt.colorbar()
        plt.title('First image of ASIC 1:'+filename)
        plt.show()
        plt.pause(0.1)

#%%


#%%                                                       ###
###                                                       ###
####                                                     ####
######                                                 ######
########                                             ########
########## Code below needs to be updated for FEMB ##########
#############################################################
#############################################################
#############################################################
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


#%% baseline statistics
datasetIndex = 0
#adcData = imgDesc
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
   



