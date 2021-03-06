
import json, csv, sys, os
import pandas as pd
import numpy as np
from pandas import ExcelWriter

usage = "Creates a pivot table of the appended reclassified CDL file. To add or omit counties of interest, open the pivotTablesConfig.json file and edit it\n" + \
        "usage: python createPivotTables.py <Directory path of appended reclassified file> <Date of column of interest>"

if len(sys.argv) < 2:  #number of arguments required
    print usage
    sys.exit(1)

# Set working directory to user input (directory path of input files)
os.chdir(sys.argv[1])

# Load the json file which includes all the desired counties
with open('pivotTableConfig.json') as json_data_file:
    data = json.load(json_data_file)

# Create an empty list
countyList = []

# For each county in the json file, append it to the empty list created above. We're making the json file into a list
print "COUNTIES TO BE PROCESSED:"
for item in data['county_list']:
    print item
    countyList.append(item)

print countyList

#Declare the input and output files
inputFilename = sys.argv[1]+"\AppendedReclass.csv"
outputFilename = sys.argv[1]+"\countyReclass.csv"

#Open input and output CSV files
with open(inputFilename, 'rb') as inFile, open(outputFilename, 'wb') as outfile:
    r = csv.reader(inFile)
    w = csv.writer(outfile)

    # For every row in the input file, if the county value matches with a county in the original json file then don't write it to the output file.
    # This will result in a new file with all the unwanted counties removed.
    for line in r:
        if not any(county_name in element
                      for element in line
                      for county_name in countyList):
                            w.writerow(line)

# Read-in newly created CSV file
df = pd.read_csv('countyReclass.csv',  low_memory=False) #using low memory false to bypass stating dtype explictly

# Creates pivot table that indexes county name 'COUNTY' from the previously merged file and summarizes idle vs. cropped acreage.
print "CREATING PIVOT TABLE..."
df2 = pd.pivot_table(df,index=["COUNTY"], values=["ACRES"], columns=[str(sys.argv[2])], aggfunc=[np.sum], fill_value=0, margins=True)
df2.to_csv('pivot.csv')

# Read-in pivot table CSV and drop the first two rows.
df3 = pd.read_csv('pivot.csv', header = 2)

# Create a data dictionary of crop categories and their respective crop codes
cropDict = {'0':'NA', '2':'Cropped', '3':'Cropped - MC',  '4':'Emergent', '5':'Perennial', '6':'Young Perennial', '7':'Alfalfa', '8':'Winter wheat/Pasture', '9':'Rice', '10':'No crop to date', '11':'No crop to date - MC', '12':'No crop to date - LC', '13':'No crop yet - Perennial', '14':'No crop yet - Alfalfa', '15':'No crop yet - Rice', '16':'Cleared Perennial', '17':'Failed Rice', 'All':'All'}

# Create a list of just the headers of the pivot table
headers_list = df3.columns

# For the headers from index 1 to 2 less than the length, replace the crop code with the crop category
for i in range(1, len(headers_list)):
    header = df3.columns[i]
    df3.columns.values[i] = cropDict[header]

# Save to Excel
writer = ExcelWriter('pivotTable.xlsx')
df3.to_excel(writer)
writer.save()

os.remove('pivot.csv')
os.remove('countyReclass.csv')
