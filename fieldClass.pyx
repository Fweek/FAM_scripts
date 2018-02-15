cimport cython
import numpy as np
cimport numpy as np
import sys
from cpython cimport bool
@cython.boundscheck(False)
@cython.wraparound(False)

def classifyFields(np.ndarray [np.float32_t, ndim=2] thisYr,np.ndarray [np.float32_t, ndim=2] lastYr,np.ndarray [np.float32_t, ndim=2] refYr,np.ndarray [np.float32_t, ndim=2] outClass,int t1,tester=None):
  cdef int yDim = thisYr.shape[0]
  cdef int xDim = thisYr.shape[1]
  cdef int y = 0
  cdef int x = 0
  cdef int tsDim = xDim - 5

  cdef double noclass = -9995.0
  cdef double classVal = noclass
  cdef double noCCount = 0
  cdef double nodata = -9999.0
  
  cdef int noDCount = 0
  cdef double tsVal = nodata
  cdef int empTS = 0
  cdef double notEnough = -9994.0
 
  cdef double sid = 0
  
  cdef int cropTypeVal = -1
  cdef int cropTypePrev = -1
  cdef int cropTypeRef = -1
  cdef double csVal = noclass

  cdef int outIndx = t1
  t1 = t1 - 5 #coloffset
  cdef int prevClassIndx = t1 - 1
  cdef int prevClass = -1 

  cdef int tempClass = 0  
  cdef int notFound = 0

  #winterSkip = [2,5,6,7,8,9]
  winterSkip = []

  print "-----------------"
  print "(index,outIndx,yDim,xDim,tsDim):",t1,outIndx,yDim,xDim,tsDim
  
  cdef np.ndarray[np.float32_t, ndim=1] cSeries = np.zeros([tsDim], dtype=np.float32)

  cdef np.ndarray[np.float32_t, ndim=1] tsThisYr = np.zeros([tsDim], dtype=np.float32)
  cdef np.ndarray[np.float32_t, ndim=1] tsLastYr = np.zeros([tsDim], dtype=np.float32)
  cdef np.ndarray[np.float32_t, ndim=1] tsRefYr = np.zeros([tsDim], dtype=np.float32)
  
  #DEBUG
  #cdef double simsIDTest = 0#3905480.0
  cdef int countTemp = 0
  #cdef double idTest = 5107910.0

  for y in range(1,yDim): #first row is header
    #print "\r",y,   
    noDCount = 0
    simsIDTest = thisYr[<unsigned int>y,0]

    #if simsIDTest != idTest:
    #  continue
    #else:
    #   print simsIDTest,t1
    #if countTemp > 1:
    #  continue
    #else:
    #  countTemp += 1
    #  print simsIDTest,t1

    #temp = thisYr[<unsigned int>y,:]
    #print "Temp"
    #print temp

    #Load the ndvi averages TSeries and classification series
    for x in range(5,xDim): #first 5 columns: SimsID,pixCount,y,x,cropType
      tsVal = thisYr[<unsigned int>y,<unsigned int>x]
      tsThisYr[<unsigned int>x-5] = tsVal
      cSeries[<unsigned int>x-5] = outClass[<unsigned int>y,<unsigned int>x]
        
      #The rows will not line up year to year, need to retrieve  
      #Using same mask for all years
      #tsVal = prevYr[<unsigned int>y,<unsigned int>x]

      tsLastYr[<unsigned int>x-5] = lastYr[<unsigned int>y,<unsigned int>x]

      tsRefYr[<unsigned int>x-5] = refYr[<unsigned int>y,<unsigned int>x]

      if tsVal < -1:
        noDCount += 1

    #print tsThisYr  
    #print "-----------------------" 

    if noDCount >= (tsDim): #need to account for first few rows.
      empTS += 1
      outClass[<unsigned int>y,<unsigned int>outIndx] = notEnough
    else:
      #using same mask for all years to account for duplicates field shapes
      '''
      sid = thisYr[<unsigned int>y,0]
      tsLastYr = getTSByID(lastYr,sid,tsDim)

      if tsLastYr == None:
        #print "Error %d not found in last year file" % sid
        notFound += 1
        continue      

      tsRefYr = getTSByID(refYr,sid,tsDim)
      if tsRefYr == None:
        #print "Error %d not found in ref year file" % sid
        notFound += 1
        continue
      ''' 
      
      #Get croptype 
      cropTypeVal = int(thisYr[<unsigned int>y,4])
      cropTypePrev = int(lastYr[<unsigned int>y,4])
      cropTypeRef = int(refYr[<unsigned int>y,4])
     
      #print "Checking for clouds"
      #Should this be done when we create avgs file to speed up classfication???
      tsThisYr = checkForClouds(tsThisYr)   
      tsLastYr = checkForClouds(tsLastYr)
      tsRefYr = checkForClouds(tsRefYr) 

      #print tsThisYr
        

      #Check jan-mar 
      if t1 <= 11:
        #print "Checking jan-march"
        classVal = cropSpecificCheck(tsThisYr,tsLastYr,tsRefYr,t1,cropTypeVal,cropTypeRef)
        if classVal is not noclass:
          outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
        else:
          classVal = janMarCheck(tsThisYr,tsLastYr,t1) 
          outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
          
        #print outClass[<unsigned int>y,<unsigned int>outIndx],classVal 
      elif ((t1 > 11) and (t1 <= 19)): #Apr-May
        # allow prev. identified crops to persist through the winter; no need to check again
        #if (lastTStepClass == (2 or 5 or 6 or 7 or 8 or 9): 
     
        classVal = outClass[<unsigned int>y,<unsigned int>outIndx-1]
        if classVal in winterSkip:
          outClass[<unsigned int>y,<unsigned int>outIndx] = classVal     
        else:
          classVal = cropSpecificCheck(tsThisYr,tsLastYr,tsRefYr,t1,cropTypeVal,cropTypeRef)
          if classVal is not noclass:
            outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
          else:
            classVal = aprMayCheck(tsThisYr,tsLastYr,t1)
            outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
      elif ((t1 > 19) and (t1 <= 23)): #June
        # allow prev. identified perennial crops to persist 
        #through the summer as long as they are still clearly green in June
        classVal = outClass[<unsigned int>y,<unsigned int>outIndx-1]
        #if classVal == 5:
        #  tempClass = None #junPrevCheck(tsThisYr,classVal)
        #  if tempClass is not None:
        #    outClass[<unsigned int>y,<unsigned int>outIndx] = tempClass
        #    continue
        classVal = cropSpecificCheck(tsThisYr,tsLastYr,tsRefYr,t1,cropTypeVal,cropTypeRef)
        if classVal is not noclass:
            #print "persistant during summer", classVal
            outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
        else:
           prevClass = int(outClass[<unsigned int>y,<unsigned int>prevClassIndx])
           classVal = junCheck(tsThisYr,tsLastYr,t1,prevClass,cropTypeVal)
           outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
      elif (t1 > 23) and (t1 <= 33): #July-Sept
        classVal = julSeptCheck(tsThisYr,tsLastYr,tsRefYr,t1,prevClass,cropTypeVal,cropTypeRef)
        outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
      else:
        outClass[<unsigned int>y,<unsigned int>outIndx] = classVal
            
      
  #print "Number of no class items",noCCount
  print "Number of empty time Series,",empTS
  print "Number of no matching sims id",notFound
  return outClass


cdef getTSByID(np.ndarray[np.float32_t, ndim=2] yrList,double sid,int tsDim):
  cdef int yDim = yrList.shape[0]
  cdef int xDim = yrList.shape[1]
  cdef int y = 0
  cdef int x = 0
  cdef double sidVal = 0

  cdef np.ndarray[np.float32_t, ndim=1] tsYr = np.zeros([tsDim], dtype=np.float32)
 
  for y in range(1,yDim):
    sidVal = yrList[<unsigned int>y,0]

    if sidVal == sid:
      for x in range(5,xDim):
        tsYr[<unsigned int>x-5] = yrList[<unsigned int>y,<unsigned int>x]
      
      return tsYr
  
  return None   

