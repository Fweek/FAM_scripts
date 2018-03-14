import sys, numpy, netCDF4, datetime,os
from optparse import OptionParser
import cyFieldClass as cyFC
import pylab

def main():
  usage = "usage: %prog [options] <filesDir>\n"+\
            "FAM algorithm classiciation"
  parser = OptionParser(usage=usage)
  parser.add_option("-s","--start",dest="tStart",default=6,
      help="Start step,has to be greater than 5, default 6")
  parser.add_option("-e","--end",dest="tEnd",default=-1,
      help="End step")
  parser.add_option("-t","--tester",dest="tester",default=None,
      help="test classification")
  parser.add_option("-p","--subset",dest="subset",default=None,
      help="extrac Subset from class file")
  parser.add_option("--refYear",dest="refYear",default=2011,
      help="year to use as reference default 2011")
  parser.add_option("--processYear",dest="processYear",default=2013,
      help="year to process,default 2013")
  parser.add_option("-v","--verbose",dest="verbose",default=False,
      help="Verbose")
  opts,args=parser.parse_args()
  if len(args)<1:
     sys.exit(parser.print_help())

  outDir = args[0]

  tStart = int(opts.tStart)
  tEnd = int(opts.tEnd)
  tester = opts.tester
  subsetFn = opts.subset
  refYr = int(opts.refYear)
  curYr = int(opts.processYear)
  verbose = opts.verbose

  colOffset = 5 #number of columns used for field ids,y,x,numpixels,crop type
  if tStart < 6:
    print "Error, tStart has to be greater than 5"
    sys.exit(0)
 
  try:   
    bTime = datetime.datetime.now()

    print "Field Classification ",tester

    #Open ref year
    outFn = "%s/%d_avgs.csv" % (outDir,refYr)
    refYear = openCSV(outFn)

    #Processing year
    outFn = "%s/%d_avgs.csv" % (outDir,curYr)
    prosYear = openCSV(outFn)
  
    #Previous year
    outFn = "%s/%d_avgs.csv" % (outDir,curYr-1)
    prevYear = openCSV(outFn)
 
    #output file
    outFn = "%s/%d_class.csv" % (outDir,curYr)
    outClass = openCSV(outFn,"int32")
    outClass = outClass.astype(numpy.float32)
 
    numpy.savetxt(outFn, outClass, delimiter=",",fmt='%d')

    sys.exit(0)
    #crop file
    #outFn = "%s/field_cropType.csv" % (outDir)
    #cropType = openCSV(outFn,"int32")
          
    print "Loaded data files"  
     
    print "Starting fallow fields classification..."      
    tStart = tStart + colOffset #+ 6
    tEnd = tEnd + colOffset
    print tStart,tEnd
    for i in range(tStart,tEnd):
      print datetime.datetime.now()

      t2 = prosYear[0,i]
      datet = netCDF4.num2date(t2, units="days since 1980-1-1 00:00:00", calendar='gregorian')
      strD = datet.strftime("%Y-%m-%d")
      print "Processing time %s" % strD

      #print prosYear.dtype
      outClass = cyFC.classifyFields(prosYear,prevYear,refYear,outClass,i)
      
    print outFn
    numpy.savetxt(outFn, outClass, delimiter=",",fmt='%d')       
  
    print "Start time: ",bTime
    print "End time: ",datetime.datetime.now()

  except RuntimeError, e:
    sys.stderr.write(str(e)+'\n')
    sys.exit(1)

def openCSV(outFn,dataType="float32"):
  if os.path.exists(outFn): 
    avgs = numpy.genfromtxt(outFn, dtype=dataType,delimiter = ',')
  else:
    print "Error: File %s doesn't exists" % outFn
    sys.exit(0)
  
  return avgs

if __name__ == '__main__':
   main()
