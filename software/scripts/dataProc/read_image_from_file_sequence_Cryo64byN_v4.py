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
import numpy as np
import ePixViewer.Cameras as cameras
import ePixViewer.imgProcessing as imgPr
# 
import matplotlib   
matplotlib.use('QT4Agg')
import matplotlib.pyplot as plt
import h5py


#matplotlib.pyplot.ion()
NUMBER_OF_PACKETS_PER_FRAME = 2
#MAX_NUMBER_OF_FRAMES_PER_BATCH  = 1500*NUMBER_OF_PACKETS_PER_FRAME
MAX_NUMBER_OF_FRAMES_PER_BATCH  = 4

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
SAVEHDF5              = True

##################################################
# Dark images
##################################################
def getData(localFile):

    file_header = [0]
    numberOfFrames = 0
    previousSize = 0
    while ((len(file_header)>0) and ((numberOfFrames<MAX_NUMBER_OF_FRAMES_PER_BATCH) or (MAX_NUMBER_OF_FRAMES_PER_BATCH==-1))):
        try:
            # reads file header [the number of bytes to read, EVIO]
            file_header = np.fromfile(localFile, dtype='uint32', count=2)
#            print("header 0: ", file_header[0])
#            print("header 1: ", (file_header[1]&0xff000000)>>24)
            payloadSize = int(file_header[0]/4)-1 #-1 is need because size info includes the second word from the header

            newPayload = np.fromfile(f, dtype='uint32', count=payloadSize) #(frame size splited by four to read 32 bit 
#            print ("Payload" , numberOfFrames, ":",  (newPayload[0:5]))
            #save only serial data frames
            if ((file_header[1]&0xff000000)>>24)==1: #image packet only, 2 mean scope data
                if (numberOfFrames == 0):
                    allFrames = [newPayload.copy()]
                else:
                    newFrame  = [newPayload.copy()]
                    allFrames = np.append(allFrames, newFrame, axis = 0)
                numberOfFrames = numberOfFrames + 1 
#                print ("Payload" , numberOfFrames, ":",  (newPayload[0:5]))
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
#    print("numberOfFrames in the 3D array: " ,numberOfFrames)
#    print("Starting descrambling images")
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

    return imgDesc