cdef junPrevCheck(np.ndarray[np.float32_t, ndim=1] tsThisYr,double classVal):
  cdef double avgJunNdvi = 0
  cdef double avgMayNdvi = 0
  
  avgJunNdvi = average(tsThisYr,19,22)
  avgMayNdvi = average(tsThisYr,15,18)

  #THRESH
  if (avgJunNdvi >= 0.4) or (avgJunNdvi > avgMayNdvi):
     return classVal
  elif (avgMayNdvi > 0.5) and (avgJunNdvi < 0.3):
     return 16 #Clearly perennial

  return -9995 #None


cdef julSeptCheck(np.ndarray[np.float32_t, ndim=1] tsThisYr,np.ndarray[np.float32_t, ndim=1] tsLastYr,
              np.ndarray[np.float32_t, ndim=1] tsRefYr,int t1,int prevClass,
              int cropType,int cropTypeRef):
  cdef int tDimThis = tsThisYr.shape[0]
  cdef int tDimLast = tsLastYr.shape[0]   
   
  cdef double avgThis = 0
  cdef double avgLast = 0
    
  cdef int classVal = 0

  cdef double maxThis = 0
  cdef double maxLast = 0
  cdef int valsOver = 0
  cdef double slope = 0

  cdef double noclass = -9995.0

  cdef double maxJun = getMax(tsThisYr,21,22) #19to21
  cdef double maxSinceJun = getMax(tsThisYr,21,t1) #19to21
  cdef double maxSinceJan = getMax(tsThisYr,0,t1)

  cdef double avgThisMonth = average(tsThisYr,t1-4,t1) #Do we mean last 4 timesteps or actual month?
  cdef double avgPrevMonth = average(tsThisYr,t1-9,t1-5)
  cdef double avgJun = average(tsThisYr,19,22)

  cdef double avgLast32 = average(tsThisYr,t1-4,t1)
  cdef double avgLast33to64 = average(tsThisYr,t1-8,t1-5)

  #classSkip = [2,3,6,7,8,9]
  classSkip = []

  if prevClass == 5:
   if (avgThisMonth > 0.4) or (avgThisMonth > (1.05 * avgPrevMonth)):
     return prevClass
   if (avgJun > 0.5) and (avgThisMonth < 0.3):
      return 16.0 # cleared perennial
    
  # allow other prev. identified summer  crops to persist through the summer
  if prevClass in classSkip:
     return prevClass

  #1) Run Crop Specific Checks for Alfalfa, Wheat, Pasture, Rice, Perennials first 
  classVal = cropSpecificCheck(tsThisYr,tsLastYr,tsRefYr,t1,cropType,cropTypeRef)

  if classVal is not noclass:
    return classVal
  else:
    #if (maxSinceJun > 0.6): #TODO: Test and make sure its correct,also fix for June 0.34
    #if (maxSinceJun >= 0.4):
    #  return 2.0 # cropped, high confidence
    valsOver = countValsOverLimit(tsThisYr,21,t1,0.4)  #19to21
    if (valsOver >= 3):
       return 2.0 # cropped, high confidence

    valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21
    if (valsOver >= 2):
       return 3.0 # cropped, medium confidence

  
    slope = slopeOfBestFit(tsThisYr,t1-5,t1)
    if(maxSinceJun >= 0.3) and (slope >  0.05):
      return 4.0 # cropped, emergent

    if(maxSinceJun >= 0.3) and (avgLast32 > (avgLast33to64 + 0.1)):
      return 4.0 # cropped, emergent

    if(maxSinceJun >= 0.3) and increasing(tsThisYr,t1-5,t1):
      return 4.0 # cropped, emergent

    if(maxSinceJun <= 0.3):
      return 10.0 # no crop, high confidence
    if(maxSinceJun < 0.4):
      return 11.0 # no crop, medium confidence
       
  return 12.0 # no crop, low confidence

cdef junCheck(np.ndarray[np.float32_t, ndim=1] tsThisYr,np.ndarray[np.float32_t, ndim=1] tsLastYr,int t1,int prevClass,
              int cropType):
  cdef int tDimThis = tsThisYr.shape[0]
  cdef int tDimLast = tsLastYr.shape[0]   
   
  cdef double avgThis = 0
  cdef double avgLast = 0
    
  cdef double noclass = -9995.0
  cdef int classVal = 0

  cdef double maxThis = 0
  cdef double maxLast = 0
  cdef int valsOver = 0
  cdef double maxSinceJan = 0
  cdef double slope = 0

  cdef double maxMay = 0
  cdef double maxSinceNov = 0
  cdef double maxJun = getMax(tsThisYr,21,22) #19to21
  cdef double maxJun2Pres = getMax(tsThisYr,21,t1) #19to21

  cdef double maxSinceJun = 0
  cdef double minSinceJun = 0
  cdef double maxSinceMay = 0
 
  # add a rule to check for emergent crops and ensure that there is no spill over
  #if prevClass == 4:
  #  maxSinceNov = getMax(tsLastYr,38,tDimLast-1) + getMax(tsThisYr,0,15)
  #  maxMay = getMax(tsThisYr,15,18)
  #  if(maxMay > maxSinceNov) and (maxJun > maxMay):  
  #   # update value for field in April / May to change final winter crop class to 10    (nc-hc)
  #   ###Ask for clarification
  #   return noclass

  minSinceJun = getMin(tsThisYr,19,t1)
  maxSinceJun = getMax(tsThisYr,21,t1) #19to21
  maxSinceMay = getMax(tsThisYr,15,t1)  

  #print "juneCheck"
  #print minSinceJun,maxSinceJun,maxSinceMay

  #Added 2/3/2015
  #if(maxSinceMay >= 0.6) and (minSinceJun < 0.4) and decreasing(tsThisYr,t1-5,t1,0.05):
  # return 18.0 # new class for senescent winter crop

  valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21  
  if (valsOver >= 2):
    return 2.0 # cropped, high confidence

  valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21 
  if (valsOver >= 1) and increasing(tsThisYr,t1-4,t1):
    return 2.0 # cropped, medium confidence


  #THRESH
  if (maxJun2Pres >= 0.4):
     return 3.0 # cropped, high confidence
  
  slope = slopeOfBestFit(tsThisYr,t1-5,t1)
  if (maxJun2Pres >= 0.3) and (slope >  0.035):
    return 4.0 # cropped, emergent
    
  #if(maxSinceJun >= 0.3) and decreasing(tsThisYr,t1-5,t1):
  #  return 4.0 # cropped, emergent

  if(maxSinceJun >= 0.3) and increasing(tsThisYr,t1-4,t1):
    return 4.0 # cropped, emergent

  if(maxJun2Pres <= 0.3):
    return 10.0 # no crop, high confidence
    
  if(maxJun2Pres < 0.4):
    return 11.0 # no crop, medium confidence
    
  return 12.0 # no crop, low confidence

