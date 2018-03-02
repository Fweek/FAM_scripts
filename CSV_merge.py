# This script merges multiple CSV files into one and removes extra headers.
# Then it double checks if extra headers exist

#Import packages
import glob, os, csv, sys, datetime

#Error message user receives if missing parameters
usage = "Merges all the individual CSV files into one\n" + \
        "usage: python CSV_merge.py <Directory path of raw input CSVs>"

if len(sys.argv) <1:  #Number of arguments required
    print usage
    sys.exit(1)

#Saves start date and time of script. Will be printed when script finishes.
bTime = datetime.datetime.now()

#Set working directory to user input (directory path of input files)
os.chdir(sys.argv[1])

#Make a new directory for the combined output files if it does not already exist
if not os.path.exists('Output-Merged'):
    os.makedirs('Output-Merged', )

#Make a new directory for the merged class output files if it does not already exist
if not os.path.exists('Class-Merged'):
    os.makedirs('Class-Merged', )

#------------------------------------------------------------
#Merging timeseries files

#Set working directory to directory of reformatted files
os.chdir(sys.argv[1]+'/Output-Combined')

files = [f for f in sorted(os.listdir(sys.argv[1]+'/Output-Combined')) if os.path.isfile(f)] #select only files and exclude directories
filename = str(files[0]) #create string object of the first file's filename
filename_split = filename.split('_') #split the filename string up by _
filename_length = len(filename_split) #how many splits are there?
output_prefix = '_'.join(filename_split[1:filename_length-1]) #Rejoin the the splits without the first and last splits
date=filename_split[filename_length-3]
date_split=date.split('-')
date_year=date_split[0]

CSV_files = glob.glob("*.csv")

print ' '
print "STARTING MERGE..."
header_saved = False
with open('temp.csv','wb') as fout:
    for filename in CSV_files:
        print(filename)
        with open(filename) as fin:
            header = next(fin)
            if not header_saved:
                fout.write(header)
                header_saved = True
            for line in fin:
                fout.write(line)
print "done"

print "Double-checking for duplicate headers"
with open('temp.csv', 'rb') as inp, open(sys.argv[1]+'/Output-Merged/Merged_'+output_prefix+'.csv', 'wb') as out:
    reader = csv.reader(inp)
    writer = csv.writer(out)
    headers = next(reader, None)  # returns the headers or `None` if the input is empty
    if headers:
        writer.writerow(headers)
    for row in csv.reader(inp):
        if row[1] != "date":
            writer.writerow(row)
print "done"

os.remove('temp.csv')

#-----------------------------------------------------------
#Merging class files

#Set working directory to directory of reformatted class files

os.chdir(sys.argv[1]+'/Class-Template')

class_files = glob.glob("*L7SR*.csv") #select only Landsat 7 files; the satellite doesn't really matter, we just need one complete set of SIMSIDs

print ' '
print "STARTING MERGE..."
header_saved = False
with open('classtemp.csv','wb') as fout:
    for filename in class_files:
        print(filename)
        with open(filename) as fin:
            header = next(fin)
            if not header_saved:
                fout.write(header)
                header_saved = True
            for line in fin:
                fout.write(line)
print "done"

print "Double-checking for duplicate headers"
with open('classtemp.csv', 'rb') as inp, open(sys.argv[1]+'/Class-Merged/'+date_year+'_class.csv', 'wb') as out:
    reader = csv.reader(inp)
    writer = csv.writer(out)
    headers = next(reader, None)  # returns the headers or `None` if the input is empty
    if headers:
        writer.writerow(headers)
    for row in csv.reader(inp):
        if row[1] != "date":
            writer.writerow(row)
print "done"

os.remove('classtemp.csv')


print 'MERGING COMPLETE'
print "Start time: ", bTime
print "End time: ", datetime.datetime.now()
