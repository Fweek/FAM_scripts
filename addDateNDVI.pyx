cimport cython
cimport numpy as np
import numpy as np

def populate (int yDim, np.ndarray[np.float_t, ndim=2] finalOutput, np.ndarray[np.float_t, ndim=2] tempOut):
    cdef int row = 0
    cdef double simsId = 0
    #cdef tuple j = ()
    cdef int j = 0
    cdef double date = 0
    cdef double ndvi = 0
    cdef double tempOutId = 0
    cdef int col = 0
    cdef double dateTemp = 0
    cdef double dateTemp2 = 0

    cdef int jDim = tempOut.shape[0]#0

    #cdef int currentIndx = 0
    cdef int cnt1 = 0
    cdef int cnt2 = 0
    cdef int cnt3 = 0
    
    print yDim
    print jDim

    for row in range(1,yDim): # for each row in the range of SIMs IDs (~300000)
        print '{0}\r'.format(row),
        simsId = finalOutput[<unsigned int>row, 0] # create variable called simsId, set it equal to the simsId in the [row, 0] position

        for j in range(0,jDim):#tempOut: # then in a different list
            #Get the sims IDs
            tempOutId = tempOut[<unsigned int>j,0] # make tempOutId equal to just the SIMS ID column
            # Check the date and add to column
            #print tempOutId,simsId
            if simsId < tempOutId:
                break

            elif simsId == tempOutId: # check to see if the two SIMS ID match up
                #currentIndx = j
                #we could use this to start searching at last position
                #print "IDs match", simsId, tempOutId # if they match says so
                date = tempOut[<unsigned int>j,1]  # create variables for each column
                ndvi = tempOut[<unsigned int>j,2]
                cnt1 += 1
                
                #If it's no data then move on to next row
                if ndvi > -1.0:
                  #print date, ndvi
                  cnt2 += 1
                    
                  #Find the colum
                  for col in range(5, 51):
                    dateTemp = int(finalOutput[0, <unsigned int>col])   # make new date variable based on header
                    dateTemp2 = dateTemp+8

                    if (date >= dateTemp) and (date < dateTemp2):
                        #print row, col, ndvi
                        finalOutput[<unsigned int>row, <unsigned int>col] = ndvi
                        cnt3 += 1
      
    print cnt1
    print cnt2
    print cnt3
    return finalOutput