cdef aprMayCheck(np.ndarray[np.float32_t, ndim=1] tsThisYr,np.ndarray[np.float32_t, ndim=1] tsLastYr,int t1):
  cdef int tDimThis = tsThisYr.shape[0]
  cdef int tDimLast = tsLastYr.shape[0]   
   
  cdef double avgThis = 0
  cdef double avgLast = 0
    
  cdef int classVal = 0

  cdef double maxThis = 0
  cdef double maxLast = 0
  cdef int valsOver = 0
  cdef double maxSinceJan = 0
  cdef double maxSinceApr = 0
  cdef double slope = 0

  cdef double avgSinceJan = average(tsThisYr,0,t1)

  #Added 02032015
  cdef double maxSinceMay1 = 0

  if (avgSinceJan > 0.5):
    return 2.0 # cropped, high confidence

  valsOver = countValsOverLimit(tsThisYr,0,t1,0.6)
  if (valsOver >= 2):
    return 2.0 # cropped, high confidence

  valsOver = countValsOverLimit(tsThisYr,0,t1,0.5)
  if(valsOver >= 2):
    return 3.0 # cropped with medium confidence

  maxSinceApr = getMax(tsThisYr,11,t1)
  if (maxSinceApr >= 0.4) and (slopeOfBestFit(tsThisYr,t1-5,t1) > 0.05):
     return 4.0 # cropped, emergent
   
  avgThis = average(tsThisYr,t1-4,t1)
  #if (maxSinceJan >= 0.4) and (avgThis > NDVIavg-33-64-days-prior):
  #    return 4 # cropped, emergent
  
  #if (maxSinceJan >= 0.4) and decreasing(tsThisYr,t1-5,t1):
  #   return 4.0 # cropped, emergent
  maxSinceMay1 = getMax(tsThisYr,15,t1)

  if (maxSinceMay1 >= 0.3) and increasing(tsThisYr,t1-4,t1):  #--> t1 here should equal timestep 15; will need to add maxSinceMay function
     return 4.0 # cropped, emergent

  if (maxSinceJan <= 0.3):
     return 10.0 # no crop, high confidence
  
  if (maxSinceJan < 0.4):
    return 11.0 # no crop, medium confidence
  
  return 12.0 # no crop, low confidence

cdef janMarCheck(np.ndarray[np.float32_t, ndim=1] tsThisYr,np.ndarray[np.float32_t, ndim=1] tsLastYr,int t1):
   cdef int tDimThis = tsThisYr.shape[0]
   cdef int tDimLast = tsLastYr.shape[0]
   
   cdef int lastIndx = tDimLast-1   
   
   cdef double avgThis = 0
   cdef double avgLast = 0
    
   cdef int classVal = 0

   cdef double maxThis = 0
   cdef double maxLast = 0
   cdef int valsOver = 0
   cdef double maxSinceJan = 0
   cdef double maxSinceMar = 0
   cdef double slope = 0
 
   #Avg ndvi nov1 last year to present    
   cdef double avgNovPres = 0
   avgNovPres = average2Years(tsLastYr,38,lastIndx,tsThisYr,0,t1)
   
   if (avgNovPres > 0.5):
       return 2.0 # cropped, high confidence

   #valsOver = countValsOverLimit(tsLastYr,38,lastIndx,0.65) 
   #valsOver = valsOver + countValsOverLimit(tsThisYr,0,t1,0.65)
   valsOver = countValsOverLimit(tsThisYr,0,t1,0.65)

   if (valsOver >= 2.0):
      return 2.0 # cropped, high confidence

   #valsOver = countValsOverLimit(tsLastYr,38,lastIndx,0.6) + countValsOverLimit(tsThisYr,0,t1,0.6)
   valsOver = countValsOverLimit(tsThisYr,0,t1,0.6)
   if(valsOver >= 2.0):
      return 3.0 # cropped with medium confidence

   maxSinceMar = getMax(tsThisYr,8,t1)
   if t1 > 7:
     slope = slopeOfBestFit(tsThisYr,t1-5,t1)
     if (maxSinceMar >= 0.4) and (slope >  0.04):
       return 4.0 # cropped, emergent

   avgThis = average(tsThisYr,t1-4,t1)
   
   if t1 > 8:
    if(maxSinceMar >= 0.4) and increasing(tsThisYr,t1-4,t1):
     return 4.0 # cropped, emergent

   if(maxSinceJan <= 0.35):
      return 10.0 # no crop, high confidence
   if(avgNovPres <= 0.3):
      return 10.0 # no crop, high confidence
   if(avgNovPres < 0.4):
      return 11.0 # no crop, medium confidence
   
   return 12.0 # no crop, low confidence

cdef average2Years(np.ndarray[np.float32_t, ndim=1] yr1,int yr1St,int yr1End,
                  np.ndarray[np.float32_t, ndim=1] yr2,int yr2St,int yr2End):
   cdef int i = 0
   cdef double avg = 0.0 #-9999.0
   cdef double val = 0.0
   cdef double count = 0
   cdef double nodata = 0.09999
   
   #Do first year 
   for i in range(yr1St,yr1End+1):
     val = yr1[<unsigned int>i]
     if val > nodata:
       avg = avg + val
       count = count + 1.0
   
   #And second
   for i in range(yr2St,yr2End+1):
     val = yr2[<unsigned int>i]
     if val > nodata:
       avg = avg + val
       count = count + 1.0
   
   if count > 0.0:
      avg = avg/count
   else:
      avg = -9999.0

   return avg
   
cdef checkForClouds(np.ndarray[np.float32_t, ndim=1] tSeries):
   tDim = tSeries.shape[0]
   cdef double n1 = 0
   cdef double n2 = 0
   cdef double n3 = 0
   cdef int t = 0

   for t in range(0,tDim-2):
     n1 = tSeries[<unsigned int>t]
     n2 = tSeries[<unsigned int>t+1]
     n3 = tSeries[<unsigned int>t+2]

     if ((n1 - n2) > 0.3) and (n3 >= (0.9 * n1)):
       n2 = (n1 + n3) / 2
       tSeries[<unsigned int>t+1] = n2

   return tSeries