#filenameroot = '/data/cryoData/rampTest/data_rampTest_extSignal'
#filenameroot = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest4/RampTest4_HSDAC_Cfilter'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest5_noFilter/'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04//Room_04/rampTest6_Room_224MHz_NoFilter/'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest6_Room_224MHz_Filter/'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest6_DUNE_224MHz_NoFilter/'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest7_Room_448MHz_NoFilter/'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest7_DUNE_448MHz_NoFilter/'
#filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest8_Room_112MHz_NoFilter/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest2_20bitDAC_Room_Ch60toCh63/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest2_20bitDAC_DUNE_Ch60toCh63/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest3_20bitDAC_DUNE_Ch60/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest4_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest5_20bitDAC_DUNE_Ch63/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest6_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest7_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest8_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest9_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest10_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest11_20bitDAC_DUNE_Ch60toCh63/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest12_20bitDAC_DUNE_Ch61/'
filenamepath = '/u1/aldo/EXO_Lab/Board_C00-04/ADC_04/Room_04/500MHz_ExtClk_Test/500MHz_RampTest1_Room_Ch61/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest3_20bitDAC_Room_Ch60/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest4_20bitDAC_Room_Ch61/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/Room_04/rampTest9_20bitDAC_Room_224MHz_Ch60/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest10_20bitDAC_Room_448MHz_Ch60/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest11_20bitDAC_Room_224MHz_FastSett_Ch60/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest12_20bitDAC_Room_224MHz_FastSett_Ch61/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest13_20bitDAC_Room_224MHz_FastSett_Ch00/'
#filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest14_20bitDAC_Room_224MHz_FastSett_Ch01/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest15_20bitDAC_DUNE_Ch60_224MHz/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/Room_04/rampTest16_20bitDAC_DUNE_Ch61_224MHz/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest13_20bitDAC_DUNE_Ch61/'
filenamepath = '/data/cryoData/EXO_Lab/Board_C00-04/ADC_04/DUNE_04/rampTest14_20bitDAC_DUNE_Ch60/'
#filenameroot = 'RampTest5_HSDAC_noFilter_448MHz'
#filenameroot = 'RampTest6_CH0_CH63_HSDAC_noFilter_Room_224MHz'
#filenameroot = 'RampTest6_CH0_CH63_HSDAC_Filter_Room_224MHz'
#filenameroot = 'RampTest6_CH0_CH63_HSDAC_noFilter_DUNE_224MHz' 
#filenameroot = 'RampTest7_CH0_CH63_HSDAC_noFilter_Room_448MHz'
#filenameroot = 'RampTest8_CH0_CH63_HSDAC_noFilter_Room_112MHz'
filenameroot = 'rampTest2_20bitDAC_Room_Ch60to63' 
filenameroot = 'rampTest2_20bitDAC_DUNE_Ch60to63' 
filenameroot = 'rampTest3_20bitDAC_DUNE_Ch60'
filenameroot = 'rampTest4_20bitDAC_DUNE_Ch61'
filenameroot = 'rampTest5_20bitDAC_DUNE_Ch63'
filenameroot = 'rampTest6_20bitDAC_DUNE_Ch61'
filenameroot = 'rampTest7_20bitDAC_DUNE_Ch61'
filenameroot = 'rampTest8_20bitDAC_DUNE_Ch61'
filenameroot = 'rampTest10_20bitDAC_DUNE_Ch61'
filenameroot = 'rampTest11_20bitDAC_DUNE_Ch60toCh63'
filenameroot = '500MHz_RampTest1_Room_Ch61'
filenameroot = 'rampTest3_20bitDAC_Room_Ch61'
filenameroot = 'rampTest10_20bitDAC_Room_448MHz_Ch60_pxl47' 
filenameroot = 'rampTest11_20bitDAC_Room_224MHz_FastSett_Ch60'
filenameroot = 'rampTest12_20bitDAC_Room_224MHz_FastSett_Ch61_pxl47'
filenameroot = 'rampTest13_20bitDAC_Room_224MHz_FastSett_Ch00_pxl14'
#filenameroot = 'rampTest14_20bitDAC_Room_224MHz_FastSett_Ch01_pxl29'
filenameroot = 'rampTest15_20bitDAC_DUNE_Ch60_224MHz_pxl61'
filenameroot = 'rampTest16_20bitDAC_DUNE_Ch61_224MHz_pxl53'
filenameroot = 'rampTest13_20bitDAC_DUNE_Ch61_pxl48'
filenameroot = 'rampTest14_20bitDAC_DUNE_Ch60_pxl56'
##
##
filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN4/ADC/Room/RampTest/T0_RampTest_Room/'
filenameroot = 'T0_RampTest_20bitDAC_Room_448MHz_CH0toCH3_CH60to63'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest/T0_RampTest_20bitDAC_448MHz_Cold/'
filenameroot = 'T0_RampTest_20bitDAC_Cold_448MHz_CH0toCH1_ADC1'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Room/RampTest/T0_448MHz_20bitDAC_Room_Trig10/'
filenameroot = 'SN05_RampTest_20bitDAC_448MHz_ADC2Top_ADC2Bot_Trig10'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Room/RampTest/T1_448MHz_20bitDAC_Room_Trig5/'
filenameroot = 'SN05_RampTest_20bitDAC_448MHz_ADC2Top_ADC2Bot_Trig5'

#filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Room/RampTest/T2_224MHz_20bitDAC_Room_Trig5/'
#filenameroot = 'SN05_RampTest_20bitDAC_448MHz_CH4ADC2Top_CH59ADC2Bot_Trig5'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Room/RampTest/T3_448MHz_20bitDAC_Room_Trig5/'
filenameroot = 'SN05_RampTest_20bitDAC_448MHz_CH4ADC2Top_CH59ADC2Bot_Trig5'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Room/RampTest/T4_448MHz_20bitDAC_Room_Trig5/'
filenameroot = 'T4_SN05_RampTest_20bitDAC_448MHz_CH4ADC2Top_CH59ADC2Bot_Trig5'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest_Cold/T2_448MHz_20bitDAC_Cold_Trig5/'
filenameroot = 'T2_SN5_448MHz_CH4ADC2Top_CH59ADC2Bot_Trig5'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest_Cold/T3_448MHz_20bitDAC_Cold_Trig5/'
filenameroot = 'T3_SN5_448MHz_CH0ADC1Top_CH63ADC1Bot_Trig5'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest_Cold/T4_448MHz_20bitDAC_Cold_Trig5/'
filenameroot = 'T4_SN5_448MHz_CH28ADC8Top_CH35ADC8Bot_Trig5_65535'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest_Cold/T5_224MHz_20bitDAC_Cold_Trig5/'
filenameroot = 'T5_SN5_224MHz_CH4ADC2Top_CH59ADC2Bot_Trig5'

