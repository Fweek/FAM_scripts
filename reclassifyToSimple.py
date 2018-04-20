import sys, numpy, netCDF4, datetime, os
from optparse import OptionParser
import cyFieldClass as cyFC
import pylab


def main():
    usage = "usage: %prog [options] <Directory location of Reclassified folder> <output suffix>\n" + \
            "Reclassifies input to Full and simple"
    parser = OptionParser(usage=usage)
    parser.add_option("-s", "--start", dest="tStart", default=0,
                      help="Start step")
    parser.add_option("-e", "--end", dest="tEnd", default=-1,
                      help="End step")
    parser.add_option("--processYears", dest="processYears", default='2014,2013,2011',
                      help="comma separated list of years to process, default 2014,2013,2011")
    parser.add_option("-v", "--verbose", dest="verbose", default=False,
                      help="Verbose")
    opts, args = parser.parse_args()
    if len(args) < 1:
        sys.exit(parser.print_help())

    outDir = args[0]
    postFix = args[1]

    tStart = int(opts.tStart)
    tEnd = int(opts.tEnd)
    # curYr = int(opts.processYear)
    processYears = opts.processYears.split(',')
    verbose = opts.verbose

    colOffset = 5  # number of columns used for field ids,y,x,numpixels,crop type

    sFOffset = 8  # 12

    # output file
    # outFn = "%s/Test_reclass.csv" % outDir #(outDir,curYr)
    # outClass = openCSV(outFn,"int32")
    # outClass = outClass.astype(numpy.float32)

    try:
        bTime = datetime.datetime.now()

        # tstart,tend,indxOut
        # timePeriods = [(6,10,4),(11,14,3),(15,18,2),(19,22,1)]
        # timePeriods = [(6,10,4),(6,14,3),(6,18,2),(19,23,1)]
        # timePeriods = [(6,10,4),(6,14,3),(6,18,2),(19,25,1)]
        # timePeriods = [(6,10,4),(6,14,3),(6,18,2),(19,29,1)]
        # timePeriods = [(6,10,4),(6,14,3),(6,18,2),(19,33,1)]
        # timePeriods = [(6,10,4),(6,14,3),(6,18,2),(20,33,1)]

        # timePeriods = [(6,10,4),(6,14,3),(6,18,2),(20,33,1),(20,24,1),(20,28,1),(20,33,1)]
        # timePeriods = [(6,10,6),(6,14,5),(6,18,4),(20,24,3),(20,28,2),(20,33,1)]
        # timePeriods = [(6,10,7),(6,14,6),(6,18,5),(19,22,4),(19,26,3),(19,29,2),(19,33,1)]
        timePeriods = [(6, 10, 7), (6, 14, 6), (6, 18, 5), (21, 24, 4), (21, 26, 3), (21, 29, 2), (21, 33, 1)]

        # TODO: find better way
        # yDim = 221632
        # New grid
        # yDim = 242409
        # (258299) (226285)
        # This is for the 2013 shapefile
        # yDim = 264498
        # This is for the 2012 that should've been the same
        # yDim = 226285
        # yDim = 242409
        # yDim = 370897
        # yDim = 342326
        yDim = 120009
        output = numpy.zeros([yDim, 26], dtype=numpy.float32)

        indxAdd = 0

        print "Processing years %s" % opts.processYears
        for yr in processYears:
            yr = int(yr)
            print "year %d" % yr

            # Processing year
            outFn = "%s/%d_class.csv" % (outDir, yr)
            prosYear = openCSV(outFn)
            print "Loaded data files for %d" % yr

            print prosYear.shape[0], prosYear.shape[1]
            # Get sims id
            output[:, 0] = prosYear[:, 0]

            # print prosYear.shape[0],prosYear.shape[1]

            # continue

            print "Starting fallow fields re-classification from full to simple..."
            for tp in timePeriods:
                # tStart = tStart + colOffset
                # tEnd = tEnd + colOffset

                tStart = tp[0] + colOffset
                tEnd = tp[1] + colOffset

                # for i in range(tStart,tEnd):
                # print datetime.datetime.now()

                # t2 = prosYear[0,i]
                t2 = prosYear[0, tStart]
                datet = netCDF4.num2date(t2, units="days since 1980-1-1 00:00:00", calendar='gregorian')
                strD = datet.strftime("%Y-%m-%d")

                t3 = prosYear[0, tEnd]
                datet = netCDF4.num2date(t3, units="days since 1980-1-1 00:00:00", calendar='gregorian')
                strD2 = datet.strftime("%Y-%m-%d")
                print "Processing time %s through %s" % (strD, strD2)

                # t3 = t3
                datet = netCDF4.num2date(t3, units="days since 1980-1-1 00:00:00", calendar='gregorian')
                t3Int = int(datet.strftime("%Y%m%d"))
                print  datet.strftime("%Y%m%d")
                print  t3Int

                print "t2: ", t2, "t3: ", t3
                print 'tStart=', tStart, 'tEnd=', tEnd
                print "prosYear", prosYear
                prosYear = prosYear.astype(numpy.float64)
                outClass = cyFC.reclassify(prosYear, tStart, tEnd)

                # add to right column
                curIndx = tp[2]  # +indxAdd
                print "output F", curIndx
                output[:, curIndx] = outClass[:, 1]
                output[0, curIndx] = t3Int
                print "output S", curIndx + sFOffset
                output[:, curIndx + sFOffset] = outClass[:, 2]
                output[0, curIndx + sFOffset] = t3Int

                # indxAdd = indxAdd + 4

        print "saving %s/reclassified_%s.csv" % (outDir, postFix)
        outResFn = "%s/reclassified_%s.csv" % (outDir, postFix)
        numpy.savetxt(outResFn, output, delimiter=",", fmt='%d')

        # print prosYear.dtype
        # outClass = cyFC.classifyFields(prosYear,prevYear,refYear,outClass,i)

        # print outFn
        # numpy.savetxt(outFn, outClass, delimiter=",",fmt='%d')

        print "Start time: ", bTime
        print "End time: ", datetime.datetime.now()

    except RuntimeError, e:
        sys.stderr.write(str(e) + '\n')
        sys.exit(1)


def openCSV(outFn, dataType="float32"):
    if os.path.exists(outFn):
        avgs = numpy.genfromtxt(outFn, dtype=dataType, delimiter=',')
    else:
        print "Error: File %s doesn't exists" % outFn
        sys.exit(0)

    return avgs


if __name__ == '__main__':
    main()
