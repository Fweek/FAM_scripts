import sys, numpy, netCDF4, datetime, os, csv
from optparse import OptionParser
import cyFieldClass as cyFC

def main():
    usage = "Reclassifies input to full and simple\n" + \
            "usage: %prog [options] <Directory location of Reclassified folder>"
            #Sample command line call: python reclassifyToSimple.py --start=0 --end=34 --processYear=2016 C:\Users\[username]\Desktop\CALIFORNIA\CA_FAM_2016\Reclassified

    parser = OptionParser(usage=usage)
    parser.add_option("-s", "--start", dest="tStart", default=0,
                      help="Start step")
    parser.add_option("-e", "--end", dest="tEnd", default=-1,
                      help="End step")
    parser.add_option("--processYears", dest="processYears", default="2014,2013,2011",
                      help="comma separated list of years to process, default 2014,2013,2011")
    parser.add_option("-v", "--verbose", dest="verbose", default=False,
                      help="Verbose")
    opts, args = parser.parse_args()
    if len(args) < 1:
        sys.exit(parser.print_help())

    outDir = args[0]

    tStart = int(opts.tStart)
    tEnd = int(opts.tEnd)
    # curYr = int(opts.processYear)
    processYears = opts.processYears.split(",")
    verbose = opts.verbose

    colOffset = 5  # number of columns used for field ids,y,x,numpixels, and crop type

    sFOffset = 8

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

        os.chdir(outDir)
        csvFilename = sorted(os.listdir('.'))[0]
        with open(csvFilename, 'rb') as f:
            reader = csv.reader(f)
            first_col_len = len(zip(*reader)[0])
            yDim = int(first_col_len)
        print yDim

        output = numpy.zeros([yDim, 26], dtype=numpy.float32)

        indxAdd = 0

        print "Processing years: %s" % opts.processYears
        for yr in processYears: #For each year in the list of years given
            yr = int(yr) #Turn selected year into an integer
            print "Year %d" % yr

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
                print "tStart=", tStart, "tEnd=", tEnd
                print "prosYear", prosYear
                sys.stdout.flush()
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

        print "saving %s/%s_reclass.csv" % (outDir, opts.processYears)
        outResFn = "%s/%s_reclass.csv" % (outDir, opts.processYears)
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