filenamepath = '/u1/cryo/data/Cryo_v2_nEXO_Varinat/Board_SN5/ADC/Cold/RampTest_Cold/T6_224MHz_20bitDAC_Cold_Trig5/'
filenameroot = 'T6_SN5_224MHz_CH4ADC2Top_CH59ADC2Bot_Trig5_ADCB2B3_0x3'

frame_index = 1

for j in range(0, 16):
    for i in range(j*int(65536/16), (j+1)*int(65536/16), 1):
        filename = filenamepath + filenameroot+"_"+ str(i)+".dat"
        print(filename)
        f = open(filename, mode = 'rb')
        newImage = getData(f)
        if not len(newImage):
            print("padding image")
            newImage = np.zeros((5,64,128))
                        
        print(newImage.shape)
        if i == j*int(65536/16):
            imgList = newImage[0]
        else:
            if newImage.shape[0]>frame_index:
                imgList = np.concatenate((imgList, newImage[frame_index]),0)


    #LAST PARAMETER DEPENDS ON NUMBER OF SAMPLES ACQUIRED
    imgDesc = imgList.reshape(-1,64,128) # when setting packet size to 4096
    #imgDesc = imgList.reshape(-1,64,256) # when setting packet size to 8192 
    #avgImgDesc = np.average(imgDesc,2)
    if(SAVEHDF5):
        print("Saving Hdf5")
        #h5_filename = os.path.splitext(filename)[0]+".hdf5"
        h5_filename = filenameroot+("_frame_%d"%frame_index)+".hdf5"
        if j==0:
            f = h5py.File(h5_filename, "w")
        else:
            f = h5py.File(h5_filename, "r+")
        f['adcData_'+str(j)] = imgDesc.astype('uint16')
        f.close()
        #np.savetxt(os.path.splitext(filename)[0] + "_traces" + ".csv", imgDesc[0,:,:], fmt='%d', delimiter=',', newline='\n')
        #np.savetxt(filenameroot + "_avgTraces" + ".csv", avgImgDesc[:,44], fmt='%d', delimiter=',', newline='\n')

    imgDesc = []
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



#show first image
if PLOT_IMAGE :
    for i in range(0, 1):
        plt.imshow(imgDesc[8,:,:], interpolation='nearest')
        plt.gray()
        plt.colorbar()
        plt.title('First image of :'+filename)
        plt.show()
    plt.plot(imgDesc[:,57,15])
    #plt.plot(imgDesc[:,45,5])
    plt.plot(avgImgDesc[:,57])
    plt.title('Pixel time series (15,15) and (15,45) :'+filename)
    plt.show()

    plt.hist(imgDesc[4,44,:])
    plt.show()

darkImg = np.mean(imgDesc, axis=0)
print(darkImg.shape)


if PLOT_IMAGE_DARK :
    plt.imshow(darkImg, interpolation='nearest')
    plt.gray()
    plt.colorbar()
    plt.title('Dark image map of :'+filename)
    plt.show()

heatMap = np.std(imgDesc, axis=0)
if PLOT_IMAGE_HEATMAP :
    plt.imshow(heatMap, interpolation='nearest', vmin=0, vmax=200)
    plt.gray()
    plt.colorbar()
    plt.title('Heat map of :'+filename)
    plt.show()

darkSub = imgDesc - darkImg
if PLOT_IMAGE_DARKSUB :
    for i in range(0, 1):
        #plt.imshow(darkSub[i,:,0:31], interpolation='nearest')
        plt.imshow(darkSub[i,:,:], interpolation='nearest')
        plt.gray()
        plt.colorbar()
        plt.title('First image of :'+filename)
        plt.show()



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




    


