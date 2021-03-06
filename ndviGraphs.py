import sys,os
import numpy
import matplotlib.pyplot as plt
from datetime import date

#-----------------------------------------------------------
def main():
  if len(sys.argv) < 3:
     sys.stderr.write("ndviGraphs.py <Input directory> <CSV list of SIMSIDs to graph> <merged mean NDVI timeseries CSV file> <year> <Output suffix>\n")
     sys.exit(1)
  outDir = sys.argv[1]
  inFn,avgsFn,year,outSuf = outDir+"/"+sys.argv[2],outDir+"/"+sys.argv[3],int(sys.argv[4]),sys.argv[5]

  print "Loading %s" % inFn
  fPtr = open(inFn,'r')
  if fPtr is None:
    print "Error opening %s" % inFn
    sys.exit(1)
  inList = fPtr.readlines()
  fPtr.close()

  print "Loading %s" % avgsFn
  avgsList = numpy.genfromtxt(avgsFn, dtype='double',delimiter = ',')

  if not os.path.exists(outDir):
    print "Error: %s directory doesnt exists" % outDir
    sys.exit(0)

  #Get header
  #hdr = avgsList[0][5::]
  #print hdr,len(hdr)
  #hdrMa = numpy.ma.masked_less_equal(hdr,0)

  #sys.exit(0)

  d0 = date(1980, 01, 01)
  d1 = date(year, 01, 01)
  delta = d1 - d0
  tStart = delta.days

  # if year == 2010: #days since 1980-01-01
  #    tStart = 10958
  # elif year == 2011:
  #    tStart = 11323
  # elif year == 2012:
  #    tStart = 11688
  # elif year == 2013:
  #    tStart = 12054
  # elif year == 2014:
  #    tStart = 12419
  # elif year == 2015:
  #    tStart = 12784
  # elif year == 2016:
  #    tStart = 13149
  # else:
  #    print "Error: Only 2010-2016 supported"
  #    sys.exit(1)
  tEnd = tStart + 365

  xSeries = numpy.zeros((46),dtype=numpy.int32)
  indx = 0

  for i in range(tStart,tEnd,8):
      xSeries[indx] = i
      indx += 1

  xTicks = []
  xTicks = [tStart+0,tStart+31,tStart+59,tStart+90,tStart+120,tStart+151,tStart+181,tStart+212,tStart+243,tStart+273,tStart+304,tStart+334]
  xLabels = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
  print xTicks

  notFound = 0
  notFList = []
  for sid in inList:
      sid = int(sid)
      ndvi = findRow(sid,avgsList)
      if ndvi is not None:
        print ndvi

        print "Masking data"
        ndviLen = len(ndvi)
        print ndviLen

        y = numpy.ma.masked_less_equal(ndvi,-9994.0)

        #y2 = y[y>-9994]
        y2 = y[y>-9994]
        x = xSeries[y>-9994.0]
        #print y2,x
        minX = numpy.min(x)
        maxX = numpy.max(x)

        print "Plotting data"
        plt.plot(x,y2,'*',x,y2,'r--')
        plt.ylim(0,1)
        plt.ylabel("NDVI")
        plt.xticks(xTicks,xLabels)
        plt.xlim(minX,maxX)
        plt.xlabel("Months")
        plt.title("SIMS ID: "+str(sid))
        #plt.show()
        #sys.exit(0)
        print "Saving to file"
        plt.savefig(outDir+'/'+str(sid)+'_'+str(year)+"_"+outSuf)
        plt.clf()
        #sys.exit(0)
      else:
        notFound += 1
        notFList.append(sid)

  print "Not found %d" % notFound
  print notFList

def findRow(sid,avgsList):
   for r in avgsList:
    if r[0] == sid:
      return r[5::]

   print "%d not found" % sid
   return None


if __name__ == '__main__':
   main()