cdef cropSpecificCheck(np.ndarray[np.float32_t, ndim=1] tsThisYr,np.ndarray[np.float32_t, ndim=1] tsLastYr, np.ndarray[np.float32_t, ndim=1] tsRefYr, int t1, int cropType,int cropTypeRef):
  cdef int tDim = tsThisYr.shape[0]
  cdef int tempCount = 0
  cdef double tempSlope = 1
  cdef double tempMax = tsLastYr[0]
  cdef double tempMin = tsLastYr[1]
  cdef int peakCount = 0
  cdef double n1 = 0
  cdef double n2 = 0

  cdef int t = 0

  cdef double maxSinceJan = 0 
  cdef double maxSinceMar = 0 
  cdef double maxSinceJanRef = 0
  cdef double maxSinceMarRef = 0
  cdef double maxJun2Aug = 0
  cdef double maxSinceApr = 0
  cdef double maxLastSum = 0
  cdef double maxSinceJun = 0
  cdef double maxSinceMay = 0

  cdef double avgThis = 0
  cdef double avgThis2 = 0
  cdef double avgLast = 0

  cdef double slope = 0
  cdef double slopeMar = 0
  cdef double slopeApr = 0
  cdef double slopeMay = 0

  cdef double avgJun = 0
  cdef double avgJuly = 0
  cdef double avgAug = 0
  
  cdef bool confirmed = False
  cdef int perennial = 3
  cdef double noclass = -9995.0

  cdef double avgLast32 = 0
  cdef double avgLast33to64 = 0

  #print "t1 ",t1

  #alfalfa 1
  '''
  if cropType == 36:
     maxSinceJan = getMax(tsThisYr,0,t1) 
     #Winter Check
     if (t1 <= 19):
       if (maxSinceJan >= 0.5):
         return 7.0 # cropped, alfalfa
       elif (maxSinceJan < 0.5):
         return 14.0 # alfalfa, no crop yet
       else:
         return noclass # can’t confirm it’s alfalfa, so check for other crop indicators
  '''
  #TODO: Debug fix section below
  '''  
   for t in range(0,tDim-1):
     n1 = tsLastYr[t]
     n2 = tsLastYr[t+1]
     if((tempSlope > 0) and (n2 > n1)):
       tempMax = n2
     elif((tempSlope > 0) and (n2 < n1)):   # found local max
       if(((tempMax - tempMin) > 0.2) and (tempMax > 0.6)):   
         peakCount += 1
         tempSlope = -1  # change slope to negative
         tempMin = n2   # set new min value
     elif((tempSlope < 0) and (n2 < n1)):
       tempMin = n2
     elif((tempSlope < 0) and (n2 > n1)):
       tempSlope = 1
       tempMax = n2
 
     maxSinceJan = getMax(tsThisYr,0,t1) 
     #Winter Check
     if (t1 <= 19):
       if ((peakCount >= 2) and (maxSinceJan >= 0.6)):
         return 7.0 # cropped, alfalfa
       elif((peakCount >=2) and (maxSinceJan < 0.4)):
         return 14.0 # alfalfa, no crop yet
       else:
         return noclass # can’t confirm it’s alfalfa, so check for other crop indicators
     

     maxSinceJun = getMax(tsThisYr,19,t1) #19to21
     if(t1 > 19):
       if(peakCount < 3):
        return noclass # can’t confirm it’s alfalfa so check for other indicators
       else:  
        avgLast32 = average(tsThisYr,t1-4,t1)
        avgLast33to64 = average(tsThisYr,t1-8,t1-5)
        if (maxSinceJun >= 0.6):
           return 7.0 # cropped, alfalfa
        elif((maxSinceJun < 0.6) and (maxSinceJun >= 0.3)):
          slope = slopeOfBestFit(tsLastYr,t1-6,t1)
          if (maxSinceJun >= 0.3) and (slope >  0.05):
            return 4.0 # cropped, emergent
          elif (maxSinceJun >= 0.3) and (avgLast32 > (avgLast33to64 +0.1)):
            return 4.0 # cropped, emergent
        elif(maxSinceJun-1 >= 0.3) and decreasing(tsThisYr,t1-5,t1):
           return 4.0 # cropped, emergent
        else:
            return 14.0 #alfalfa, no crop yet (can’t tell difference between recent cutting and dry down)
        
     elif(maxSinceJun < 0.3):
        return 10.0 # no crop, high confidence
     else:
         return noclass # can’t confirm crop state
  '''
  
  #alfalfa 1
  if cropType == 36:
    if (t1 < 19):  
      maxSinceJan = getMax(tsThisYr,0,t1)
      valsOver = countValsOverLimit(tsThisYr,0,t1,0.65)
      if (valsOver >= 2.0):
        return 7.0 # cropped, alfalfa
      elif(maxSinceJan < 0.35):
           return 10 # no crop, high confidence
      elif((maxSinceJan < 0.65) and (maxSinceJan >= 0.35)):
         slope = slopeOfBestFit(tsThisYr,t1-6,t1)
         if (maxSinceJan >= 0.35) and (slope >  0.05):
           return 4.0 # cropped, emergent
      #elif (maxSinceJan >= 0.35) and (avgLast32 > (avgLast33to64 +0.1)):
      #   return 4.0 # cropped, emergent
      elif(maxSinceJan >= 0.35) and increasing(tsThisYr,t1-5,t1):
         return 4.0 # cropped, emergent
      else:
         return 14.0 # alfalfa, no crop yet     

    if(t1 >= 19):
      maxSinceJun = getMax(tsThisYr,21,t1) #19to21  
      avgLast32 = average(tsThisYr,t1-4,t1)
      avgLast33to64 = average(tsThisYr,t1-9,t1-5)
      valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21 
      if (valsOver >= 2.0):
        return 7.0 # cropped, alfalfa
      if (valsOver >= 1.0) and (t1 <= 22):
        return 7.0 # cropped, alfalfa      
      elif(maxSinceJun <= 0.35):
        return 10 # no crop, high confidence
      elif((maxSinceJun < 0.5) and (maxSinceJun >= 0.35)):
        slope = slopeOfBestFit(tsThisYr,t1-6,t1)
        if (maxSinceJun >= 0.35) and (slope >  0.035):
          return 4.0 # cropped, emergent
      elif (maxSinceJun >= 0.35) and (avgLast32 > (avgLast33to64 +0.1)):
          return 4.0 # cropped, emergent
      elif(maxSinceJun >= 0.35) and increasing(tsThisYr,t1-5,t1):
          return 4.0 # cropped, emergent
      else:
          return 11.0 # no crop, medium confidence     

  #Rice
  if cropType == 3:
     confirmed == False

     #if the slope for last March or April or May was positive and average NDVI for June 
     #and July and August was > 0.5 then confirm as rice
     slopeMar = slopeOfBestFit(tsLastYr,7,10) #march
     slopeApr = slopeOfBestFit(tsLastYr,11,14)
     slopeMay = slopeOfBestFit(tsLastYr,15,18)
     if (slopeMar > 0) or (slopeApr > 0) or (slopeMay > 0):
        avgJun = getMax(tsLastYr,19,22)
        avgJuly = getMax(tsLastYr,23,25)
        avgAug = getMax(tsLastYr,26,29)
        if (avgJun > 0.5) and (avgJuly > 0.5) and (avgAug > 0.5):
          confirmed = True ###TEMP need to implement check above   
  
     if (confirmed == True) and (t1 <= 8):
       return 15.0 # rice, no crop yet

     maxSinceMar = getMax(tsThisYr,8,t1)
     if (confirmed == True) and (t1 > 8) and (t1 <= 19):
       valsOver = countValsOverLimit(tsThisYr,0,t1,0.6) 
       if(valsOver >= 2):
         return 2.0 # cropped, but probably not rice if this green by early June
       if(valsOver < 2):
         return 15.0 # rice, no crop yet
       else:
         return noclass


       #if(maxSinceJan >= 0.6):
       #  return 9.0 # cropped, rice
       #if(maxSinceJan < 0.6):
       #  return 15.0 # rice, no crop yet  
        
       #return noclass

     #June - Sept
     if(t1 > 19) and (t1 <= 25): #    (confirmed == True):
       #maxSinceJan = getMax(tsThisYr,0,t1)
       maxSinceJun = getMax(tsThisYr,21,t1) #19to21
       valsOver = countValsOverLimit(tsThisYr,21,t1,0.6) #19to21
   
       if(valsOver >= 1):
         return 9.0 # rice
       if((valsOver < 2)  and (t1 <= 25)):
         return 15.0 # rice, no crop yet

     if(t1 > 25):    # and (confirmed == True):
       maxSinceJun = getMax(tsThisYr,21,t1) #19to21
       valsOver = countValsOverLimit(tsThisYr,21,t1,0.5) #19to21

       if(valsOver >= 2):
         return 9.0 # rice


       if((valsOver < 2)  and (t1 > 25) and (maxSinceJun > 0.4) and increasing(tsThisYr,t1-4,t1)):
           return 4.0 # cropped, emergent
       if((valsOver < 2)  and (t1 > 25) and (maxSinceJun < 0.35)):
           return 10.0 # no crop, high confidence
       if((valsOver < 2)  and (t1 > 25)):
           return 11.0 # no crop, medium confidence
      
     return noclass


     '''
     #THRESH 
     if(maxSinceJun >= 0.4):
        return 9.0 # cropped, rice
      #TRESH
      if(maxSinceJun < 0.4):
         return 15.0 # rice, no crop yet  
      else:
       return noclass
     '''  

  if isPerennial(cropType):
     # if perennial and month is Jan/Feb/March, 
     # no point in checking (too much confusion with cover crops before budbreak)
     if (t1 <= 15):
       return 13.0 # no crop yet, perennial

     # from tSeriesLast Year, find maximum value between June and August
     maxJun2Aug = getMax(tsLastYr,19,30)

     # calculate average for date of Max + 2 timesteps on each side
     # need to write this function

     if (t1 > 15) and (t1 < 19):
       maxSinceApr = getMax(tsThisYr,12,t1)
       maxSinceJan = getMax(tsThisYr,0,t1)
       maxLastSum = getMax(tsLastYr,21,34) #19to21
       avgThis = average(tsThisYr,t1-4,t1)
       avgThis2 = average(tsThisYr,t1-8,t1-5)
       avgLast = average(tsThisYr,t1-4,t1)
       maxSinceMay = average(tsThisYr,15,t1)

       #if (maxSinceApr >= 0.6):
       #  return 5.0 # perennial crop
   
       #(since Apr 1; at least 2 vals > 0.6)
       #step:  11
       #Time  12507.0 = 14 03 30 00  DOY= 88.0
       valsOver = countValsOverLimit(tsThisYr,15,t1,0.6)
       if valsOver > 1:
         return 5.0 # perennial crop
       
       if(maxSinceApr <= 0.6) and ((maxSinceJan) >= 0.4):
         avgThis = average(tsThisYr,t1-4,t1)
         avgThis2 = average(tsThisYr,t1-8,t1-5)

         #if(maxSinceJan >= (0.85 * maxLastSum)) and (avgThis > avgThis2):
         #  return 5.0 # perennial crop
         
         if ((maxSinceApr >= 0.4) and (maxSinceApr > (1.05 * maxLastSum)) and (avgThis > avgThis2)):
           return 5.0 # perennial crop

         if((maxSinceApr <= 0.6) and (maxSinceMay >= 0.4) and increasing(tsThisYr,t1-4,t1,0.03)):
           return 4.0 #


        

       #if(maxSinceJan < 0.4) and (avgThis > avgLast):
       #  return 6.0 # cropped, young perennia
       #else:
       return 13.0 #perennial no crop yet
       
     # June algorithm
     if ((t1 >= 19) and (t1 < 23)):
       maxSinceJun = getMax(tsThisYr,21,t1) #19to21
       maxLastSum = getMax(tsLastYr,21,34) #19to21
       
       # mature perennials
       #THRESH
       #if(maxSinceJun >= 0.4): # >= 0.6):
       #return 5.0 # cropped perennial
       #change to count vals over; at least 2 over 0.4
       valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21
       if valsOver > 1:
         return 5.0 # cropped perennial
     
 
       # young perennials
       avgThis = average(tsThisYr,t1-4,t1)
       avgThis2 = average(tsThisYr,t1-8,t1-5)
       #if(maxSinceJun >= (0.85 * maxLastSum)) and (avgThis > avgThis2):
       if((maxSinceJun > 0.2) and (maxSinceJun >= (1.05  * maxLastSum)) and (avgThis > (1.1 * avgThis2))):
         return 6.0 # cropped, young perennial

       # emergent
       #THRESH
       if (maxSinceJun < 0.4) and (maxSinceJun >= 0.25):
         slope = slopeOfBestFit(tsLastYr,t1-5,t1)
         if (slope >  0.035):
            return 4.0 # cropped, emergent
         elif (avgLast32 > (avgLast33to64 +0.1)):
            return 4.0 # cropped, emergent
         elif  increasing(tsThisYr,t1-5,t1):
           return 4.0 # cropped, emergent
         else:
            return 13.0 # no crop yet, perennial        

       if(maxSinceJun <= 0.3):
         return 11.0 # no crop, medium confidence

     # July-Sept algorithm
     if (t1 >= 23):
      avgThis = average(tsThisYr,t1-4,t1)
      maxSinceJan = average(tsThisYr,0,t1)
      maxSinceJun = getMax(tsThisYr,19,t1)

      # check for clearing
      if((t1 < 31) and (avgThis < 0.3) and (maxSinceJan > 0.6)):
        return 16.0 # cleared perennials 
 
      maxSinceJun = average(tsThisYr,19,t1)
      # mature perennials
      #if(maxSinceJun >= 0.6):
      #if(maxSinceJun >= 0.4):      replace with countValsOver, at least 2 vals over limit
      valsOver = countValsOverLimit(tsThisYr,21,t1,0.4)
      if valsOver > 1:
        return 5.0 # cropped perennial
      
      # young perennials
      maxLastSum = getMax(tsLastYr,19,34)
      avgThis = average(tsThisYr,t1-4,t1)
      avgThis2 = average(tsThisYr,t1-8,t1-4)
      if((maxSinceJun > 0.2) and (maxSinceJun >= (1.1 * maxLastSum))) and (avgThis > (1.15 * avgThis2)):
        return 6.0 # cropped, young perennial
      avgThis2 = average(tsLastYr,t1-4,t1)
      if((maxSinceJun > 0.2) and (maxSinceJun < 0.4)) and (avgThis > (1.15 * avgThis2)):
        return 6.0 # cropped, young perennial
      
      if(maxSinceJun < 0.4) and (maxSinceJun > 0.3):
        return 11.0 # no crop, medium confidence
      if(maxSinceJun <= 0.3):
       return 10.0 # no crop, high confidence
       
      return noclass


  #Wheat and pasture
  #use 2011 as ref year for now
  #if (cropType == 23) or (cropType == 62):
  if ((cropType >= 21) and (cropType <= 35)) or ((cropType >= 234) and (cropType <= 238)) or (cropType == 62):
     if(t1 <= 19):
      maxSinceMar = getMax(tsThisYr,8,t1) 
      valsOver = countValsOverLimit(tsThisYr,8,t1,0.6)
      if (valsOver >= 2.0):
        return 8.0 # winter wheat or pasture
      elif(valsOver < 2) and (maxSinceJan >= 0.45):
        #if(cropTypeRef == 23) or (cropTypeRef == 63):
        maxSinceMarRef = getMax(tsRefYr,8,t1)
        if(maxSinceMar >= (0.9 * maxSinceMarRef)):
          return 8.0 # winter wheat or pasture
          #print_to_winter_wheat_file (NDVI-max-since-Jan1-this-year / NDVI-max-since-Jan1-reference-Year)
         #return 11 # no crop-medium-confidence
      elif(maxSinceMar <= 0.3):
         return 10.0 #no crop high confidence
      elif(maxSinceMar <= 0.45):
         return 11.0 #no crop high confidence
      else:
         return noclass

     # June  
     if(t1 > 19 and t1 <= 23):
       maxSinceJun = getMax(tsThisYr,21,t1) #19to21
       maxMay = getMax(tsThisYr,15,18)
       valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21    

       #TODO: Fix this 
       #if((maxSinceJun < maxMay)): 
       #  return 10.0 # no crop
       #elif(maxSinceJun >= 0.4):
       if(valsOver >= 1):
         #THRESH
         return 8.0 # winter wheat or pasture
       elif(maxSinceJun <= 0.3): 
         return 10.0 # no crop, high confidence
       else:
         return 12.0 # no crop, low confidence
 

     # July - Sept
     if(t1 > 23):
      valsOver = countValsOverLimit(tsThisYr,21,t1,0.4) #19to21 
      maxSinceJun = getMax(tsThisYr,21,t1) #19to21
      maxSinceJan = getMax(tsThisYr,0,t1)

      #if(maxSinceJun >= 0.5):
      if(valsOver >= 2.0):
        return 8.0 # winter wheat or pasture
      #if(maxSinceJan < 0.5) and (maxSinceJan >= 0.3):
      # if((cropTypeRef == 23) or (cropTypeRef == 62)): 
      #  #calculate NDVI-max-since June1 / NDVI-max-since-June1 in 2011 and write-out entry to separate file
      #  return 11.0 # no crop-medium-confidence
      if(maxSinceJun <= 0.3):
        return 10.0 #no crop high confidence

      if(valsOver < 2):
        return 11.0 # no crop, medium confidence

      if(maxSinceJun <= 0.3):
        return 10.0 #no crop high confidence
      else:
        return 12.0 #no crop low confidence

  #noClass
  return noclass

