import pandas as pd
import os, sys, time
from simpledbf import Dbf5

usage = "Further consolidates CDL codes into either cropped (2) or not cropped (10) in preparation to make pivot tables\n" + \
        "usage: python reformatReclass.py <Directory path of reclassified file> <filename of DBF>"

if len(sys.argv) < 2:  #number of arguments required
    print usage
    sys.exit(1)

# Set working directory to user input (directory path of input files)
os.chdir(sys.argv[1])

# Load in the DBF file and turn it into a CSV
dbf = Dbf5(sys.argv[2])
dbf.to_csv('dbf.csv')

# Add Seasonal and Annual columns and fill with reduced CDL codes
# Loop through every file in the current working directory.
for csvFilename in os.listdir('.'):
    if not csvFilename.endswith('_reclass.csv'): #skip the file if it does not end with "_reclass.csv" in filename
        print 'SKIPPING ' + csvFilename + ': Not a reclassified csv file'
        continue

    print('REFORMATTING ' + csvFilename + '...')

    # Read in CSV
    df = pd.read_csv(csvFilename)

    # Change columns names
    df.rename(columns={df.columns[9]: 'S'+df.columns[9]}, inplace=True)
    df.rename(columns={df.columns[10]: 'S'+df.columns[10]}, inplace=True)
    df.rename(columns={df.columns[11]: 'S'+df.columns[11]}, inplace=True)
    df.rename(columns={df.columns[12]: 'S'+df.columns[12]}, inplace=True)
    df.rename(columns={df.columns[13]: 'S'+df.columns[13]}, inplace=True)
    df.rename(columns={df.columns[14]: 'S'+df.columns[14]}, inplace=True)
    df.rename(columns={df.columns[15]: 'S'+df.columns[15]}, inplace=True)
    df.rename(columns={df.columns[16]: 'S'+df.columns[16]}, inplace=True)
    df.rename(columns={'-9999': 'SIMS_ID'}, inplace=True)
    df.rename(columns={df.columns[16]: 'Winter'}, inplace=True)
    df.rename(columns={df.columns[17]: 'Summer'}, inplace=True)
    df.rename(columns={df.columns[18]: 'Annual'}, inplace=True)
    print df

    # Delete unnecessary columns
    df = df.drop(df.columns[19:26], axis=1)
    print df



    # If then statements for how to fill Winter, Summer, and Annual columns
    # [ADD RULES HERE]
    df['Winter'] = df.iloc[:, 13:16].apply(lambda x: 2 if 2 in x.values else x[0], axis=1)
    df['Summer'] = df.iloc[:, 9:13].apply(lambda x: 2 if 2 in x.values else 10, axis=1)

    cols = ['Winter', 'Summer']
    df['Annual'] = df[cols].apply(lambda x: 2 if 2 in x.values else 10, axis=1)

    #print(df)

    # Export dataframe to CSV
    df.to_csv('reformattedReclass.csv')

# Merge newly updated csv with dbf (csv) using SIMS_ID as the common variable
a = pd.read_csv('reformattedReclass.csv')
b = pd.read_csv('dbf.csv')

merged = a.merge(b, on='SIMS_ID')
merged.drop('Unnamed: 0', axis=1, inplace=True)
#print merged
merged.to_csv('appendedReclass.csv', index=False)
print "Reformat complete"
time.sleep(1)

# Remove intermediate files
os.remove('dbf.csv')
os.remove('reformattedReclass.csv')
