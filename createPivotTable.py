
import json, csv, sys, os
import pandas as pd
import numpy as np
from pandas import ExcelWriter

usage = "Creates a pivot table of the appended reclassified CDL file. To add or omit counties of interest, open the pivotTablesConfig.json file and edit it\n" + \
        "usage: python createPivotTables.py <Directory path of appended reclassified file> <Directory path of the .json config file> <date column of interest>"

# if len(sys.argv) < 3:  #number of arguments required
#     print usage
#     sys.exit(1)

# Set working directory to user input (directory path of input files)
# os.chdir(sys.argv[1])

# Set working directory to user input (directory path of input files)
os.chdir('C:\Users\Michael\Desktop\CALIFORNIA\CA_FAM_2016\Reclassified')

# Load the json file which includes all the desired counties
#with open(sys.argv[2] +'\pivotTableConfig.json') as json_data_file:
with open('C:\Users\Michael\PycharmProjects\FAM\pivotTableConfig.json') as json_data_file:
    data = json.load(json_data_file)

# Create an empty list
countyList = []

# For each county in the json file, append it to the empty list created above. We're making the json file into a list
for item in data['county_list']:
    print item
    countyList.append(item)

#Declare the input and output files
# inputFileName = sys.argv[1]+"\Appended_reclass.csv"
# outputFileName = sys.argv[1]+"\Appended_reclass_county.csv"
inputFileName = 'C:\Users\Michael\Desktop\CALIFORNIA\CA_FAM_2016\Reclassified\AppendedReclass.csv'
outputFileName = 'C:\Users\Michael\Desktop\CALIFORNIA\CA_FAM_2016\Reclassified\countyReclass.csv'

#Open input and output CSV files
with open(inputFileName, 'rb') as inFile, open(outputFileName, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    # For every row in the input file, if the county value matches with a county in the original json file then write it to the output file.
    # This will result in a new file with all the unwanted counties removed.
    for line in r:
        if not any(remove_word in element
                      for element in line
                      for remove_word in countyList):
                            w.writerow(line)

# Read-in newly created CSV file
df = pd.read_csv('C:\Users\Michael\Desktop\CALIFORNIA\CA_FAM_2016\Reclassified\countyReclass.csv',  low_memory=False)
df.head()

# Creates pivot table that indexes county name 'COUNTY' from the previously merged file and summarizes idle vs. cropped acreage.
df2 = pd.pivot_table(df,index=["COUNTY"], values=["AcresMast"], columns=[df.columns[1]], aggfunc=[np.sum], fill_value=0, margins=True)
df2.to_csv('pivot.csv')

# Read-in pivot table CSV and drop the first two rows.
df3 = pd.read_csv('pivot.csv', header = 2)

# Create a data dictionary of crop categories and their respective crop codes
cropDict = {'2':'Cropped - HC', '3':'Cropped - MC',  '4':'Emergent', '5':'Perennial', '6':'Young Perennial', '7':'Alfalfa', '8':'Winter wheat/Pasture', '9':'Rice', '10':'No crop to date - HC', '11':'No crop to date - MC', '12':'No crop to date - LC', '13':'No crop yet - Perennial', '14':'No crop yet - Alfalfa', '15':'No crop yet - Rice', '16':'Cleared Perennial', '17':'Failed Rice'}

# Create a list of just the headers of the pivot table
headers_list = df3.columns

# For the headers in index 1 to 2 less than the length, replace the crop code with the crop category
for i in range(1, (len(headers_list)-2)):
    header = df3.columns[i]
    df3.columns.values[i] = cropDict[header]

# Save to CSV
#df3.to_csv('pivotTable.csv', index=False)

# Save to Excel
writer = ExcelWriter('pivotTable.xlsx')
df3.to_excel(writer)
writer.save()

os.remove('pivot.csv')
os.remove('countyReclass.csv')