def getMatchingSubsets(np.ndarray [np.float32_t, ndim=2] thisYr,np.ndarray [np.float32_t, ndim=2] lastYr,np.ndarray [np.float32_t, ndim=2] refYr,np.ndarray [np.float32_t, ndim=2] outClass):
  cdef int yDim = thisYr.shape[0]
  cdef int xDim = thisYr.shape[0]
  cdef int lDim = lastYr.shape[0]
  cdef int rDim = refYr.shape[0]
  
  cdef int y = 0
  cdef int x = 0
  cdef int l = 0
  cdef int r = 0
  
  cdef double thisVal = 0
  cdef double lastVal = 0
  cdef double refVal = 0

  cdef bool foundLast = False
  cdef bool foundRef = False

  cdef int indx = 0
   
  for y in range(1,yDim):
    foundLast = False
    foundRef = False

    thisVal = thisYr[<unsigned int>y,0]
     
    for l in range(1,lDim):
      lastVal = lastYr[<unsigned int>l,0]
            
      if lastVal == thisVal:
         foundLast = True
         break

    for r in range(1,rDim):
      refVal = refYr[<unsigned int>r,0]
            
      if lastVal == thisVal:
         foundRef = True
         break   

    if foundRef and foundLast:
      print "Raster"       
         

cdef hasClass(np.ndarray[np.float32_t, ndim=1] cSeries,int tStart,int tEnd,double classVal):
   cdef int i = 0
   cdef double classTmp = -1
     
   for i in range(tStart,tEnd+1):
     classTmp = cSeries[<unsigned int>i]
     if classTmp == classVal:
       return True
    
   return False

