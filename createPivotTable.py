# Formatting and merging the CSV reclassified output from FAM algorithm with Geo-spatial farm field boundaries (DBF file)
#  for the purpose of creating pivot and summary tables, figures, and maps, etc.
#
# Created by Carolyn Rosevelt, NASA-Ames/CSUMB Cooperative 02/14/18

# Import libraries and read-in FAM output csv file.
import pandas as pd
import os, csv, sys
from simpledbf import Dbf5

usage = "Formats the CDL codes in the reclassified CSV file in preparation to make pivot tables\n" + \
        "usage: python reformatReclass.py <Directory path of reclassified file> <filename of DBF>"

if len(sys.argv) < 2:  #number of arguments required
    print usage
    sys.exit(1)

# Set working directory to user input (directory path of input files)
os.chdir(sys.argv[1])

# Loop through every file in the current working directory.
for csvFilename in os.listdir('.'):
    if not csvFilename.startswith('reclassified'): #skip the file if it does not start with reclassified in filename
        print 'SKIPPING ' + csvFilename + ': Does not start with reclassified'
        continue
        #sys.exit(1)  #For every file in the current working directory if it is not a CSV file then skip

    print('REFORMATTING ' + csvFilename + '...')

    # with open(csvFilename, "rb") as source: #Open the input CSV file
    #     rdr = csv.reader(source) #Use csv.reader to read the input CSV file
    #
    #     with open("result.csv", "wb") as result: #Now open a new output CSV file
    #         wtr = csv.writer(result) #Use csv.writer to write in the new output CSV file
    #         for r in rdr: #For each row in the input CSV file
    #             wtr.writerow((r[0], r[1], r[2], r[3], r[4], r[5])) #Write only the rows in the first 5 columns to the new output CSV file


#Change code values for first date
inputFileName = csvFilename
outputFileName = 'temp1.csv'

with open(inputFileName, 'rb') as inFile, open(outputFileName, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    # skip the first row from the reader, the old header
    next(r, None)

    # write new header
    w.writerow(['SIMS_ID','S20160720','S20160524','S20160422','S20160320','YTD20160720'])

    for line in r:
        if line[1] == '4' or line[1] == '15':
            w.writerow((line[0], '10', line[2], line[3], line[4], '10'))

        elif line[1] == '8':
            w.writerow((line[0], '2', line[2], line[3], line[4], '10'))

        elif line[1] == '0':
            w.writerow((line[0], 'NAN', line[2], line[3], line[4], '10'))

        else:
            w.writerow((line[0], line[1], line[2], line[3], line[4], "10"))


#Change code values for second date
inputFileName = 'temp1.csv'
outputFileName = 'temp2.csv'

with open(inputFileName, 'rb') as inFile, open(outputFileName, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    for line in r:
        if line[2] == '4' or line[2] == '16':
            w.writerow((line[0], line[1], '10', line[3], line[4], line[5]))

        elif line[2] == '8':
            w.writerow((line[0], line[1], '2', line[3], line[4], line[5]))

        elif line[2] == '0':
            w.writerow((line[0], line[1], 'NAN', line[3], line[4], line[5]))

        else:
            w.writerow((line[0], line[1], line[2], line[3], line[4], line[5]))

os.remove('temp1.csv')


inputFileName = 'temp2.csv'
outputFileName = 'temp3.csv'

with open(inputFileName, 'rb') as inFile, open(outputFileName, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    next(r, None)

    # write new header
    w.writerow(['SIMS_ID','S20160720','S20160524','S20160422','S20160320','YTD20160720'])

    for line in r:
        if line[1] == 'NAN':
            w.writerow((line[0], line[1], line[2], line[3], line[4], line[5]))

        elif int(line[1]) < int(10):
            w.writerow((line[0], line[1], line[2], line[3], line[4], '2'))

        else:
            w.writerow((line[0], line[1], line[2], line[3], line[4], line[5]))

os.remove('temp2.csv')



inputFileName = 'temp3.csv'
outputFileName = 'Reformatted_reclass.csv'

with open(inputFileName, 'rb') as inFile, open(outputFileName, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    next(r, None)

    # write new header
    w.writerow(['SIMS_ID','S20160720','S20160524','S20160422','S20160320','YTD20160720'])

    for line in r:
        if line[2] == 'NAN':
            w.writerow((line[0], line[1], line[2], line[3], line[4], line[5]))

        elif int(line[2]) < int(10):
            w.writerow((line[0], line[1], line[2], line[3], line[4], '2'))

        else:
            w.writerow((line[0], line[1], line[2], line[3], line[4], line[5]))

os.remove('temp3.csv')



dbf = Dbf5(sys.argv[2])
dbf.to_csv('temp4.csv')

# Merge newly updated csv with dbf (csv) of the YEAR basemap
a = pd.read_csv('Reformatted_reclass.csv')
b = pd.read_csv('temp4.csv')

merged = a.merge(b, on='SIMS_ID')
merged.to_csv('Appended_reclass.csv', index=False)

os.remove('temp4.csv')