cdef getMax(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd):
    cdef int i = 0
    cdef double maxVal = 0.0 #-9999.0
    cdef double val = 0.0
    cdef double nodata = -1 #anything lower than -1 is nodata
    
    for i in range(tStart,tEnd+1):
       val = tSeries[<unsigned int>i]
       if (val > maxVal) and (val > nodata):
         maxVal = val

    return maxVal

cdef getMin(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd):
    cdef int i = 0
    cdef double minVal = 1.0 #-9999.0
    cdef double val = 0.0
    cdef double nodata = -1 #anything lower than -1 is nodata
    
    for i in range(tStart,tEnd+1):
       val = tSeries[<unsigned int>i]
       if (val < minVal) and (val > nodata):
         minVal = val

    return minVal

cdef getTreshByIndx(int indx):
    cdef double tresh = -1.0
    if (indx >= 7) and (indx <= 14): #Mar-Apr
       tresh = 0.75
    elif (indx >= 15) and (indx <= 18): #May
       tresh = 0.70
    elif (indx >= 19) and (indx <= 22):  #June
       tresh = 0.65
 
    return tresh

cdef getTreshByIndxMax(int indx):
    cdef double tresh = -1.0
    if (indx >= 7) and (indx <= 14):
       tresh = 0.75
    elif (indx >= 15) and (indx <= 22):  
       tresh = 0.2
 
    return tresh

cdef average(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd):
    cdef int i = 0
    cdef double avg = 0.0 #-9999.0
    cdef double val = 0.0
    cdef double count = 0
    cdef double nodata = 0.09999
    
    for i in range(tStart,tEnd+1):
       val = tSeries[<unsigned int>i]
       if val > nodata:
          avg = avg + val
          count = count + 1.0
    if count > 0.0:
       avg = avg/count
    else:
       avg = -9999.0

    return avg

cdef countValsOverLimit(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd,double limit):
    cdef int i = 0
    cdef double val = 0
    cdef int count = 0
    
    for i in range(tStart,tEnd+1):
      val = tSeries[<unsigned int>i]     
      #print val,limit
      if val >= limit:
         count += 1  
    #print "count",count     
    return count

cdef valsStayUnderTresh(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd,double tresh): 
    cdef int i = 0
    cdef double val = 0
    
    for i in range(tStart,tEnd+1):
      val = tSeries[<unsigned int>i] 
      if val > tresh:
         return False       
    return True

cdef valsGoOverTresh(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd,double tresh): 
    cdef int i = 0
    cdef double val = 0 

    for i in range(tStart,tEnd+1):
      val = tSeries[<unsigned int>i]     
      if val >= tresh:
         return True 
    return False

cdef increasing(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd,float tresh=0.02):
    cdef int i = 0
    cdef double val = 0
    cdef double curVal = tSeries[<unsigned int>tStart]
    cdef double nodata = 0.09999
    
    #We need at least three values with good data

    for i in range(tStart,tEnd+1):
       val = tSeries[<unsigned int>i] 
       if val > nodata:    
         if (val + tresh) < curVal:
           return False
         curVal = val
    return True

def increasing2(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd):
    #This function is just so we can access increasing from .py files
    return increasing(tSeries,tStart,tEnd)

cdef decreasing(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd, float tresh=0.03):
    cdef int i = 0
    cdef double val = 0
    cdef double prevVal = tSeries[<unsigned int>tStart]
    cdef double nodata = 0.09999

    for i in range(tStart,tEnd+1):
       val = tSeries[<unsigned int>i]
       if val > nodata:    
         if (val-tresh) > prevVal:
            return False
         prevVal = val
    return True

def decreasing2(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd, float tresh=0.0):
    cdef int i = 0
    cdef double val = 0
    cdef double prevVal = tSeries[<unsigned int>tStart]
    cdef double nodata = 0.09999

    for i in range(tStart,tEnd+1):
       val = tSeries[<unsigned int>i]
       if val > nodata:    
         print i,val,(val-tresh),prevVal
         if (val-tresh) > prevVal:
            return False
         prevVal = val
    return True
cdef slopeOfBestFit(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd):
     cdef int i = 0
     cdef double val = 0
     cdef double steps = 0
     cdef int fDim = 0
     cdef double valSt = 0
     cdef double valEnd = 0
     cdef double slope = 0
     cdef int count = 0
 
     #need to take care of nodata
     cdef int indx = 0
     xSeries = []
     ySeries = []
     
     for i in range(tStart,tEnd+1):
        val = tSeries[<unsigned int>i]
        if val > 0:
          ySeries.append(val)
          xSeries.append(indx)
        indx += 1        

     if len(ySeries) < 3:
        return -9993

     coefs = np.lib.polyfit(xSeries,ySeries,1) #1 means linear
     fitY = np.lib.polyval(coefs, xSeries)
     
     fDim = len(fitY) - 1
     valSt = fitY[0]
     valEnd = fitY[<unsigned int>fDim]

     steps = float(tEnd - tStart)

     slope = (valEnd - valSt)/steps
   
     return slope

def slopeOfBestFitGrapher(np.ndarray[np.float32_t, ndim=1] tSeries,int tStart,int tEnd):
     cdef int xDim = 5 #tEnd - tStart
     cdef int i = 0
     cdef double val = 0
     cdef int steps = 4
     cdef int fDim = 0
     cdef double valSt = 0
     cdef double valEnd = 0
     cdef double slope = 0
     cdef int count = 0
 
     #need to take care of nodata
     cdef int indx = 0
     xSeries = []
     ySeries = []
     

     for i in range(tStart,tEnd+1):
        val = tSeries[<unsigned int>i]
        #ySeries[<unsigned int>count] = val
        if val > 0:
          ySeries.append(val)
          xSeries.append(indx)
        indx += 1        

     coefs = np.lib.polyfit(xSeries,ySeries,1) #1 means linear
     fitY = np.lib.polyval(coefs, xSeries)
     
     fDim = len(fitY) - 1
     valSt = fitY[0]
     valEnd = fitY[<unsigned int>fDim]

     slope = (valEnd - valSt)/steps
   
     return slope,xSeries,ySeries,fitY                 

def getFieldAvgs(np.ndarray [np.float32_t, ndim=2] NDVI, np.ndarray [np.int32_t, ndim=2] centroids, np.ndarray [np.int32_t, ndim=2] maskSID,np.ndarray [np.float32_t, ndim=2] output,int colIndx):
    cdef int yDim = NDVI.shape[0]
    cdef int xDim = NDVI.shape[1]
    cdef int ctrVal = 0
    cdef int boxDim = 200
    cdef int y = 0
    cdef int x = 0
    cdef int i = 1
    cdef double totalPix = 0
    cdef double ndviAvg = 0
    cdef double sizeUnder = 0
    cdef double sizeUnderTmp = 0
    
    print "Getting field avgs..."
    for y in range(0 + boxDim,yDim - boxDim):
      #print "\r",y,
      for x in range(0 + boxDim,xDim - boxDim):         
        ctrVal = centroids[<unsigned int>y,<unsigned int>x]         
        if ctrVal > 0: 
           ndviAvg,totalPix,sizeUnderTmp = fieldAvg(NDVI,maskSID,ctrVal,y,x,boxDim)
           output[<unsigned int>i,<unsigned int>colIndx] = ndviAvg
           output[<unsigned int>i,1] = totalPix
           i += 1               
           sizeUnder = sizeUnder + sizeUnderTmp
    print sizeUnder
    return output

cdef fieldAvg(np.ndarray [np.float32_t, ndim=2] NDVI,
                  np.ndarray [np.int32_t, ndim=2] maskSID,int ctrVal, int y, int x, int boxDim,checkSize=False):
    cdef int sidVal = 0
    cdef double valCount = 0.0
    cdef double invalid = 0.1 #0.1 #Changing this value for ETC to 0.0
    cdef double ndviVal = -9999
    cdef double ndviAvg = 0.0
    cdef double ndviAvg2 = 0.0
    cdef int i = 0
    cdef int j = 0
    cdef int totalPix = 0
    cdef double pixUsed = 0

    for i in range(y - boxDim,y + boxDim):
      for j in range(x - boxDim,x + boxDim):
        sidVal = maskSID[<unsigned int>i,<unsigned int>j]
        if sidVal == ctrVal:
           totalPix += 1
           ndviVal = NDVI[<unsigned int>i,<unsigned int>j]
           if ndviVal > invalid:
              ndviAvg = ndviVal + ndviAvg
              valCount = valCount + 1.0
           
    if valCount <= 0:
       return -9999.0,totalPix,0.0 #Why are we returning -1?

    #Check that we have enough pixels
    if checkSize is False:
      pixUsed = valCount/float(totalPix)
      if pixUsed < 0.25:
        #print valCount,totalPix,pixUsed
        return -9999.0,totalPix,1.0

    ndviAvg2 = ndviAvg
    ndviAvg = ndviAvg/valCount
    
    if ndviAvg > 1.2:#1.0: #Changing for kc
       print ctrVal,ndviAvg2,valCount,y,x
       ndviAvg = 1.2 #1.0: #Changing for kc

    return ndviAvg,totalPix,0.0

def fieldAvgNP(np.ndarray [np.float32_t, ndim=2] NDVI,
              np.ndarray [np.int32_t, ndim=2] maskSID,int ctrVal, int y, int x, int boxDim):
    cdef int sidVal = 0
    cdef double valCount = 0
    cdef double invalid = 0.0999
    cdef double ndviVal = -9999
    cdef double ndviAvg = 0
    cdef int i = 0
    cdef int j = 0

    cdef np.ndarray[np.float32_t, ndim=1] tSeries = np.zeros([boxDim,boxDim], dtype=np.float32)

    for i in range(y - boxDim,y + boxDim):
      for j in range(x - boxDim,x + boxDim):
        sidVal = maskSID[<unsigned int>i,<unsigned int>j]
        if sidVal == ctrVal:
           ndviVal = NDVI[<unsigned int>i,<unsigned int>j]
           if ndviVal > invalid:
              tSeries[<unsigned int>i,<unsigned int>j] = ndviVal
              valCount = valCount + 1.0
    if valCount <= 0:
       return -9999.0,-1       
    tSeriesSub = np.ma.masked_less_equal(tSeries,invalid)
    ndviAvg = np.ma.average(tSeriesSub)
    
    return ndviAvg,valCount

def getFieldIds(np.ndarray [np.int32_t, ndim=2] centroids,np.ndarray [np.float32_t, ndim=2] output):
    cdef int yDim = centroids.shape[0]
    cdef int xDim = centroids.shape[1]
    cdef int ctrVal = 0
    cdef int y = 0
    cdef int x = 0
    cdef int count = 0
    cdef int i = 0
    

    print "Filling SID,y,x columns"
    for y in range(0,yDim):
      for x in range(0,xDim): 
        #check centroid layer
        ctrVal = centroids[<unsigned int>y,<unsigned int>x]         
        if ctrVal > 0:
           print "\r",i, 
           output[<unsigned int>i,0] = ctrVal
           output[<unsigned int>i,2] = y
           output[<unsigned int>i,3] = x
           count += 1
           i += 1
           
    print "Values found: ",count
    return output,count

def yxIndxer(np.ndarray [np.int32_t, ndim=2] mask,int valDim):
    cdef int yDim = mask.shape[0]
    cdef int xDim = mask.shape[1]
    cdef double nodata = -9999.0
    cdef int x = 0
    cdef int y = 0
    cdef int maskVal = -1
    cdef int indx = 0
    cdef int hitCount = 0
    print "Shape: ",yDim,xDim

    cdef np.ndarray [np.int32_t, ndim=2] sidYX = np.zeros([valDim,3], dtype=np.int32)
    print valDim

    for y in range(0,yDim): 
      print "\r",y,
      for x in range(0,xDim):
          maskVal = mask[<unsigned int>y,<unsigned int>x]
          if maskVal > 0:
             hitCount += 1
             indx += 1
             sidYX[<unsigned int>indx,0] = maskVal   
             sidYX[<unsigned int>indx,1] = y
             sidYX[<unsigned int>indx,2] = x
    print "Done with Count"
    print hitCount 
    return sidYX

def updateNC(np.ndarray [np.int32_t, ndim=2] classArr,np.ndarray [np.int32_t, ndim=2] sidMask,int indx,int dim):
    cdef int yDim = sidMask.shape[0]
    cdef int xDim = sidMask.shape[1]
    cdef int x = 0
    cdef int y = 0
    cdef int i = 0
    cdef int j = 0
    cdef int z = 0
    cdef int sidVal = -1
    cdef int classVal = -1
    cdef int maskVal = -1
    cdef double nodata = -9999.0
    cdef int boxDim = 150
    cdef int count = 0

    print yDim,xDim

    cdef np.ndarray [np.float32_t, ndim=2] fallowNc = np.ones([yDim,xDim], dtype=np.float32)
    fallowNc = fallowNc*nodata    

    for i in range(1,dim):
       print "\r",i,
       sidVal = classArr[<unsigned int>i,0]
       y = classArr[<unsigned int>i,2]
       x = classArr[<unsigned int>i,3]
       classVal = classArr[<unsigned int>i,<unsigned int>indx]
          
       #Fill pixels
       for j in range(y - boxDim,y+boxDim):
          for z in range(x-boxDim,x+boxDim):
             maskVal = sidMask[<unsigned int>j,<unsigned int>z]
             if maskVal == sidVal:
                count += 1
                fallowNc[<unsigned int>j,<unsigned int>z] = classVal

    print count
    return fallowNc

def getHeader(np.ndarray [np.int32_t, ndim=2] centroids,np.ndarray [np.int32_t, ndim=2]  cropArray,np.ndarray [np.float32_t, ndim=2] output):
    cdef int yDim = centroids.shape[0]
    cdef int xDim = centroids.shape[1]
    cdef int ctrVal = 0
    cdef int boxDim = 200 #120
    cdef int y = 0
    cdef int x = 0
    cdef int count = 0
    cdef int i = 1
    cdef int cropType = 0

    print "Getting mask values"
    for y in range(0 + boxDim,yDim - boxDim):
      for x in range(0 + boxDim,xDim - boxDim): 
        #check centroid layer
        ctrVal = centroids[<unsigned int>y,<unsigned int>x]         
        if ctrVal > 0:
           #print "\r",y,i,
           cropType = cropArray[<unsigned int>y,<unsigned int>x]
           output[<unsigned int>i,0] = ctrVal
           output[<unsigned int>i,2] = y
           output[<unsigned int>i,3] = x
           output[<unsigned int>i,4] = cropType
           count += 1
           i += 1
           
    print "Values found: ",count
    return output,count

def reclassify(np.ndarray [np.int16_t, ndim=2] inputArray):
   cdef int yDim = inputArray.shape[0]
   cdef int xDim = inputArray.shape[1]
   cdef int val = 0
   cdef int y = 0
   cdef int x = 0

   grapes = 69
   trees = [69,66,67,68,70,71,72,73,74,75,76,77,201,203,204,210,211,212,215,217,218,220,223]

   for y in range(0,yDim):
     for x in range(0,xDim):
       val = inputArray[<unsigned int>y,<unsigned int>x]
       if val in trees:
         inputArray[<unsigned int>y,<unsigned int>x] = 3
       else:
         inputArray[<unsigned int>y,<unsigned int>x] = 0

   return inputArray

cdef isPerennial(int cropType):
  trees = [69,66,67,68,70,71,72,73,74,75,76,77,201,203,204,210,211,212,215,217,218,220,223]
  if cropType in trees:
    return True
  else:
    return False

def reclassify(np.ndarray [np.float64_t, ndim=2] thisYr,int tStart,int tEnd,tester=None):
  cdef int yDim = thisYr.shape[0]
  cdef int xDim = thisYr.shape[1]
  cdef int y = 0
  cdef int x = 0
  cdef int z = 0
  cdef int tsDim = (tEnd - tStart) + 1  #xDim - 5
  print tsDim

  cdef double noclass = -9995.0
  cdef double classVal = noclass
  cdef double noCCount = 0
  cdef double nodata = -9999.0
  
  cdef int noDCount = 0
  cdef double tsVal = nodata
  cdef int empTS = 0
  cdef double notEnough = -9994.0
 
  cdef double sid = 0

  cdef double val = 0
  
  cdef double csVal = noclass
  cdef bool foundVal = False

  cdef int sVal = -1
  cdef double val1 = -1
  cdef double val2 = -1
  cdef double minClass = -1
  cdef int addToIndx = 0

  #DEBUG
  cdef int count = 0
  cdef int xCount = 0

  print "-----------------"
  print "(tStart,tEnd,yDim,xDim,tsDim):",tStart,tEnd,yDim,xDim,tsDim
  
  cdef np.ndarray[np.float32_t, ndim=1] tsThisYr = np.zeros([tsDim], dtype=np.float32)
  cdef np.ndarray[np.int32_t, ndim=2] output = np.zeros([yDim,3], dtype=np.int32)

  #rankingArray = [16,17,2,3,5,6,7,8,9,4,10,11,12,13,14,15]
  #rankingArray = [16,17,2,3,5,6,7,8,9,4,15,10,11,12,13,14]
  #rankingArray = [2,3,5,6,7,8,9,4,16,17,15,10,11,12,13,14]
  #rankingArray = [18,2,3,5,6,7,8,9,4,16,17,15,10,11,12,13,14]
  rankingArray = [2,3,5,6,7,8,9,4,16,17,15,10,11,12,13,14,18]

  for y in range(1,yDim): #first row is header
    #print "\r",y,   
    noDCount = 0
    xCount = 0
    addToIndx = 0

    output[<unsigned int>y,0] = int(thisYr[<unsigned int>y,0])
  
    #Load the ndvi averages TSeries and classification series
    for x in range(tStart,tEnd+1): #already taken care off first 5 columns: SimsID,pixCount,y,x,cropType
      tsVal = thisYr[<unsigned int>y,<unsigned int>x]
      tsThisYr[<unsigned int>xCount] = tsVal
      xCount += 1

    #June onward
    if (tStart >= 19): #TODO:need to update if planning to do over other time periods
      val1 = tsThisYr[<unsigned int>0] #jun 2nd
      val2 = tsThisYr[<unsigned int>1] #jun 10th
      minClass = min(tsThisYr[<unsigned int>2:]) #min class after jun 18th
 
      #if ((class on Jun 2 < 10 or class on June 10 < 10) and (min class from June 18 on >=10)
      if ((val1 < 10) or (val2 < 10)) and (minClass >= 10): 
        #then set class from 6/18 onward instead of 6/2 onward
        addToIndx = 2 #move up starting index to 6/18

    for r in rankingArray:
       foundVal = checkVal(tsThisYr,r,tsDim,addToIndx)
       if foundVal == True:
         output[<unsigned int>y,1] = int(r)
         sVal = simplifiedClass(int(r))
         output[<unsigned int>y,2] = sVal
         break

    #print output[<unsigned int>y,0],output[<unsigned int>y,1],output[<unsigned int>y,2]
    #if count > 10:
    #   return output
    #count += 1    

  return output
     
           
cdef checkVal(np.ndarray [np.float32_t, ndim=1] tsThisYr,double val,int tsDim,add=0):
   cdef int z = 0
   cdef double tsVal = 0
   cdef int tStart = 0  + add

   for z in range(tStart,tsDim):
     tsVal = tsThisYr[<unsigned int>z]
     if tsVal == val:          
       return True
      
   return False

cdef simplifiedClass(int val):
   cropped = [2, 3, 5, 6, 7, 9]# -> 2 (cropped)
   idle = [10, 11, 12] # -> 10 (idle)

   if val in cropped:
      return 2
   elif val in idle:
      return 10
   elif val == 4: #(emergent)
      return 4
   elif val == 8: #(pasture / winter wheat)
      return 8
   elif val == 13:
      return 13
   elif val == 14:
      return 14 
   elif val == 15:
      return 15
   elif val == 16:
      return 16
   elif val == 17:
      return 17 
   elif val == 18:
      return 18
   else:
      return -1

def reclassifyTo3Class(np.ndarray [np.int32_t, ndim=2] mask):
    cdef int yDim = mask.shape[0]
    cdef int xDim = mask.shape[1]
    cdef int x = 0
    cdef int y = 0
    cdef int maskVal = -1
    cdef int val3C = -1
    cdef double nodata = -9999.0

    row = [1,2,3,4,5,6,10,11,12,13,14,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,
           38,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,80,182,202,205,
           206,207,208,209,213,214,216,219,221,222,224,225,226,227,228,229,230,231,232,233,234,
           235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,254]

    vine = [69]
   
    tree = [66,67,68,70,71,72,73,74,75,76,77,201,203,204,210,211,212,215,217,218,220,223] 

    print yDim,xDim

    cdef np.ndarray [np.float32_t, ndim=2] output = np.zeros([yDim,xDim], dtype=np.float32)
    #output = output*nodata    

    for y in range(0,yDim):
      for x in range(0,xDim):
         maskVal = mask[<unsigned int>y,<unsigned int>x]
         if (maskVal > 0) and (maskVal < 270):
           if maskVal in row:
             output[<unsigned int>y,<unsigned int>x] = 1
           elif maskVal in vine:
             output[<unsigned int>y,<unsigned int>x] = 2
           elif maskVal in tree:
             output[<unsigned int>y,<unsigned int>x] = 3           

    return output
